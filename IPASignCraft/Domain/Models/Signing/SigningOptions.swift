//
//  SigningOptions.swift
//  IPASignCraft
//
//  Created by Saurav Nagpal on 23/04/26.
//


import Foundation

/// Describes all optional modifications applied during IPA signing
struct SigningOptions {
    
    /// Optional bundle identifier override
    var newBundleID: String
    
    /// Info.plist modifications
    var plistEntries: [PlistKeyValue]
    
    /// Entitlement modifications
    var modifyEntitlements: Bool
    var entitlementEntries: [EntitlementEntry]
}
