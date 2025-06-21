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
    @StateObject private var viewModel = ServiceContainer.shared.settingsViewModel
    
    @State private var showingResetConfirmation = false
    
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
                
                // Data section removed
                
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
                    appState.updateColorScheme(isDarkMode: value)
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
        Section("General") {
            Toggle("Haptic Feedback", isOn: $viewModel.isHapticsEnabled)
                .onChange(of: viewModel.isHapticsEnabled) { value in
                    appState.isHapticsEnabled = value
                }
            
            Toggle("Disable Auto-Lock", isOn: $viewModel.isAutoLockDisabled)
                .onChange(of: viewModel.isAutoLockDisabled) { value in
                    appState.isAutoLockDisabled = value
                }
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