//
//  CodeSignService.swift
//  IPASignCraft
//
//  Created by Saurav Nagpal on 16/03/26.
//

import Foundation


struct CodeSignService {
    func resignIPA(
        ipaURL: URL,
        profileURL: URL,
        certificate: CertificateRequest,
        options: SigningOptions,
        progress: ((SigningStep) -> Void)? = nil
    ) async throws -> URL {
        
        progress?(.preparing)
        // 1. Create temp workspace
        let workspace = try await BlockingExecutor.run {
             try createWorkspace()
        }
        
        // 2. Extract IPA
        progress?(.extracting)
        let appURL = try await BlockingExecutor.run {
            try IPAExtractorService.extractIPA(at: ipaURL, to: workspace)
        }
        
        // 3. Apply advanced options
        var entitlementsURL: URL?
        if options.modifyPlist || options.modifyEntitlements {
            progress?(.extracting)
            entitlementsURL = try await BlockingExecutor.run {
                try applyAdvancedOptions(options, to: appURL, workspace: workspace)
            }
        }
       
        
        // 4. Inject provisioning profile
        progress?(.embeddingProfile)
        let destination = appURL.appendingPathComponent("embedded.mobileprovision")
        try await BlockingExecutor.run {
            try FileManager.default.copyWithOverwrite(from: profileURL, to: destination)
        }
        
        // 5. Remove old signatures
        progress?(.removeOldSign)
        try await BlockingExecutor.run {
            try removeOldSignatures(at: appURL)
        }
        
        // 6. Resolve certificate identity
        progress?(.applyingCert)
        let certIdentity =  try await BlockingExecutor.run {
            try resolveCertificateIdentity(certificate)
        }
        
        // 7. Sign app bundle
        progress?(.signing)
        try await BlockingExecutor.run {
            try signAppBundle(
                appURL: appURL,
                certificate: certIdentity,
                entitlementsURL: entitlementsURL
            )
        }
        
        // 8. Repack IPA
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

//MARK: - App sign Process
fileprivate extension CodeSignService {
    func removeOldSignatures(at appURL: URL) throws {
        let path = appURL.path
        
        try ShellExecutor.run("rm -rf '\(path)/_CodeSignature'")
        try ShellExecutor.run("find '\(path)' -name '_CodeSignature' -type d -exec rm -rf {} +")
    }
    
    func signAppBundle(
        appURL: URL,
        certificate: String,
        entitlementsURL: URL?
    ) throws {
        
        let fm = FileManager.default
        
        let frameworksURL = appURL.appendingPathComponent("Frameworks")
        let pluginsURL = appURL.appendingPathComponent("PlugIns")
        
        // 1. Sign Frameworks
        if fm.fileExists(atPath: frameworksURL.path) {
            let frameworks = try fm.contentsOfDirectory(at: frameworksURL, includingPropertiesForKeys: nil)
            
            for framework in frameworks {
                try ShellExecutor.run("""
                codesign --force --sign "\(certificate)" "\(framework.path)"
                """)
            }
        }
        
        // 2. Sign Extensions
        if fm.fileExists(atPath: pluginsURL.path) {
            let plugins = try fm.contentsOfDirectory(at: pluginsURL, includingPropertiesForKeys: nil)
            
            for plugin in plugins {
                try ShellExecutor.run("""
                codesign --force --sign "\(certificate)" "\(plugin.path)"
                """)
            }
        }
        
        // 3. Sign main app
        if let entitlementsURL {
            try ShellExecutor.run("""
            codesign --force \
            --sign "\(certificate)" \
            --entitlements "\(entitlementsURL.path)" \
            "\(appURL.path)"
            """)
        } else {
            try ShellExecutor.run("""
            codesign --force \
            --sign "\(certificate)" \
            "\(appURL.path)"
            """)
        }
    }
}

//Mark - Advanced Options
fileprivate extension CodeSignService {
    func applyAdvancedOptions(
        _ options: SigningOptions,
        to appURL: URL,
        workspace: URL
    ) throws -> URL? {
        // Bundle ID update
        let bundleID = options.newBundleID
        try InfoPlistService.updateBundleID(at: appURL, newBundleID: bundleID)
        try updateExtensions(at: appURL, newBundleID: bundleID)
        
        // Info.plist updates
        if options.modifyPlist {
            try InfoPlistService.updateInfoPlist(at: appURL, entries: options.plistEntries)
        }
        
        // Entitlements
        if options.modifyEntitlements {
            return try EntitlementService.prepareEntitlements(
                appURL: appURL,
                updates: options.entitlementEntries,
                outputDir: workspace
            )
        }
        
        return nil
    }
    
    func updateExtensions(at appURL: URL, newBundleID: String) throws {
        let pluginsURL = appURL.appendingPathComponent("PlugIns")
        
        guard FileManager.default.fileExists(atPath: pluginsURL.path) else { return }
        
        let extensions = try FileManager.default.contentsOfDirectory(at: pluginsURL,
                                                                     includingPropertiesForKeys: nil)
        for ext in extensions where ext.pathExtension == "appex" {
            let plistURL = ext.appendingPathComponent("Info.plist")
            
            guard let plist = NSMutableDictionary(contentsOf: plistURL),
                  let oldBundleID = plist["CFBundleIdentifier"] as? String else { continue }
            
            // Preserve suffix (recommended)
            if let suffix = oldBundleID.split(separator: ".").last {
                plist["CFBundleIdentifier"] = "\(newBundleID).\(suffix)"
            } else {
                plist["CFBundleIdentifier"] = newBundleID
            }
            
            plist.write(to: plistURL, atomically: true)
        }
    }
}

//Mark - Helper Method
fileprivate extension CodeSignService {
    func createWorkspace() throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("IPASignCraft_\(formatter.string(from: Date()))")
        
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        
        return url
    }
}

fileprivate extension CodeSignService {
    func resolveCertificateIdentity(_ input: CertificateRequest) throws -> String {
        switch input {
        case .saved(let cert):
            return cert.name
        case .p12(let url, let password):
            return try importP12AndGetIdentity(url: url, password: password)
        }
    }
    
    func importP12AndGetIdentity(url: URL, password: String) throws -> String {
        
        let keychain = "\(NSHomeDirectory())/Library/Keychains/login.keychain-db"
        
        // 1. Import p12 into keychain
        try ShellExecutor.run("""
        security import "\(url.path)" \
        -k "\(keychain)" \
        -P "\(password)" \
        -T /usr/bin/codesign \
        -T /usr/bin/security
        """)
        
        // 2. Extract identity (SHA-1)
        let output = try ShellExecutor.runWithOutput("""
        security find-identity -v -p codesigning
        """)
        
        // 3. Parse SHA-1 hash
        guard let identity = parseIdentity(from: output.output) else {
            throw NSError(domain: "CodeSign", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to extract signing identity"
            ])
        }
        
        return identity
    }
    
    private func parseIdentity(from output: String) -> String? {
        
        // Example line:
        // 1) ABCDEF1234567890ABCDEF1234567890ABCDEF12 "Apple Development: Name"
        
        let lines = output.split(separator: "\n")
        
        for line in lines {
            if let match = line.range(of: "[A-F0-9]{40}", options: .regularExpression) {
                return String(line[match])
            }
        }
        
        return nil
    }
}
