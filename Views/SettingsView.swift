//
//  SettingsView.swift
//  SleepMate
//
//  Created by Claude on Phase 3 Migration
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ServiceContainer.shared.settingsViewModel
    
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                // Audio section
                audioSection
                
                // Timer section
                timerSection
                
                // General section
                generalSection
                
                // Tip Jar section
                tipJarSection
                
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
    
    private var tipJarSection: some View {
        Section("Support Development") {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sleepster relies on your support to fund its development. If you find it useful to enhance your sleep, please consider supporting the app by leaving a tip in our Tip Jar.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                HStack(spacing: 12) {
                    ForEach(viewModel.tipProducts, id: \.id) { product in
                        tipButton(for: product)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
        }
    }
    
    private func tipButton(for product: Product) -> some View {
        Button {
            HapticFeedback.light()
            viewModel.purchaseTip(product)
        } label: {
            VStack(spacing: 8) {
                // Get the tip type from product ID
                if let tipType = StoreKitManager.ProductType(rawValue: product.id) {
                    Text(tipType.emoji)
                        .font(.title)
                    
                    Text(tipType.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Tip of")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(product.displayPrice)
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .foregroundColor(.primary)
        }
        .disabled(viewModel.isProcessingPurchase)
    }
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("\(viewModel.appVersion) (\(viewModel.buildNumber))")
                    .foregroundColor(.secondary)
            }
            
            if viewModel.numberOfTips > 0 {
                HStack {
                    Text("Supporter")
                    Spacer()
                    HStack(spacing: 4) {
                        Text("\(viewModel.numberOfTips)")
                            .fontWeight(.semibold)
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
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