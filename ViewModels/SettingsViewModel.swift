//
//  SettingsViewModel.swift
//  SleepMate
//
//  Created by Claude on Phase 2 Migration
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let settingsManager: SettingsManager
    private let databaseManager: DatabaseManager
    
    // MARK: - Published Properties
    @Published var isDarkModeEnabled = false
    @Published var isHapticsEnabled = true
    @Published var isAutoLockDisabled = true
    @Published var masterVolume: Float = 0.5
    @Published var timerFadeOutDuration: TimeInterval = 10.0
    @Published var defaultTimerDuration: TimeInterval = 1800 // 30 minutes
    
    // MARK: - Premium Features
    @Published var isPremiumUser = false
    @Published var isMultipleSoundsEnabled = false
    @Published var isMultipleBackgroundsEnabled = false
    
    // MARK: - App Info
    @Published var appVersion = "2.5"
    @Published var buildNumber = "115"
    
    // MARK: - State
    @Published var isResetting = false
    @Published var showingResetConfirmation = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(settingsManager: SettingsManager, databaseManager: DatabaseManager) {
        self.settingsManager = settingsManager
        self.databaseManager = databaseManager
        
        loadSettings()
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind to settings manager
        $isDarkModeEnabled
            .dropFirst() // Skip initial value
            .sink { [weak self] value in
                self?.settingsManager.isDarkModeEnabled = value
            }
            .store(in: &cancellables)
        
        $isHapticsEnabled
            .dropFirst()
            .sink { [weak self] value in
                self?.settingsManager.isHapticsEnabled = value
            }
            .store(in: &cancellables)
        
        $isAutoLockDisabled
            .dropFirst()
            .sink { [weak self] value in
                self?.settingsManager.isAutoLockDisabled = value
            }
            .store(in: &cancellables)
        
        $masterVolume
            .dropFirst()
            .sink { [weak self] value in
                self?.settingsManager.masterVolume = value
            }
            .store(in: &cancellables)
        
        $timerFadeOutDuration
            .dropFirst()
            .sink { [weak self] value in
                self?.settingsManager.timerFadeOutDuration = value
            }
            .store(in: &cancellables)
        
        $defaultTimerDuration
            .dropFirst()
            .sink { [weak self] value in
                self?.settingsManager.defaultTimerDuration = value
            }
            .store(in: &cancellables)
    }
    
    private func loadSettings() {
        isDarkModeEnabled = settingsManager.isDarkModeEnabled
        isHapticsEnabled = settingsManager.isHapticsEnabled
        isAutoLockDisabled = settingsManager.isAutoLockDisabled
        masterVolume = settingsManager.masterVolume
        timerFadeOutDuration = settingsManager.timerFadeOutDuration
        defaultTimerDuration = settingsManager.defaultTimerDuration
        
        // Load premium status (would check with StoreKit in real implementation)
        loadPremiumStatus()
        
        // Load app version info
        loadAppInfo()
    }
    
    private func loadPremiumStatus() {
        // This would integrate with StoreKit for real IAP checking
        isPremiumUser = settingsManager.isPremiumUser
        isMultipleSoundsEnabled = settingsManager.isMultipleSoundsEnabled
        isMultipleBackgroundsEnabled = settingsManager.isMultipleBackgroundsEnabled
    }
    
    private func loadAppInfo() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appVersion = version
        }
        
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            buildNumber = build
        }
    }
    
    // MARK: - Actions
    func resetAllSettings() {
        showingResetConfirmation = true
    }
    
    func confirmResetSettings() {
        isResetting = true
        
        Task {
            // Reset settings to defaults
            settingsManager.resetToDefaults()
            
            // Reload settings
            await MainActor.run {
                loadSettings()
                isResetting = false
                successMessage = "Settings reset to defaults"
            }
        }
    }
    
    func resetDatabase() {
        Task {
            // Clear non-favorite items
            await databaseManager.deleteAllEntities("Sound")
            await databaseManager.deleteAllEntities("Background")
            
            // Repopulate with defaults
            await databaseManager.prePopulate()
            
            await MainActor.run {
                successMessage = "Database reset and repopulated"
            }
        }
    }
    
    func exportSettings() -> String {
        let settings: [String: Any] = [
            "isDarkModeEnabled": isDarkModeEnabled,
            "isHapticsEnabled": isHapticsEnabled,
            "isAutoLockDisabled": isAutoLockDisabled,
            "masterVolume": masterVolume,
            "timerFadeOutDuration": timerFadeOutDuration,
            "defaultTimerDuration": defaultTimerDuration
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted)
            return String(data: data, encoding: .utf8) ?? "Export failed"
        } catch {
            errorMessage = "Failed to export settings: \(error.localizedDescription)"
            return "Export failed"
        }
    }
    
    func importSettings(from jsonString: String) {
        do {
            guard let data = jsonString.data(using: .utf8) else {
                throw NSError(domain: "SettingsImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid data"])
            }
            
            let settings = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            if let darkMode = settings?["isDarkModeEnabled"] as? Bool {
                isDarkModeEnabled = darkMode
            }
            if let haptics = settings?["isHapticsEnabled"] as? Bool {
                isHapticsEnabled = haptics
            }
            if let autoLock = settings?["isAutoLockDisabled"] as? Bool {
                isAutoLockDisabled = autoLock
            }
            if let volume = settings?["masterVolume"] as? Float {
                masterVolume = volume
            }
            if let fadeOut = settings?["timerFadeOutDuration"] as? TimeInterval {
                timerFadeOutDuration = fadeOut
            }
            if let timerDefault = settings?["defaultTimerDuration"] as? TimeInterval {
                defaultTimerDuration = timerDefault
            }
            
            successMessage = "Settings imported successfully"
            
        } catch {
            errorMessage = "Failed to import settings: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Premium Features
    func purchasePremium() {
        // This would integrate with StoreKit
        // For now, just toggle the flag
        isPremiumUser = true
        isMultipleSoundsEnabled = true
        isMultipleBackgroundsEnabled = true
        
        settingsManager.isPremiumUser = true
        settingsManager.isMultipleSoundsEnabled = true
        settingsManager.isMultipleBackgroundsEnabled = true
        
        successMessage = "Premium features unlocked!"
    }
    
    func restorePurchases() {
        // This would restore purchases via StoreKit
        loadPremiumStatus()
        successMessage = "Purchases restored"
    }
    
    // MARK: - Helper Methods
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    // MARK: - Validation
    func validateTimerDuration(_ duration: TimeInterval) -> Bool {
        return duration >= 60 && duration <= 7200 // 1 minute to 2 hours
    }
    
    func validateFadeOutDuration(_ duration: TimeInterval) -> Bool {
        return duration >= 1 && duration <= 60 // 1 second to 1 minute
    }
}