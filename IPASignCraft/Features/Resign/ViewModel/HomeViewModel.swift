import Foundation
import SwiftUI
import Combine
internal import UniformTypeIdentifiers

@MainActor
class HomeViewModel: ObservableObject {
    @Published var state = HomeState()
    private let resignService = CodeSignService()

    init() {
        loadSigningIdentity()
        self.state.log += self.state.currentStep.consoleMessage
    }

    // MARK: - Load Certificates

    func loadSigningIdentity() {
        Task {
            await loadCertificates()
        }
    }

    private func loadCertificates() async {
        state.isLoading = true
        do {
            let certs = try KeychainService.fetchCertificates()

            state.certificates = certs

            if state.selectedCertificate == nil {
                state.selectedCertificate = certs.first
            }

        } catch KeychainError.locked {
            state.showUnlockPrompt = true
        } catch {
            state.errorMessage = error.localizedDescription
        }

        state.isLoading = false
    }

    // MARK: - Unlock

    func unlockKeychain(password: String) {
        Task {
            do {
                let certs = try KeychainService.fetchCertificatesAfterUnlock(password: password)
                state.certificates = certs
                state.selectedCertificate = certs.first
                state.showUnlockPrompt = false

            } catch {
                state.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Update Inputs
    func updateIPAPath(_ path: String) {
        state.log += "\n[READY] IPA package loaded\n"
        let ipaURL = URL(fileURLWithPath: path)
        state.ipaURL = ipaURL
    }

    func updateProfilePath(_ path: String) {
        state.log += "[READY] Provisioning profile loaded\n"
        let profileURL = URL(fileURLWithPath: path)
        state.profileURL = profileURL
        if let bundleID = self.bundleIdentifier(forProfileAtPath: path) {
            state.bundleID = bundleID
            state.useCustomBundleID = true
        }
    }
    
    func addPlistEntry() {
        state.plistEntries.append(PlistKeyValue())
    }

    func removePlistEntry(_ id: UUID) {
        state.plistEntries.removeAll { $0.id == id }
    }
    
    func addEntitlementPreset(_ type: EntitlementPreset) {
        
        let newEntry: EntitlementEntry
        
        switch type {
            
        case .pushNotifications(let env):
            newEntry = EntitlementEntry(
                key: "aps-environment",
                value: .string(env.rawValue)
            )
            
        case .appGroups(let groupID):
            newEntry = EntitlementEntry(
                key: "com.apple.security.application-groups",
                value: .array([.string(groupID)])
            )
            
        case .keychainSharing(let bundleID):
            newEntry = EntitlementEntry(
                key: "keychain-access-groups",
                value: .array([
                    .string("$(AppIdentifierPrefix)\(bundleID)")
                ])
            )
        }
        
        if let index = state.entitlementEntries.firstIndex(where: { $0.key == newEntry.key }) {
            let existing = state.entitlementEntries[index]
            
            if case .array(let oldArray) = existing.value,
               case .array(let newArray) = newEntry.value {
                
                let merged = oldArray + newArray
                state.entitlementEntries[index].value = .array(merged)
                
            } else {
                state.entitlementEntries[index] = newEntry
            }
            
        } else {
            state.entitlementEntries.append(newEntry)
        }
    }
    
    func addEntitlementEntry(
        key: String = "",
        value: EntitlementValue = .string("")
    ) {
        state.entitlementEntries.append(
            EntitlementEntry(key: key, value: value)
        )
    }
    
    func removeEntitlementEntry(_ id: UUID) {
        state.entitlementEntries.removeAll { $0.id == id }
    }

    // MARK: - Resign
    func resign() {
        guard let ipaURL = state.ipaURL, let profileURL = state.profileURL else {
            state.log = "IPA is missing or profile is misisng...\n"
            return
        }
        guard let selectedCertificate = self.getSigningRequest() else {
            state.log = "Invalid Certificate...\n"
            return
        }
        
        let signingOptions = SigningOptions(
            newBundleID: self.state.bundleID,
            plistEntries: self.state.plistEntries,
            modifyEntitlements: self.state.enableEntitlementEditing,
            entitlementEntries: self.state.entitlementEntries
        )
        
        self.state.isSigning = true
        state.log = "Starting resign process...\n"
        Task.detached {
            do {
                let result = try await self.resignService.resignIPA(
                    ipaURL: ipaURL,
                    profileURL: profileURL,
                    certificate: selectedCertificate,
                    options: signingOptions
                ) { step in
                    Task { @MainActor in
                        self.state.currentStep = step
                        self.state.log += "\(step.consoleMessage) \n"
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.state.log += "Finished\nOutput: \(result)\n"
                    self.saveIPA(at: result)
                    self.resetState()
                }

            } catch {
                await MainActor.run {
                    self.resetState()
                    self.state.log += "Error: \(error.localizedDescription)\n"
                }
            }
        }
    }
}

fileprivate extension HomeViewModel {
    func bundleIdentifier(forProfileAtPath path: String) -> String? {
        do {
            return try ProvisionExtractService.extractBundleID(from: path)
        } catch {
            state.log += "Error: \(error.localizedDescription)\n"
        }
        return nil
    }
    
    func getSigningRequest() -> CertificateRequest? {
        if self.state.certMode == .custom {
            let p12URL = URL(fileURLWithPath: state.p12Path)
            return CertificateRequest.p12(url: p12URL, password: state.p12Password)
        } else if let selectedCertificate = state.selectedCertificate {
            return CertificateRequest.saved(selectedCertificate)
        }
        return nil
    }
    
    func saveIPA(at tempURL: URL) {
        let panel = NSSavePanel()
        panel.title = "Save Resigned IPA"
        panel.nameFieldStringValue = "resigned.ipa"
        panel.allowedContentTypes = [.data]

        panel.begin { response in
            if response == .OK, let destinationURL = panel.url {
                do {
                    let finalURL = destinationURL.pathExtension.lowercased() == "ipa"
                        ? destinationURL
                        : destinationURL.appendingPathExtension("ipa")

                    try FileManager.default.copyItem(at: tempURL, to: finalURL)
                } catch {
                    print("Save failed:", error)
                }
            }
        }
    }
}

//MARK: - State Handling
fileprivate extension HomeViewModel {
    func resetState() {
        self.state.isSigning = false
        self.state.currentStep = .idle
        self.state.log = ""
        self.state.log += self.state.currentStep.consoleMessage
    }
}
