//
//  CodeSignService.swift
//  IPASignCraft
//
//  Created by Saurav Nagpal on 16/03/26.
///
//  CodeSignService.swift
//  IPASignCraft
//
//

import Foundation

// MARK: - Signing Identity Models

struct SigningIdentity {
    let sha1: String
    let commonName: String
    let keychainPath: String?
    let keychainPassword: String?
    let originalSearchList: [String]?
}

struct ProvisioningContext {
    let embeddedProfileURL: URL
    let installedProfileURL: URL
}

// MARK: - Main Service

struct CodeSignService {
    
    func resignIPA(
        ipaURL: URL,
        profileURL: URL,
        certificate: CertificateRequest,
        options: SigningOptions,
        progress: ((SigningStep) -> Void)? = nil
    ) async throws -> URL {
        
        try cleanupStaleTemporaryArtifacts()
        
        progress?(.preparing)
        let workspace = try await BlockingExecutor.run { try createWorkspace() }
        
        progress?(.extracting)
        let appURL = try await BlockingExecutor.run {
            try IPAExtractorService.extractIPA(at: ipaURL, to: workspace)
        }
        
        progress?(.modifying)
        try await BlockingExecutor.run {
            try applyAdvancedOptions(options, to: appURL)
        }
        
        progress?(.resolvingIdentity)
        let signingIdentity = try await BlockingExecutor.run {
            try resolveCertificateIdentity(certificate)
        }
        
        defer {
            cleanupTemporaryKeychainIfNeeded(signingIdentity)
        }
        
        progress?(.embeddingProfile)
        _ = try await BlockingExecutor.run {
            try prepareProvisioningProfile(profileURL: profileURL, appURL: appURL)
        }
        
        let entitlementsURL = try await BlockingExecutor.run {
            try EntitlementService.prepareEntitlements(
                appURL: appURL,
                profileURL: profileURL,
                updates: options.entitlementEntries,
                outputDir: workspace
            )
        }
        
        progress?(.removeOldSign)
        try await BlockingExecutor.run {
            try removeOldSignatures(at: appURL)
        }
        
        progress?(.signingFrameworks)
        try await BlockingExecutor.run {
            try signNestedItems(inside: appURL,
                                signingIdentity: signingIdentity
            )
        }
        
        progress?(.signingMainBundle)
        try await BlockingExecutor.run {
            try signAppBundle(
                appURL: appURL,
                signingIdentity: signingIdentity,
                entitlementsURL: entitlementsURL
            )
        }
        
        
        progress?(.verifying)
        try await BlockingExecutor.run {
            try verifySignedBundle(appURL)
        }
        
        progress?(.repackaging)
        let outputIPA = workspace.appendingPathComponent("resigned.ipa")
        
        try await BlockingExecutor.run {
            try ShellExecutor.run("""
            cd "\(workspace.path)" && zip -qry "\(outputIPA.lastPathComponent)" Payload
            """)
        }
        
        progress?(.completed)
        return outputIPA
    }
}

// MARK: - Certificate Resolution

fileprivate extension CodeSignService {
    
    func resolveCertificateIdentity(_ input: CertificateRequest) throws -> SigningIdentity {
        switch input {
        case .saved(let cert):
            return SigningIdentity(
                sha1: cert.identity,
                commonName: cert.name,
                keychainPath: nil,
                keychainPassword: nil,
                originalSearchList: nil
            )
            
        case .p12(let url, let password):
            return try prepareTemporarySigningIdentity(
                p12URL: url,
                p12Password: password
            )
        }
    }
    
    func prepareTemporarySigningIdentity(
        p12URL: URL,
        p12Password: String
    ) throws -> SigningIdentity {
        
        let originalListOutput = try ShellExecutor.runWithOutput("security list-keychains -d user")
        let originalSearchList = extractQuotedPaths(from: originalListOutput.output)
        
        let tempKeychainDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("IPASignCraft_Keychains", isDirectory: true)
        
        try FileManager.default.createDirectory(at: tempKeychainDir, withIntermediateDirectories: true)
        
        let keychainPassword = UUID().uuidString
        let keychainURL = tempKeychainDir
            .appendingPathComponent("temp_sign_\(UUID().uuidString).keychain-db")
        
        let keychainPath = keychainURL.path
        
        try ShellExecutor.run("""
        security create-keychain -p "\(keychainPassword)" "\(keychainPath)"
        security unlock-keychain -p "\(keychainPassword)" "\(keychainPath)"
        security set-keychain-settings -lut 21600 "\(keychainPath)"
        """)
        
        let joinedSearchList = ([ "\"\(keychainPath)\"" ] + originalSearchList).joined(separator: " ")
        
        try ShellExecutor.run("""
        security list-keychains -d user -s \(joinedSearchList)
        """)
        
        let importResult = try ShellExecutor.runWithOutput("""
        security import "\(p12URL.path)" \
        -k "\(keychainPath)" \
        -P "\(p12Password)" \
        -A \
        -T /usr/bin/codesign \
        -T /usr/bin/security
        """)
        
        if importResult.status != 0 {
            throw NSError(domain: "CodeSign", code: Int(importResult.status), userInfo: [
                NSLocalizedDescriptionKey: importResult.output
            ])
        }
        
        try ShellExecutor.run("""
        security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "\(keychainPassword)" "\(keychainPath)"
        """)
        
        try ShellExecutor.run("sleep 1")
        
        let identityResult = try ShellExecutor.runWithOutput(
            "security find-identity -v -p codesigning \"\(keychainPath)\""
        )
        
        guard let parsed = parseIdentityAndName(from: identityResult.output) else {
            throw NSError(domain: "CodeSign", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Imported P12 does not expose a valid signing identity."
            ])
        }
        
        return SigningIdentity(
            sha1: parsed.sha1,
            commonName: parsed.commonName,
            keychainPath: keychainPath,
            keychainPassword: keychainPassword,
            originalSearchList: originalSearchList
        )
    }
    
    func cleanupTemporaryKeychainIfNeeded(_ identity: SigningIdentity) {
        guard let keychainPath = identity.keychainPath else { return }
        
        if let originalList = identity.originalSearchList, !originalList.isEmpty {
            let joined = originalList.joined(separator: " ")
            try? ShellExecutor.run("security list-keychains -d user -s \(joined)")
        }
        
        try? ShellExecutor.run("security delete-keychain \"\(keychainPath)\"")
        try? FileManager.default.removeItem(atPath: keychainPath)
    }
    
    func cleanupStaleTemporaryArtifacts() throws {
        
        let currentListOutput = try ShellExecutor.runWithOutput("security list-keychains -d user")
        let currentList = extractQuotedPaths(from: currentListOutput.output)
        
        let sanitizedList = currentList.filter {
            !$0.contains("IPASignCraft_Keychains") &&
            !$0.contains("temp_sign_")
        }
        
        if !sanitizedList.isEmpty {
            let joined = sanitizedList.joined(separator: " ")
            try? ShellExecutor.run("security list-keychains -d user -s \(joined)")
        }
        
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("IPASignCraft_Keychains")
        
        guard FileManager.default.fileExists(atPath: tempDir.path) else { return }
        
        let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        
        for item in contents {
            try? ShellExecutor.run("security delete-keychain \"\(item.path)\"")
            try? FileManager.default.removeItem(at: item)
        }
    }
}

// MARK: - Provisioning

fileprivate extension CodeSignService {
    
    func prepareProvisioningProfile(profileURL: URL, appURL: URL) throws -> ProvisioningContext {
        let embeddedURL = appURL.appendingPathComponent("embedded.mobileprovision")
        try FileManager.default.copyWithOverwrite(from: profileURL, to: embeddedURL)
        
        let installedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Provisioning_\(UUID().uuidString).mobileprovision")
        
        try FileManager.default.copyWithOverwrite(from: profileURL, to: installedURL)
        
        return ProvisioningContext(
            embeddedProfileURL: embeddedURL,
            installedProfileURL: installedURL
        )
    }
}

// MARK: - Remove Old Signatures

fileprivate extension CodeSignService {
    
    func removeOldSignatures(at appURL: URL) throws {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: appURL, includingPropertiesForKeys: nil) else { return }
        
        var targets: [URL] = [appURL]
        
        for case let item as URL in enumerator where isSignableItem(item) {
            targets.append(item)
        }
        
        targets.sort { $0.path.count > $1.path.count }
        
        for item in targets {
            try? ShellExecutor.run("codesign --remove-signature \"\(item.path)\"")
            try? ShellExecutor.run("rm -rf \"\(item.path)/_CodeSignature\"")
        }
    }
    
    func verifySignedBundle(_ appURL: URL) throws {
        try ShellExecutor.run("""
        codesign --verify --deep --strict --verbose=4 "\(appURL.path)"
        """)
    }
}

// MARK: - Signing

fileprivate extension CodeSignService {
    
    func signAppBundle(
        appURL: URL,
        signingIdentity: SigningIdentity,
        entitlementsURL: URL
    ) throws {
        try signItem(at: appURL, signingIdentity: signingIdentity, entitlementsURL: entitlementsURL)
    }
    
    private func signNestedItems(
        inside rootURL: URL,
        signingIdentity: SigningIdentity
    ) throws {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: rootURL, includingPropertiesForKeys: nil) else { return }
        
        var targets: [URL] = []
        
        for case let item as URL in enumerator where isSignableItem(item) {
            targets.append(item)
        }
        
        targets.sort { $0.path.count > $1.path.count }
        
        for item in targets {
            try signItem(at: item, signingIdentity: signingIdentity, entitlementsURL: nil)
        }
    }
    
    private func signItem(
        at url: URL,
        signingIdentity: SigningIdentity,
        entitlementsURL: URL?
    ) throws {
        
        var command = """
        codesign --force --verbose=4 --timestamp=none --sign "\(signingIdentity.sha1)"
        """
        
        if let keychainPath = signingIdentity.keychainPath {
            command += " --keychain \"\(keychainPath)\""
        }
        
        if let entitlementsURL {
            command += " --entitlements \"\(entitlementsURL.path)\""
        }
        
        command += " \"\(url.path)\""
        
        let result = try ShellExecutor.runWithOutput(command)
        
        if result.status != 0 {
            throw NSError(domain: "CodeSign", code: Int(result.status), userInfo: [
                NSLocalizedDescriptionKey: result.output
            ])
        }
    }
    
    private func isSignableItem(_ url: URL) -> Bool {
        let path = url.path.lowercased()
        
        return path.hasSuffix(".framework")
        || path.hasSuffix(".dylib")
        || path.hasSuffix(".appex")
    }
}

// MARK: - Advanced Options

fileprivate extension CodeSignService {
    
    func applyAdvancedOptions(_ options: SigningOptions, to appURL: URL) throws {
        let bundleID = options.newBundleID
        
        try InfoPlistService.updateBundleID(at: appURL, newBundleID: bundleID)
        try updateExtensions(at: appURL, newBundleID: bundleID)
        
        if options.plistEntries.count > 0 {
            try InfoPlistService.updateInfoPlist(at: appURL, entries: options.plistEntries)
        }
    }
    
    func updateExtensions(at appURL: URL, newBundleID: String) throws {
        let pluginsURL = appURL.appendingPathComponent("PlugIns")
        guard FileManager.default.fileExists(atPath: pluginsURL.path) else { return }
        
        let extensions = try FileManager.default.contentsOfDirectory(at: pluginsURL, includingPropertiesForKeys: nil)
        
        for ext in extensions where ext.pathExtension == "appex" {
            let plistURL = ext.appendingPathComponent("Info.plist")
            
            guard let plist = NSMutableDictionary(contentsOf: plistURL),
                  let oldBundleID = plist["CFBundleIdentifier"] as? String else { continue }
            
            if let suffix = oldBundleID.split(separator: ".").last {
                plist["CFBundleIdentifier"] = "\(newBundleID).\(suffix)"
            } else {
                plist["CFBundleIdentifier"] = newBundleID
            }
            
            plist.write(to: plistURL, atomically: true)
        }
    }
}

// MARK: - Helpers

fileprivate extension CodeSignService {
    
    func createWorkspace() throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("IPASignCraft_\(formatter.string(from: Date()))")
        
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    private func extractQuotedPaths(from output: String) -> [String] {
        let regex = try? NSRegularExpression(pattern: "\"([^\"]+)\"")
        let range = NSRange(output.startIndex..., in: output)
        let matches = regex?.matches(in: output, range: range) ?? []
        
        return matches.compactMap {
            guard let pathRange = Range($0.range(at: 1), in: output) else { return nil }
            return "\"\(output[pathRange])\""
        }
    }
    
    private func parseIdentityAndName(from output: String) -> (sha1: String, commonName: String)? {
        let lines = output.split(separator: "\n")
        
        for rawLine in lines {
            let line = String(rawLine)
            
            if line.contains("valid identities found") { continue }
            
            guard let shaRange = line.range(of: "[A-F0-9]{40}", options: .regularExpression) else {
                continue
            }
            
            let sha1 = String(line[shaRange])
            
            guard let firstQuote = line.firstIndex(of: "\""),
                  let lastQuote = line.lastIndex(of: "\""),
                  firstQuote != lastQuote else {
                continue
            }
            
            let name = String(line[line.index(after: firstQuote)..<lastQuote])
            return (sha1, name)
        }
        
        return nil
    }
}
