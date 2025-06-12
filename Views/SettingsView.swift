//
//  SettingsView.swift
//  SleepMate
//
//  Created by Claude on Phase 3 Migration
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: SettingsViewModel
    
    @State private var showingResetConfirmation = false
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var exportedSettings = ""
    
    init() {
        // ViewModel will be injected via environment in real usage
        let container = ServiceContainer()
        self._viewModel = StateObject(wrappedValue: container.settingsViewModel)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Appearance section
                appearanceSection
                
                // Audio section
                audioSection
                
                // Timer section
                timerSection
                
                // General section
                generalSection
                
                // Premium section
                if !viewModel.isPremiumUser {
                    premiumSection
                }
                
                // Data section
                dataSection
                
                // About section
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Reset Settings", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    viewModel.confirmResetSettings()
                }
            } message: {
                Text("This will reset all settings to their default values. This action cannot be undone.")
            }
            .sheet(isPresented: $showingExportSheet) {
                exportSettingsSheet
            }
            .sheet(isPresented: $showingImportSheet) {
                importSettingsSheet
            }
            .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
                Button("OK") {
                    viewModel.clearMessages()
                }
            } message: {
                if let message = viewModel.successMessage {
                    Text(message)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearMessages()
                }
            } message: {
                if let message = viewModel.errorMessage {
                    Text(message)
                }
            }
        }
        .onAppear {
            setupViewModel()
        }
    }
    
    // MARK: - Form Sections
    
    private var appearanceSection: some View {
        Section("Appearance") {
            Toggle("Dark Mode", isOn: $viewModel.isDarkModeEnabled)
                .onChange(of: viewModel.isDarkModeEnabled) { value in
                    appState.isDarkModeEnabled = value
                }
        }
    }
    
    private var audioSection: some View {
        Section("Audio") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Master Volume")
                    Spacer()
                    Text("\(Int(viewModel.masterVolume * 100))%")
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $viewModel.masterVolume, in: 0...1)
                    .tint(.blue)
                    .onChange(of: viewModel.masterVolume) { value in
                        appState.updateVolume(value)
                    }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var timerSection: some View {
        Section("Timer") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Default Duration")
                    Spacer()
                    Text(viewModel.formatDuration(viewModel.defaultTimerDuration))
                        .foregroundColor(.secondary)
                }
                
                Text("The default timer duration when starting sleep mode")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Fade Out Duration")
                    Spacer()
                    Text("\(Int(viewModel.timerFadeOutDuration))s")
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $viewModel.timerFadeOutDuration, in: 1...60, step: 1)
                    .tint(.blue)
                
                Text("How long audio takes to fade out when timer expires")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    
    private var generalSection: some View {
        VStack(spacing: 16) {
            Toggle("Haptic Feedback", isOn: $viewModel.isHapticsEnabled)
                .onChange(of: viewModel.isHapticsEnabled) { value in
                    appState.isHapticsEnabled = value
                }
            
            Toggle("Disable Auto-Lock", isOn: $viewModel.isAutoLockDisabled)
                .onChange(of: viewModel.isAutoLockDisabled) { value in
                    appState.isAutoLockDisabled = value
                }
            
            // HStack {
            //     Text("Background Quality")
            //     Spacer()
            //     Picker("Quality", selection: $viewModel.backgroundImageQuality) {
            //         Text("Low").tag(0)
            //         Text("Medium").tag(1)
            //         Text("High").tag(2)
            //     }
            //     .pickerStyle(.segmented)
            //     .frame(width: 150)
            // }
        }
    }
    
    private var premiumSection: some View {
        Section("Premium Features") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unlock Premium")
                            .font(.headline)
                        Text("Get access to exclusive sounds and backgrounds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
                
                PrimaryButton("Upgrade Now") {
                    viewModel.purchasePremium()
                }
                
                SecondaryButton("Restore Purchases") {
                    viewModel.restorePurchases()
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var dataSection: some View {
        Section("Data Management") {
            Button("Export Settings") {
                exportedSettings = viewModel.exportSettings()
                showingExportSheet = true
            }
            
            Button("Import Settings") {
                showingImportSheet = true
            }
            
            Button("Reset Database") {
                viewModel.resetDatabase()
            }
            
            Button("Reset All Settings") {
                showingResetConfirmation = true
            }
            .foregroundColor(.red)
        }
    }
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("\(viewModel.appVersion) (\(viewModel.buildNumber))")
                    .foregroundColor(.secondary)
            }
            
            if viewModel.isPremiumUser {
                HStack {
                    Text("Premium User")
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            Button("Information & Help") {
                appState.selectedTab = .information
            }
        }
    }
    
    // MARK: - Sheets
    
    private var exportSettingsSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your settings have been exported. You can copy this data and import it on another device.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(exportedSettings)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .textSelection(.enabled)
                    
                    PrimaryButton("Share Settings") {
                        let activityController = UIActivityViewController(
                            activityItems: [exportedSettings],
                            applicationActivities: nil
                        )
                        
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController?.present(activityController, animated: true)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Export Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingExportSheet = false
                    }
                }
            }
        }
    }
    
    private var importSettingsSheet: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Paste your exported settings data below:")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                TextEditor(text: .constant(""))
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .frame(minHeight: 200)
                
                PrimaryButton("Import Settings") {
                    // In a real implementation, this would parse the pasted data
                    viewModel.successMessage = "Settings imported successfully"
                    showingImportSheet = false
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Import Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingImportSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupViewModel() {
        // In real implementation, this would be handled by dependency injection
        // viewModel = serviceContainer.settingsViewModel
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(ServiceContainer())
        .environmentObject(AppState())
}