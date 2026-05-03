//
//  ContentView.swift
//  IPASignCraft
//
//  Created by Saurav Nagpal on 16/03/26.
//

import SwiftUI

/// Main screen for IPA re-signing workflow
/// Responsible only for layout + binding UI to ViewModel state
struct HomeView: View {
    /// Central state holder for all signing inputs and progress
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        ZStack {
            /// Background layer (visual only, no interaction)
            homeBackground
            
            /// Main two-column layout
            HStack(alignment: .top, spacing: Spacing.xxl) {
                leftSection.frame(maxWidth: 720)       // Input + configuration
                rightSection     // Status + logs
                    .frame(width: 320)
            }
            .padding(.horizontal, Spacing.md)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

// MARK: - Background
private extension HomeView {
    /// Watercolor background with soft overlay for readability
    var homeBackground: some View {
        GeometryReader { geo in
            Image("homeBgWatercolor")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .overlay(Color.white.opacity(0.6))
        }
    }
}

//MARK: - Input Section
private extension HomeView {
    /// Left column: user inputs and configuration
    var leftSection: some View {
        ScrollView {
            VStack(spacing: Spacing.base) {
                headerSection
                ipaSection
                provisionSection
                advancedSection
                certificateSection
                actionSection
            }
            .padding(.vertical, Spacing.base)
            .padding(.leading, Spacing.base)
            .padding(.trailing, Spacing.xxl)
            .frame(maxWidth: 720)
        }
    }
}

//MARK: - output Section
private extension HomeView {
    /// Right column: signing progress and logs
    var rightSection: some View {
        VStack(spacing: Spacing.base) {
            progressSection
            logsSection
            Spacer()
        }
        .padding(.top, Spacing.lg)
    }
}

// MARK: - Header
private extension HomeView {
    /// App title and short description
    var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("IPASignCraft")
                .font(AppFont.title)
            
            Text("Craft a new signature for your IPA")
                .font(AppFont.secondary)
                .foregroundColor(AppColors.secondaryText)
        }
    }
}

private extension HomeView {
    /// IPA input: drag/drop or browse file
    var ipaSection: some View {
        HomeSectionView("IPA File") {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                
                /// Helper text for clarity
                Text("Select or drop the IPA you want to re-sign")
                    .font(AppFont.secondary)
                    .foregroundColor(AppColors.secondaryText)
                
                /// File input binding to ViewModel
                FileDropView(
                    title: nil,
                    filePath: Binding(
                        get: { viewModel.state.ipaURL?.path ?? ""},
                        set: { viewModel.updateIPAPath($0) }
                    ),
                    supportedTypes: [.ipa]
                )

                /// Show file summary when selected
                if let ipaPath = viewModel.state.ipaURL?.path {
                    infoRow(
                        icon: "doc.fill",
                        color: AppColors.accent,
                        title: (ipaPath as NSString).lastPathComponent,
                        subtitle: "Ready for signing"
                    )
                }
            }
        }
    }
}

private extension HomeView {
    /// Provisioning profile selection and validation
    var provisionSection: some View {
        HomeSectionView("Provisioning Profile") {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                
                Text("Select the provisioning profile to embed")
                    .font(AppFont.secondary)
                    .foregroundColor(AppColors.secondaryText)
                
                /// Profile picker
                FilePickerView(
                    title: "Select Profile",
                    supportedTypes: [.mobileProvision],
                    filePath: Binding(
                        get: { viewModel.state.profileURL?.path ?? "" },
                        set: { viewModel.updateProfilePath($0) }
                    )
                )
                
                /// Display selected profile info
                if let profilePath = viewModel.state.profileURL?.path {
                    infoRow(
                        icon: "checkmark.seal.fill",
                        color: AppColors.success,
                        title: (profilePath as NSString).lastPathComponent,
                        subtitle: "Profile ready"
                    )
                    /// Derived bundle identifier
                    Text("Bundle ID: \(viewModel.state.bundleID)")
                        .font(AppFont.secondary)
                }
            }
        }
    }
}

// MARK: - Advance Section
fileprivate extension HomeView {
    var advancedSection: some View {
        HomeSectionView("") {
            VStack(alignment: .leading, spacing: Spacing.base) {
                
                // Header Row
                HStack {
                    Label("Advanced Options", systemImage: "slider.horizontal.3")
                        .font(AppFont.section)
                    
                    Spacer()
                    
                    Toggle("", isOn: self.$viewModel.state.isAdvancedExpanded)
                        .labelsHidden()
                }
                
                // Optional hint
                Text("Optional customization for advanced users")
                    .font(AppFont.secondary)
                    .foregroundColor(AppColors.secondaryText)
                
                // Content
                if self.viewModel.state.isAdvancedExpanded {
                    VStack(spacing: Spacing.base) {
                        
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Info.plist")
                                .font(AppFont.body)
                            plistSection
                        }
                        
                        Divider().opacity(0.2)
                        
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Entitlements")
                                .font(AppFont.body)
                            entitlementSection
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
}

fileprivate extension HomeView {
    var plistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Info.plist Modifications")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("+ Add") {
                    viewModel.addPlistEntry()
                }
            }
            
            ForEach($viewModel.state.plistEntries) { $entry in
                HStack(spacing: 10) {
                    
                    TextField("Key", text: $entry.key)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Value", text: $entry.value)
                        .textFieldStyle(.roundedBorder)
                    
                    Button {
                        viewModel.removePlistEntry(entry.id)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
        }
    }
}

fileprivate extension HomeView {
    var entitlementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Entitlement Modifications")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Menu("Add Capability") {
                    Button("Push Notifications") {
                        viewModel.addEntitlementPreset(.pushNotifications(environment: .production))
                    }
                    
                    Button("App Groups") {
                        viewModel.addEntitlementPreset(.appGroups(groupID: ""))
                    }
                    
                    Button("Keychain Sharing") {
                        viewModel.addEntitlementPreset(.keychainSharing(bundleID: ""))
                    }
                }
                
                Button("+ Add") {
                    viewModel.addEntitlementEntry()
                }
            }
            
            Text("Example: aps-environment → development")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach($viewModel.state.entitlementEntries) { $entry in
                VStack(alignment: .leading, spacing: 8) {
                    
                    HStack(spacing: 10) {
                        
                        TextField("Key", text: $entry.key)
                            .textFieldStyle(.roundedBorder)
                        
                        EntitlementTypePicker(entry: $entry)
                        
                        Button {
                            viewModel.removeEntitlementEntry(entry.id)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    entitlementValueInput(for: $entry)
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
        }
    }
    
    @ViewBuilder
    func entitlementValueInput(for entry: Binding<EntitlementEntry>) -> some View {
        
        switch entry.wrappedValue.value {
            
        case .string:
            stringInput(for: entry)
            
        case .bool:
            boolInput(for: entry)
            
        case .array(let values):
            arrayInput(for: entry, values: values)
        }
    }
    
    private func stringInput(for entry: Binding<EntitlementEntry>) -> some View {
        TextField(
            "Value",
            text: Binding(
                get: {
                    if case .string(let value) = entry.wrappedValue.value {
                        return value
                    }
                    return ""
                },
                set: { newValue in
                    entry.wrappedValue.value = .string(newValue)
                }
            )
        )
        .textFieldStyle(.roundedBorder)
    }
    
    private func boolInput(for entry: Binding<EntitlementEntry>) -> some View {
        Toggle(
            "Enabled",
            isOn: Binding(
                get: {
                    if case .bool(let value) = entry.wrappedValue.value {
                        return value
                    }
                    return false
                },
                set: { newValue in
                    entry.wrappedValue.value = .bool(newValue)
                }
            )
        )
    }
    
    private func arrayInput(
        for entry: Binding<EntitlementEntry>,
        values: [EntitlementValue]
    ) -> some View {
        
        VStack(alignment: .leading, spacing: 8) {
            
            ForEach(values.indices, id: \.self) { index in
                HStack(spacing: 8) {
                    
                    TextField(
                        "Item \(index + 1)",
                        text: Binding(
                            get: {
                                if case .string(let str) = values[index] {
                                    return str
                                }
                                return ""
                            },
                            set: { newValue in
                                var updated = values
                                updated[index] = .string(newValue)
                                entry.wrappedValue.value = .array(updated)
                            }
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                    
                    Button {
                        var updated = values
                        updated.remove(at: index)
                        entry.wrappedValue.value = .array(updated)
                    } label: {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            Button("+ Add Item") {
                if case .array(let values) = entry.wrappedValue.value {
                    entry.wrappedValue.value = .array(values + [.string("")])
                }
            }
            .font(.caption)
        }
    }
}

// MARK: -  Certificate Section
private extension HomeView {
    /// Certificate selection (custom or saved)
    var certificateSection: some View {
        HomeSectionView("Certificate") {
            VStack(alignment: .leading, spacing: Spacing.base) {
                
                // MARK: - Selection (Centered)
                Picker("", selection: self.$viewModel.state.certMode) {
                    Text("Keychain Certificate").tag(CertificateMode.keychain)
                    Text("Custom (.p12)").tag(CertificateMode.custom)
                }
                .pickerStyle(.segmented)
                .tint(AppColors.accent)
                .frame(maxWidth: 320) // keeps it compact (macOS style)
                .frame(maxWidth: .infinity, alignment: .center)
                
                // MARK: - Content
                Group {
                    if self.viewModel.state.certMode == .custom {
                        customCertificateView
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        savedCertificateView
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }.frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// Custom certificate input (.p12 + password)
    var customCertificateView: some View {
        VStack(alignment: .leading, spacing: Spacing.base) {
            // File picker
            FilePickerView(
                title: "Select .p12",
                supportedTypes: [.p12],
                filePath: $viewModel.state.p12Path
            )
            
            // Password input
            SecureField("Password", text: $viewModel.state.p12Password)
                .textFieldStyle(.roundedBorder)
        }
        .fieldContainer()
    }
    
    /// Saved certificate selection from local store
    var savedCertificateView: some View {
        VStack(alignment: .leading, spacing: Spacing.base) {
            CertificatePickerView(
                title: "Keychian Certificate",
                certificates: viewModel.state.certificates,
                selected: $viewModel.state.selectedCertificate
            )
        }
        .fieldContainer()
    }
}

// MARK: - Actions Section
private extension HomeView {
    /// Final trigger for signing process
    var actionSection: some View {
        HomeSectionView("Action") {
            VStack(spacing: Spacing.sm) {
                
                /// Dynamic status hint
                Text(actionStatusText)
                    .font(AppFont.secondary)
                    .foregroundColor(AppColors.secondaryText)
                
                /// Primary action button
                PrimaryButton(
                    title: viewModel.state.isSigning ? "Signing..." : "Re-sign IPA",
                    action: {
                        viewModel.resign()
                    },
                    isEnabled: viewModel.state.isResignEnabled && !viewModel.state.isSigning
                )
            }
        }
    }
    
    /// Derived UI message based on state
    var actionStatusText: String {
        if viewModel.state.isSigning {
            return "Signing in progress..."
        }
        return viewModel.state.isResignEnabled
        ? "Ready to re-sign IPA"
        : "Select required inputs to enable signing"
    }
}

fileprivate extension HomeView {
    var progressSection: some View {
        AppCard {
            Label("Signing Status", systemImage: "waveform.path.ecg")
            
            VStack(alignment: .leading, spacing: 14) {
                
                // Progress bar driven by step index
                ProgressView(value: viewModel.state.progress).tint(AppColors.accent)
                ForEach(SigningStep.workflow, id: \.self) { step in
                    statusRow(for: step)
                }
            }
        }
    }
    
    func statusRow(for step: SigningStep) -> some View {
        let isCompletedState = viewModel.state.currentStep == .completed
        let isCurrent = (step == viewModel.state.currentStep)
        let isDone = viewModel.state.isStepCompleted(step) || (isCompletedState && step != .completed)

        return HStack {
            Image(systemName: iconName(step: step, isCurrent: isCurrent, done: isDone))
                .foregroundColor(iconColor(step: step, isCurrent: isCurrent, done: isDone))

            Text(step.title)
                .font(.caption)
                .fontWeight((isCurrent || (isCompletedState && step == .completed)) ? .semibold : .regular)

            Spacer()
        }
    }
    
    func iconName(step: SigningStep, isCurrent: Bool, done: Bool) -> String {
        if step == .completed && isCurrent {
            return "checkmark.seal.fill"
        }

        if isCurrent {
            return "arrow.triangle.2.circlepath.circle.fill"
        }

        if done {
            return "checkmark.circle.fill"
        }

        return "circle"
    }

    func iconColor(step: SigningStep, isCurrent: Bool, done: Bool) -> Color {
        if step == .completed && isCurrent {
            return AppColors.accent
        }

        if isCurrent {
            return AppColors.accentHover
        }

        if done {
            return AppColors.accent
        }

        return .gray
    }
}

// MARK: - Log Section
fileprivate extension HomeView {
    var logsSection: some View {
        AppCard {
            HStack {
                Label("Logs", systemImage: "terminal")
                Spacer()
                Button("Clear") {
                    
                }
            }
            
            ScrollView {
                Text(viewModel.state.log)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(height: 260)
            .background(Color.black.opacity(0.9))
            .cornerRadius(10)
            .foregroundColor(.green)
        }
    }
}

//MARK: - Resusable
fileprivate extension HomeView {
    /// Small reusable row for selected file summaries
    func infoRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.secondary)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(AppFont.secondary)
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
        }
        .fieldContainer()
    }
}

#Preview {
    HomeView()
}
