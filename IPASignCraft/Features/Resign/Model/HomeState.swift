//
//  HomeState.swift
//  IPASignCraft
//
//  Created by Saurav Nagpal on 20/03/26.
//

import Foundation

enum CertificateMode {
    case keychain
    case custom
}

struct HomeState {
    
    // MARK: - Input Files
    
    /// Selected IPA file path
    var ipaURL: URL?
    
    /// Selected provisioning profile path
    var profileURL: URL?
    
    
    // MARK: - App Identity
    
    /// Whether user wants to override bundle identifier
    var useCustomBundleID: Bool = false
    
    /// Bundle identifier (original or overridden)
    var bundleID: String = ""
    
    
    // MARK: - Advanced Options
    
    /// Enable Info.plist modification
    var enablePlistEditing: Bool = false
    
    /// Enable Entitlement modification
    var enableEntitlementEditing: Bool = false
    
    
    // MARK: - Info.plist Modifications
    
    /// User-provided plist key-value entries
    var plistEntries: [PlistKeyValue] = []
    
    
    // MARK: - Entitlement Modifications
    
    /// (Prepared for next step – even if not fully used yet)
    var entitlementEntries: [EntitlementEntry] = []
    
    
    // MARK: - Certificate Configuration
    
    /// Selection between keychian and custom certificate
    var certMode: CertificateMode = .keychain
    
    /// Path to custom .p12 certificate
    var p12Path: String = ""
    
    /// Password for .p12
    var p12Password: String = ""
    
    /// Selected saved certificate
    var selectedCertificate: SigningCertificate?
    
    /// Available certificates
    var certificates: [SigningCertificate] = []
    
    
    // MARK: - Execution State
    
    /// Indicates resign process is running
    var isLoading: Bool = false
    
    /// Indicates Advance  Option Expand/Collapse
    var isAdvancedExpanded = false
    
    // MARK: - UI State
    
    /// Error message to display
    var errorMessage: String?
    
    /// Whether unlock prompt should be shown
    var showUnlockPrompt: Bool = false
    // MARK: - Logs
    
    /// Execution logs
    var log: String = ""
    
    // MARK: - Signing Steps
    var currentStep: SigningStep = .idle
    
    // MARK: - Validation
    var isSigning: Bool = false
    var isResignEnabled: Bool {
        let hasIPA = (ipaURL != nil)
        let hasProfile = (profileURL != nil)
        
        let hasCertificate: Bool = {
            if self.certMode == .custom {
                return !p12Path.isEmpty && !p12Password.isEmpty
            } else {
                return selectedCertificate != nil
            }
        }()
        
        return hasIPA && hasProfile && hasCertificate && !isLoading
    }
}

extension SigningStep {
    var title: String {
        switch self {
        case .idle: return "Idle"
        case .preparing: return "Start Preparing"
        case .extracting: return "Extract IPA"
        case .modifying: return "Modifying IPA"
        case .embeddingProfile: return "Embed Profile"
        case .removeOldSign: return "Remove Old Sign"
        case .applyingCert: return "Apply Certificate"
        case .signing: return "Code Sign"
        case .repackaging: return "Repackage IPA"
        case .completed: return "Completed"
        }
    }
}

extension HomeState {
    var progressIndex: Int {
        guard let index = SigningStep.progressSteps.firstIndex(of: currentStep) else {
            return 0
        }
        return index
    }
    
    var progress: Double {
        let steps = SigningStep.progressSteps
        guard let index = steps.firstIndex(of: currentStep) else {
            return 0
        }
        return Double(index + 1) / Double(steps.count)
    }
}

extension SigningStep {
    static var progressSteps: [SigningStep] {
        [
            .preparing,
            .extracting,
            .modifying,
            .embeddingProfile,
            .removeOldSign,
            .applyingCert,
            .signing,
            .repackaging,
            .completed
        ]
    }

    var progressIndex: Int? {
        Self.progressSteps.firstIndex(of: self)
    }
}

extension HomeState {
    func isStepCompleted(_ step: SigningStep) -> Bool {
        guard
            let currentIndex = SigningStep.progressSteps.firstIndex(of: currentStep),
            let stepIndex = SigningStep.progressSteps.firstIndex(of: step)
        else {
            return false
        }

        return stepIndex < currentIndex
    }
}
