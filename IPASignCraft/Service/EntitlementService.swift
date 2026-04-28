//
//  EntitlementService.swift
//  IPASignCraft
//
//  Created by Saurav Nagpal on 07/04/26.
//

import Foundation

import Foundation

struct EntitlementService {
    
    /// Generates final signing entitlements using:
    /// 1. Provisioning profile as authoritative base
    /// 2. Existing app entitlements as optional feature supplement
    /// 3. User custom updates as final override
    static func prepareEntitlements(
        appURL: URL,
        profileURL: URL,
        updates: [EntitlementEntry],
        outputDir: URL
    ) throws -> URL {
        
        // Step 1: Extract entitlements from provisioning profile (authoritative signing truth)
        let profileRaw = try extractProfileEntitlements(from: profileURL)
        
        // Step 2: Extract entitlements from original app (feature supplement only)
        let appRaw = try extractAppEntitlements(from: appURL)
        
        // Step 3: Convert to typed model
        let profileBase = convertToModel(profileRaw)
        let appExisting = convertToModel(appRaw)
        
        // Step 4: Merge safe app entitlements into provisioning base
        var merged = mergeSafeAppEntitlements(
            profileBase: profileBase,
            appExisting: appExisting
        )
        
        // Step 5: Apply user manual updates last
        let updateDict = Dictionary(uniqueKeysWithValues: updates.map { ($0.key, $0.value) })
        merged = mergeUserUpdates(base: merged, updates: updateDict)
        
        // Step 6: Convert back to plist and write
        let finalPlist = merged.mapValues { $0.toAny() }
        let entitlementsURL = outputDir.appendingPathComponent("final_entitlements.plist")
        
        try write(finalPlist, to: entitlementsURL)
        
        return entitlementsURL
    }
}

private extension EntitlementService {
    
    /// Extracts entitlements directly from provisioning profile.
    static func extractProfileEntitlements(from profileURL: URL) throws -> [String: Any] {
        
        let decoded = try ShellExecutor.runWithOutput("""
        security cms -D -i "\(profileURL.path)"
        """)
        
        guard let data = decoded.output.data(using: .utf8) else {
            throw IPASignCraftError.entitlementExtractionFailed
        }
        
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        
        guard
            let dict = plist as? [String: Any],
            let entitlements = dict["Entitlements"] as? [String: Any]
        else {
            throw IPASignCraftError.entitlementExtractionFailed
        }
        
        return entitlements
    }
    
    /// Extracts currently embedded entitlements from original app binary.
    static func extractAppEntitlements(from appURL: URL) throws -> [String: Any] {
        
        let result = try ShellExecutor.runWithOutput("""
        /usr/bin/codesign -d --entitlements :- "\(appURL.path)"
        """)
        
        guard let data = result.output.data(using: .utf8) else {
            return [:]
        }
        
        let plist = try? PropertyListSerialization.propertyList(from: data, format: nil)
        return plist as? [String: Any] ?? [:]
    }
}

private extension EntitlementService {
    
    static func convertToModel(
        _ raw: [String: Any]
    ) -> [String: EntitlementValue] {
        raw.compactMapValues {
            EntitlementValue.from(any: $0)
        }
    }
}

private extension EntitlementService {
    
    /// Merges only non-protected feature entitlements from original app.
    /// Apple identity-critical keys are always preserved from provisioning profile.
    static func mergeSafeAppEntitlements(
        profileBase: [String: EntitlementValue],
        appExisting: [String: EntitlementValue]
    ) -> [String: EntitlementValue] {
        
        var result = profileBase
        
        for (key, value) in appExisting {
            
            // Never allow original app to overwrite protected signing identity keys
            if protectedKeys.contains(key) {
                continue
            }
            
            // If profile does not contain this feature entitlement, preserve app capability
            if result[key] == nil {
                result[key] = value
                continue
            }
            
            // Merge arrays without duplicates
            if case .array(let oldArray)? = result[key],
               case .array(let newArray) = value {
                
                result[key] = .array(removeDuplicates(oldArray + newArray))
            }
        }
        
        return result
    }
    
    /// Applies user manual overrides after all automatic merging.
    static func mergeUserUpdates(
        base: [String: EntitlementValue],
        updates: [String: EntitlementValue]
    ) -> [String: EntitlementValue] {
        
        var result = base
        
        for (key, value) in updates {
            if case .array(let oldArray)? = result[key],
               case .array(let newArray) = value {
                
                result[key] = .array(removeDuplicates(oldArray + newArray))
            } else {
                result[key] = value
            }
        }
        
        return result
    }
    
    static func removeDuplicates(_ array: [EntitlementValue]) -> [EntitlementValue] {
        var seen = Set<String>()
        
        return array.filter {
            let token = "\($0)"
            if seen.contains(token) { return false }
            seen.insert(token)
            return true
        }
    }
}

private extension EntitlementService {
    
    /// These keys define Apple signing identity and must come only from provisioning profile.
    static let protectedKeys: Set<String> = [
        "application-identifier",
        "com.apple.developer.team-identifier",
        "keychain-access-groups",
        "get-task-allow",
        "aps-environment"
    ]
}

private extension EntitlementService {
    static func write(
        _ plist: [String: Any],
        to url: URL
    ) throws {
        
        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        
        try data.write(to: url)
    }
}
