//
//  AppState.swift
//  SleepMate
//
//  Created by Claude on Phase 2 Migration
//

import Foundation
import SwiftUI
import UIKit

@MainActor
class AppState: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AppState()
    
    // MARK: - UI State
    @Published var selectedTab: TabItem = .main
    @Published var colorScheme: ColorScheme? = nil
    @Published var isSettingsPresented = false
    @Published var isTimerPresented = false
    @Published var isInformationPresented = false
    
    // MARK: - App Lifecycle State
    @Published var isAppActive = true
    @Published var isInBackground = false
    
    // MARK: - Sleep State
    @Published var isSleeping = false
    @Published var shouldStartSleepingImmediately = false
    
    // MARK: - Audio State
    @Published var currentVolume: Float = 0.5
    @Published var isMuted = false
    
    // MARK: - Timer State
    @Published var timerDuration: TimeInterval = 0
    @Published var isTimerRunning = false
    @Published var timeRemaining: TimeInterval = 0
    
    // MARK: - Animation State
    @Published var selectedAnimation: AnimatedBackground?
    @Published var animationIntensity: Float = 0.5
    @Published var animationSpeed: Float = 1.0
    @Published var animationColorTheme: ColorTheme = .defaultTheme
    @Published var isDimmed = false
    
    // MARK: - Alert State
    @Published var alertItem: AlertItem?
    
    // MARK: - Loading State
    @Published var isLoading = false
    @Published var loadingMessage = ""
    
    // MARK: - Shortcut Handling
    var launchedShortcutItem: UIApplicationShortcutItem?
    
    // MARK: - Navigation State
    @Published var navigationPath: [String] = [] // iOS 15.0 compatible navigation
    
    // MARK: - Settings State
    @Published var isHapticsEnabled = true
    @Published var isAutoLockDisabled = true
    
    init() {
        loadUserPreferences()
        setupNotifications()
    }
    
    // MARK: - User Preferences
    private func loadUserPreferences() {
        // Load saved preferences
        isHapticsEnabled = UserDefaults.standard.bool(forKey: "isHapticsEnabled")
        isAutoLockDisabled = UserDefaults.standard.bool(forKey: "isAutoLockDisabled")
        currentVolume = UserDefaults.standard.float(forKey: "lastVolume")
    }
    
    func updateColorScheme(isDarkMode: Bool) {
        colorScheme = isDarkMode ? .dark : .light
    }
    
    // MARK: - Notifications Setup
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isAppActive = true
                self?.isInBackground = false
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isAppActive = false
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isInBackground = true
            }
        }
    }
    
    // MARK: - Action Methods
    func startSleeping() {
        isSleeping = true
        shouldStartSleepingImmediately = false
    }
    
    func stopSleeping() {
        isSleeping = false
        isTimerRunning = false
    }
    
    func showAlert(_ alert: AlertItem) {
        alertItem = alert
    }
    
    func showLoading(_ message: String = "Loading...") {
        isLoading = true
        loadingMessage = message
    }
    
    func hideLoading() {
        isLoading = false
        loadingMessage = ""
    }
    
    func selectTab(_ tab: TabItem) {
        selectedTab = tab
    }
    
    func updateVolume(_ volume: Float) {
        currentVolume = volume
        UserDefaults.standard.set(volume, forKey: "lastVolume")
    }
    
    func toggleMute() {
        isMuted.toggle()
    }
    
    func updateTimerState(duration: TimeInterval, remaining: TimeInterval, isRunning: Bool) {
        timerDuration = duration
        timeRemaining = remaining
        isTimerRunning = isRunning
    }
    
    func setAnimation(_ animation: AnimatedBackground?) {
        Task { @MainActor in
            selectedAnimation = animation
        }
    }
    
    func updateAnimationSettings(intensity: Float, speed: Float, colorTheme: ColorTheme) {
        Task { @MainActor in
            animationIntensity = intensity
            animationSpeed = speed
            animationColorTheme = colorTheme
        }
    }
    
    func setDimmedMode(_ dimmed: Bool) {
        isDimmed = dimmed
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Supporting Types
enum TabItem: String, CaseIterable {
    case main = "Main"
    case sounds = "Sounds"
    case backgrounds = "Backgrounds"
    case settings = "Settings"
    case information = "Information"
    
    var systemImage: String {
        switch self {
        case .main: return "moon.fill"
        case .sounds: return "speaker.wave.3.fill"
        case .backgrounds: return "photo.fill"
        case .settings: return "gearshape.fill"
        case .information: return "info.circle.fill"
        }
    }
    
    var title: String {
        return rawValue
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let dismissButton: Alert.Button
    
    static func error(_ message: String) -> AlertItem {
        AlertItem(
            title: "Error",
            message: message,
            dismissButton: .default(Text("OK"))
        )
    }
    
    static func info(_ title: String, message: String) -> AlertItem {
        AlertItem(
            title: title,
            message: message,
            dismissButton: .default(Text("OK"))
        )
    }
}