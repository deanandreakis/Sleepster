//
//  BrightnessManager.swift
//  SleepMate
//
//  Created by Claude on Phase 2 Migration
//

import Foundation
import SwiftUI

@MainActor
class BrightnessManager: ObservableObject {
    
    // MARK: - Properties
    private let settingsManager: SettingsManager
    private var originalBrightness: Double = 0.5
    private var isSleepModeActive = false
    private var shouldRestoreOnTouch = false
    
    // MARK: - Published Properties
    @Published var currentBrightness: Double = 0.5
    
    // MARK: - Initialization
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        self.currentBrightness = UIScreen.main.brightness
        
        // Load saved brightness level on initialization
        if settingsManager.lastBrightnessLevel > 0 {
            setBrightness(settingsManager.lastBrightnessLevel, animated: false)
        }
    }
    
    // MARK: - Public Methods
    
    /// Sets the screen brightness to the specified level
    /// - Parameters:
    ///   - level: Brightness level (0.01 to 1.0)
    ///   - animated: Whether to animate the transition
    ///   - duration: Animation duration (default: 0.5 seconds)
    func setBrightness(_ level: Double, animated: Bool = true, duration: TimeInterval = 0.5) {
        let clampedLevel = max(0.01, min(1.0, level))
        
        if animated {
            withAnimation(.easeInOut(duration: duration)) {
                UIScreen.main.brightness = clampedLevel
                currentBrightness = clampedLevel
            }
        } else {
            UIScreen.main.brightness = clampedLevel
            currentBrightness = clampedLevel
        }
        
        // Save the brightness level unless we're in sleep mode
        if !isSleepModeActive {
            settingsManager.lastBrightnessLevel = clampedLevel
        }
    }
    
    /// Dims the screen for sleep mode if auto-brightness is enabled
    func dimForSleep() {
        print("🔆 BrightnessManager.dimForSleep() called")
        print("🔆 Auto-brightness enabled: \(settingsManager.isAutoBrightnessEnabled)")
        print("🔆 Sleep mode active: \(isSleepModeActive)")
        print("🔆 Current brightness: \(UIScreen.main.brightness)")
        print("🔆 Target brightness: \(settingsManager.sleepModeBrightnessLevel)")
        
        guard settingsManager.isAutoBrightnessEnabled else { 
            print("🔆 Auto-brightness is disabled, skipping dim")
            return 
        }
        guard !isSleepModeActive else { 
            print("🔆 Sleep mode already active, skipping dim")
            return 
        }
        
        // Store current brightness to restore later
        originalBrightness = UIScreen.main.brightness
        isSleepModeActive = true
        
        // Add detailed debugging for brightness setting retrieval
        let storedValue = UserDefaults.standard.double(forKey: "sleepModeBrightnessLevel")
        let settingsValue = settingsManager.sleepModeBrightnessLevel
        print("🔆 Stored UserDefaults value: \(storedValue)")
        print("🔆 SettingsManager value: \(settingsValue)")
        
        let targetBrightness = settingsManager.sleepModeBrightnessLevel
        
        print("🔆 Setting brightness from \(originalBrightness) to \(targetBrightness)")
        
        withAnimation(.easeInOut(duration: 2.0)) {
            UIScreen.main.brightness = targetBrightness
            currentBrightness = targetBrightness
        }
        
        print("BrightnessManager: Dimmed for sleep mode (\(Int(targetBrightness * 100))%)")
    }
    
    /// Restores the original brightness when sleep mode ends
    func restoreFromSleep() {
        print("🔆 BrightnessManager.restoreFromSleep() called")
        print("🔆 Auto-brightness enabled: \(settingsManager.isAutoBrightnessEnabled)")
        print("🔆 Sleep mode active: \(isSleepModeActive)")
        print("🔆 Original brightness: \(originalBrightness)")
        
        guard settingsManager.isAutoBrightnessEnabled else { 
            print("🔆 Auto-brightness is disabled, skipping restore")
            return 
        }
        guard isSleepModeActive else { 
            print("🔆 Sleep mode not active, skipping restore")
            return 
        }
        
        isSleepModeActive = false
        shouldRestoreOnTouch = false
        
        print("🔆 Restoring brightness from \(UIScreen.main.brightness) to \(originalBrightness)")
        
        withAnimation(.easeInOut(duration: 1.0)) {
            UIScreen.main.brightness = originalBrightness
            currentBrightness = originalBrightness
        }
        
        // Update saved brightness level to the restored value
        settingsManager.lastBrightnessLevel = originalBrightness
        
        print("BrightnessManager: Restored brightness from sleep mode (\(Int(originalBrightness * 100))%)")
    }
    
    /// Sets flag to restore brightness on next user touch (used when timer expires)
    func scheduleRestoreOnTouch() {
        print("🔆 BrightnessManager.scheduleRestoreOnTouch() called")
        print("🔆 Auto-brightness enabled: \(settingsManager.isAutoBrightnessEnabled)")
        print("🔆 Sleep mode active: \(isSleepModeActive)")
        
        guard settingsManager.isAutoBrightnessEnabled && isSleepModeActive else {
            print("🔆 Conditions not met for restore on touch, exiting sleep mode normally")
            isSleepModeActive = false
            return
        }
        
        shouldRestoreOnTouch = true
        print("🔆 Brightness restoration scheduled for next user touch")
    }
    
    /// Restores brightness if restoration is pending (called on user touch)
    func restoreOnTouchIfNeeded() {
        guard shouldRestoreOnTouch else { return }
        
        print("🔆 BrightnessManager.restoreOnTouchIfNeeded() - restoring brightness on user touch")
        
        shouldRestoreOnTouch = false
        isSleepModeActive = false
        
        withAnimation(.easeInOut(duration: 1.0)) {
            UIScreen.main.brightness = originalBrightness
            currentBrightness = originalBrightness
        }
        
        // Update saved brightness level to the restored value
        settingsManager.lastBrightnessLevel = originalBrightness
        
        print("BrightnessManager: Restored brightness on user touch (\(Int(originalBrightness * 100))%)")
    }
    
    /// Forces an immediate stop of any brightness animations and restores to last known good state
    func forceRestore() {
        isSleepModeActive = false
        let targetBrightness = settingsManager.lastBrightnessLevel
        
        UIScreen.main.brightness = targetBrightness
        currentBrightness = targetBrightness
        
        print("BrightnessManager: Force restored to \(Int(targetBrightness * 100))%")
    }
    
    // MARK: - Preset Methods
    
    /// Sets brightness to dim level (10%)
    func setDim() {
        setBrightness(0.1)
    }
    
    /// Sets brightness to low level (30%)
    func setLow() {
        setBrightness(0.3)
    }
    
    /// Sets brightness to medium level (60%)
    func setMedium() {
        setBrightness(0.6)
    }
    
    /// Sets brightness to bright level (100%)
    func setBright() {
        setBrightness(1.0)
    }
    
    // MARK: - Utility Methods
    
    /// Returns the current brightness as a percentage string
    var brightnessPercentage: String {
        return "\(Int(currentBrightness * 100))%"
    }
    
    /// Returns whether auto-brightness is currently enabled
    var isAutoBrightnessEnabled: Bool {
        return settingsManager.isAutoBrightnessEnabled
    }
    
    /// Returns whether sleep mode is currently active
    var isSleepMode: Bool {
        return isSleepModeActive
    }
    
    /// Returns whether brightness restoration is pending user touch
    var isPendingRestoreOnTouch: Bool {
        return shouldRestoreOnTouch
    }
    
    /// Updates the sleep mode brightness level
    func setSleepModeBrightness(_ level: Double) {
        let clampedLevel = max(0.01, min(1.0, level))
        settingsManager.sleepModeBrightnessLevel = clampedLevel
    }
    
    /// Toggles auto-brightness on/off
    func toggleAutoBrightness() {
        settingsManager.isAutoBrightnessEnabled.toggle()
    }
}