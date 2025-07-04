//
//  SettingsManager.swift
//  SleepMate
//
//  Created by Claude on Phase 2 Migration
//

import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let isHapticsEnabled = "isHapticsEnabled"
        static let isAutoLockDisabled = "isAutoLockDisabled"
        static let masterVolume = "masterVolume"
        static let lastVolume = "lastVolume"
        static let timerFadeOutDuration = "timerFadeOutDuration"
        static let defaultTimerDuration = "defaultTimerDuration"
        static let lastTimerDuration = "lastTimerDuration"
        static let isPremiumUser = "isPremiumUser"
        static let isMultipleSoundsEnabled = "isMultipleSoundsEnabled"
        static let isMultipleBackgroundsEnabled = "isMultipleBackgroundsEnabled"
        static let appLaunchCount = "appLaunchCount"
        static let lastAppVersion = "lastAppVersion"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let selectedSoundID = "selectedSoundID"
        static let selectedBackgroundID = "selectedBackgroundID"
        static let backgroundImageQuality = "backgroundImageQuality"
        static let isAnalyticsEnabled = "isAnalyticsEnabled"
        static let lastDatabaseVersion = "lastDatabaseVersion"
        static let isAutoBrightnessEnabled = "isAutoBrightnessEnabled"
        static let lastBrightnessLevel = "lastBrightnessLevel"
        static let sleepModeBrightnessLevel = "sleepModeBrightnessLevel"
    }
    
    // MARK: - Default Values
    private enum Defaults {
        static let isHapticsEnabled = true
        static let isAutoLockDisabled = true
        static let masterVolume: Float = 0.5
        static let lastVolume: Float = 0.5
        static let timerFadeOutDuration: TimeInterval = 10.0
        static let defaultTimerDuration: TimeInterval = 300.0 // 5 minutes
        static let lastTimerDuration: TimeInterval = 300.0
        static let isPremiumUser = false
        static let isMultipleSoundsEnabled = false
        static let isMultipleBackgroundsEnabled = false
        static let appLaunchCount = 0
        static let hasCompletedOnboarding = false
        static let backgroundImageQuality = 1 // 0=low, 1=medium, 2=high
        static let isAnalyticsEnabled = true
        static let lastDatabaseVersion = 1
        static let isAutoBrightnessEnabled = true
        static let lastBrightnessLevel: Double = 0.5
        static let sleepModeBrightnessLevel: Double = 0.1
    }
    
    private let userDefaults = UserDefaults.standard
    
    // MARK: - App Preferences
    
    @Published var isHapticsEnabled: Bool {
        didSet { 
            userDefaults.set(isHapticsEnabled, forKey: Keys.isHapticsEnabled)
            updateHapticFeedback()
        }
    }
    
    @Published var isAutoLockDisabled: Bool {
        didSet { 
            userDefaults.set(isAutoLockDisabled, forKey: Keys.isAutoLockDisabled)
            updateAutoLockSetting()
        }
    }
    
    // MARK: - Audio Settings
    var masterVolume: Float {
        get { userDefaults.float(forKey: Keys.masterVolume) }
        set { 
            userDefaults.set(newValue, forKey: Keys.masterVolume)
            objectWillChange.send()
        }
    }
    
    var lastVolume: Float {
        get { userDefaults.float(forKey: Keys.lastVolume) }
        set { userDefaults.set(newValue, forKey: Keys.lastVolume) }
    }
    
    // MARK: - Timer Settings
    var timerFadeOutDuration: TimeInterval {
        get { userDefaults.double(forKey: Keys.timerFadeOutDuration) }
        set { userDefaults.set(newValue, forKey: Keys.timerFadeOutDuration) }
    }
    
    var defaultTimerDuration: TimeInterval {
        get { userDefaults.double(forKey: Keys.defaultTimerDuration) }
        set { userDefaults.set(newValue, forKey: Keys.defaultTimerDuration) }
    }
    
    var lastTimerDuration: TimeInterval {
        get { 
            let value = userDefaults.double(forKey: Keys.lastTimerDuration)
            return value > 0 ? value : Defaults.lastTimerDuration
        }
        set { 
            userDefaults.set(newValue, forKey: Keys.lastTimerDuration)
        }
    }
    
    // MARK: - Premium Features
    var isPremiumUser: Bool {
        get { userDefaults.bool(forKey: Keys.isPremiumUser) }
        set { 
            userDefaults.set(newValue, forKey: Keys.isPremiumUser)
            objectWillChange.send()
        }
    }
    
    var isMultipleSoundsEnabled: Bool {
        get { userDefaults.bool(forKey: Keys.isMultipleSoundsEnabled) }
        set { 
            userDefaults.set(newValue, forKey: Keys.isMultipleSoundsEnabled)
            objectWillChange.send()
        }
    }
    
    var isMultipleBackgroundsEnabled: Bool {
        get { userDefaults.bool(forKey: Keys.isMultipleBackgroundsEnabled) }
        set { 
            userDefaults.set(newValue, forKey: Keys.isMultipleBackgroundsEnabled)
            objectWillChange.send()
        }
    }
    
    // MARK: - App State
    var appLaunchCount: Int {
        get { userDefaults.integer(forKey: Keys.appLaunchCount) }
        set { userDefaults.set(newValue, forKey: Keys.appLaunchCount) }
    }
    
    var lastAppVersion: String? {
        get { userDefaults.string(forKey: Keys.lastAppVersion) }
        set { userDefaults.set(newValue, forKey: Keys.lastAppVersion) }
    }
    
    var hasCompletedOnboarding: Bool {
        get { userDefaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { userDefaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }
    
    // MARK: - Content Preferences
    var selectedSoundID: String? {
        get { userDefaults.string(forKey: Keys.selectedSoundID) }
        set { userDefaults.set(newValue, forKey: Keys.selectedSoundID) }
    }
    
    var selectedBackgroundID: String? {
        get { userDefaults.string(forKey: Keys.selectedBackgroundID) }
        set { userDefaults.set(newValue, forKey: Keys.selectedBackgroundID) }
    }
    
    var backgroundImageQuality: Int {
        get { userDefaults.integer(forKey: Keys.backgroundImageQuality) }
        set { userDefaults.set(newValue, forKey: Keys.backgroundImageQuality) }
    }
    
    // MARK: - Privacy Settings
    var isAnalyticsEnabled: Bool {
        get { userDefaults.bool(forKey: Keys.isAnalyticsEnabled) }
        set { 
            userDefaults.set(newValue, forKey: Keys.isAnalyticsEnabled)
            updateAnalyticsConsent()
        }
    }
    
    // MARK: - Database Version
    var lastDatabaseVersion: Int {
        get { userDefaults.integer(forKey: Keys.lastDatabaseVersion) }
        set { userDefaults.set(newValue, forKey: Keys.lastDatabaseVersion) }
    }
    
    // MARK: - Brightness Settings
    var isAutoBrightnessEnabled: Bool {
        get { userDefaults.bool(forKey: Keys.isAutoBrightnessEnabled) }
        set { 
            userDefaults.set(newValue, forKey: Keys.isAutoBrightnessEnabled)
            objectWillChange.send()
        }
    }
    
    var lastBrightnessLevel: Double {
        get { 
            let value = userDefaults.double(forKey: Keys.lastBrightnessLevel)
            return value > 0 ? value : Defaults.lastBrightnessLevel
        }
        set { 
            userDefaults.set(newValue, forKey: Keys.lastBrightnessLevel)
            objectWillChange.send()
        }
    }
    
    var sleepModeBrightnessLevel: Double {
        get { 
            // Check if the key exists first
            if userDefaults.object(forKey: Keys.sleepModeBrightnessLevel) != nil {
                let value = userDefaults.double(forKey: Keys.sleepModeBrightnessLevel)
                // Allow values >= 0.01 (minimum brightness), use default if somehow 0
                return value >= 0.01 ? value : Defaults.sleepModeBrightnessLevel
            } else {
                // Key doesn't exist, return default
                return Defaults.sleepModeBrightnessLevel
            }
        }
        set { 
            userDefaults.set(newValue, forKey: Keys.sleepModeBrightnessLevel)
            objectWillChange.send()
        }
    }
    
    // MARK: - Initialization
    init() {
        // Load current values or set defaults
        self.isHapticsEnabled = userDefaults.object(forKey: Keys.isHapticsEnabled) as? Bool ?? Defaults.isHapticsEnabled
        self.isAutoLockDisabled = userDefaults.object(forKey: Keys.isAutoLockDisabled) as? Bool ?? Defaults.isAutoLockDisabled
        
        // Set defaults if not already set
        registerDefaults()
        
        // Handle app launch
        handleAppLaunch()
        
        // Apply current settings
        updateHapticFeedback()
        updateAutoLockSetting()
        updateAnalyticsConsent()
    }
    
    // MARK: - Default Registration
    private func registerDefaults() {
        let defaults: [String: Any] = [
            Keys.isHapticsEnabled: Defaults.isHapticsEnabled,
            Keys.isAutoLockDisabled: Defaults.isAutoLockDisabled,
            Keys.masterVolume: Defaults.masterVolume,
            Keys.lastVolume: Defaults.lastVolume,
            Keys.timerFadeOutDuration: Defaults.timerFadeOutDuration,
            Keys.defaultTimerDuration: Defaults.defaultTimerDuration,
            Keys.lastTimerDuration: Defaults.lastTimerDuration,
            Keys.isPremiumUser: Defaults.isPremiumUser,
            Keys.isMultipleSoundsEnabled: Defaults.isMultipleSoundsEnabled,
            Keys.isMultipleBackgroundsEnabled: Defaults.isMultipleBackgroundsEnabled,
            Keys.appLaunchCount: Defaults.appLaunchCount,
            Keys.hasCompletedOnboarding: Defaults.hasCompletedOnboarding,
            Keys.backgroundImageQuality: Defaults.backgroundImageQuality,
            Keys.isAnalyticsEnabled: Defaults.isAnalyticsEnabled,
            Keys.lastDatabaseVersion: Defaults.lastDatabaseVersion,
            Keys.isAutoBrightnessEnabled: Defaults.isAutoBrightnessEnabled,
            Keys.lastBrightnessLevel: Defaults.lastBrightnessLevel,
            Keys.sleepModeBrightnessLevel: Defaults.sleepModeBrightnessLevel
        ]
        
        userDefaults.register(defaults: defaults)
    }
    
    // MARK: - App Launch Handling
    private func handleAppLaunch() {
        let currentAppLaunchCount = appLaunchCount
        let isFirstLaunch = currentAppLaunchCount == 0
        appLaunchCount += 1
        
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let previousVersion = lastAppVersion
        
        if isFirstLaunch {
            // First launch - explicitly set default timer duration
            lastTimerDuration = Defaults.lastTimerDuration
        }
        
        if previousVersion != currentVersion {
            handleVersionUpdate(from: previousVersion, to: currentVersion)
            lastAppVersion = currentVersion
        }
    }
    
    private func handleVersionUpdate(from previousVersion: String?, to currentVersion: String?) {
        // Handle version-specific migrations
        if previousVersion == nil {
            // First launch - ensure default timer duration is set
            if userDefaults.object(forKey: Keys.lastTimerDuration) == nil {
                lastTimerDuration = Defaults.lastTimerDuration
            }
        } else if let _ = previousVersion, let _ = currentVersion {
            // Perform any version-specific migrations here
        }
    }
    
    // MARK: - Settings Application
    private func updateHapticFeedback() {
        // Enable or disable haptic feedback system-wide
        // This would be implemented in the UI components that use haptics
    }
    
    private func updateAutoLockSetting() {
        // This will be applied when the app enters sleep mode
        // The actual implementation is in the AudioManager/MainViewModel
    }
    
    private func updateAnalyticsConsent() {
        // Enable or disable analytics based on user preference
        // This would integrate with analytics SDKs like Flurry
    }
    
    // MARK: - Utility Methods
    func resetToDefaults() {
        let keysToRemove = [
            Keys.isHapticsEnabled,
            Keys.isAutoLockDisabled,
            Keys.masterVolume,
            Keys.lastVolume,
            Keys.timerFadeOutDuration,
            Keys.defaultTimerDuration,
            Keys.lastTimerDuration,
            Keys.backgroundImageQuality,
            Keys.selectedSoundID,
            Keys.selectedBackgroundID
        ]
        
        keysToRemove.forEach { userDefaults.removeObject(forKey: $0) }
        
        // Reload default values
        isHapticsEnabled = Defaults.isHapticsEnabled
        isAutoLockDisabled = Defaults.isAutoLockDisabled
        
        objectWillChange.send()
    }
    
    func exportSettings() -> [String: Any] {
        return [
            "isHapticsEnabled": isHapticsEnabled,
            "isAutoLockDisabled": isAutoLockDisabled,
            "masterVolume": masterVolume,
            "timerFadeOutDuration": timerFadeOutDuration,
            "defaultTimerDuration": defaultTimerDuration,
            "backgroundImageQuality": backgroundImageQuality,
            "isAnalyticsEnabled": isAnalyticsEnabled
        ]
    }
    
    func importSettings(_ settings: [String: Any]) {
        if let haptics = settings["isHapticsEnabled"] as? Bool {
            isHapticsEnabled = haptics
        }
        if let autoLock = settings["isAutoLockDisabled"] as? Bool {
            isAutoLockDisabled = autoLock
        }
        if let volume = settings["masterVolume"] as? Float {
            masterVolume = volume
        }
        if let fadeOut = settings["timerFadeOutDuration"] as? TimeInterval {
            timerFadeOutDuration = fadeOut
        }
        if let timerDefault = settings["defaultTimerDuration"] as? TimeInterval {
            defaultTimerDuration = timerDefault
        }
        if let imageQuality = settings["backgroundImageQuality"] as? Int {
            backgroundImageQuality = imageQuality
        }
        if let analytics = settings["isAnalyticsEnabled"] as? Bool {
            isAnalyticsEnabled = analytics
        }
    }
    
    // MARK: - Validation
    func validateTimerDuration(_ duration: TimeInterval) -> Bool {
        return duration >= 60 && duration <= 28800 // 1 minute to 8 hours
    }
    
    func validateVolume(_ volume: Float) -> Bool {
        return volume >= 0.0 && volume <= 1.0
    }
    
    func validateFadeOutDuration(_ duration: TimeInterval) -> Bool {
        return duration >= 1.0 && duration <= 300.0 // 1 second to 5 minutes
    }
    
    // MARK: - Feature Flags
    func isFeatureEnabled(_ feature: String) -> Bool {
        switch feature {
        case "multipleSounds":
            return isPremiumUser && isMultipleSoundsEnabled
        case "multipleBackgrounds":
            return isPremiumUser && isMultipleBackgroundsEnabled
        case "advancedTimer":
            return isPremiumUser
        case "customBackgrounds":
            return isPremiumUser
        default:
            return false
        }
    }
    
    // MARK: - Debug Helpers
    func printAllSettings() {
        print("=== Settings Manager State ===")
        print("Haptics: \(isHapticsEnabled)")
        print("Auto-Lock Disabled: \(isAutoLockDisabled)")
        print("Master Volume: \(masterVolume)")
        print("Timer Duration: \(defaultTimerDuration)")
        print("Fade Out Duration: \(timerFadeOutDuration)")
        print("Premium User: \(isPremiumUser)")
        print("App Launch Count: \(appLaunchCount)")
        print("===============================")
    }
}