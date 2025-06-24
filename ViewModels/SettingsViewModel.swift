//
//  SettingsViewModel.swift
//  SleepMate
//
//  Created by Claude on Phase 2 Migration
//

import Foundation
import SwiftUI
import Combine
import StoreKit

@MainActor
class SettingsViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let settingsManager: SettingsManager
    private let databaseManager: DatabaseManager
    private let storeKitManager = StoreKitManager.shared
    
    // MARK: - Published Properties
    @Published var isHapticsEnabled = true
    @Published var isAutoLockDisabled = true
    @Published var masterVolume: Float = 0.5
    @Published var timerFadeOutDuration: TimeInterval = 10.0
    @Published var defaultTimerDuration: TimeInterval = 1800 // 30 minutes
    
    // MARK: - Tip Jar Features
    @Published var tipProducts: [Product] = []
    @Published var isProcessingPurchase = false
    @Published var totalTipsGiven: Double = 0.0
    @Published var numberOfTips: Int = 0
    
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
        loadTipProducts()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind to settings manager
        
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
        isHapticsEnabled = settingsManager.isHapticsEnabled
        isAutoLockDisabled = settingsManager.isAutoLockDisabled
        masterVolume = settingsManager.masterVolume
        timerFadeOutDuration = settingsManager.timerFadeOutDuration
        defaultTimerDuration = settingsManager.defaultTimerDuration
        
        // Load tip status
        loadTipStatus()
        
        // Load app version info
        loadAppInfo()
    }
    
    private func loadTipStatus() {
        totalTipsGiven = storeKitManager.totalTipAmount
        numberOfTips = storeKitManager.numberOfTips
    }
    
    private func loadTipProducts() {
        Task {
            await storeKitManager.loadProducts()
            await MainActor.run {
                self.tipProducts = storeKitManager.products
            }
        }
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
    
    // MARK: - Tip Jar Features
    func purchaseTip(_ product: Product) {
        isProcessingPurchase = true
        
        Task {
            // Listen for purchase success notification
            let purchaseObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("PurchaseSuccessful"),
                object: nil,
                queue: .main
            ) { [weak self] notification in
                if let productId = notification.userInfo?["productId"] as? String,
                   productId == product.id {
                    self?.successMessage = "Thank you for your support! ❤️"
                    self?.loadTipStatus()
                    self?.isProcessingPurchase = false
                }
            }
            
            let errorObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("PurchaseFailed"),
                object: nil,
                queue: .main
            ) { [weak self] notification in
                if let error = notification.userInfo?["error"] as? Error {
                    self?.errorMessage = "Purchase failed: \(error.localizedDescription)"
                } else {
                    self?.errorMessage = "Purchase was cancelled"
                }
                self?.isProcessingPurchase = false
            }
            
            // Attempt the purchase
            await storeKitManager.purchase(product)
            
            // Clean up observers after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                NotificationCenter.default.removeObserver(purchaseObserver)
                NotificationCenter.default.removeObserver(errorObserver)
            }
        }
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