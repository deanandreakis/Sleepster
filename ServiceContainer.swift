//
//  ServiceContainer.swift
//  SleepMate
//
//  Created by Claude on Phase 2 Migration
//

import Foundation
import SwiftUI

// MARK: - Shared ViewModel Store
@MainActor
class SharedViewModelStore: ObservableObject {
    static let shared = SharedViewModelStore()
    
    private let serviceContainer = ServiceContainer.shared
    
    lazy var mainViewModel: MainViewModel = {
        serviceContainer.mainViewModel
    }()
    
    lazy var soundsViewModel: SoundsViewModel = {
        serviceContainer.soundsViewModel
    }()
    
    private init() {}
}

@MainActor
class ServiceContainer: ObservableObject {
    static let shared = ServiceContainer()
    
    // MARK: - Core Services
    lazy var coreDataStack: CoreDataStack = {
        CoreDataStack.shared
    }()
    
    lazy var databaseManager: DatabaseManager = {
        DatabaseManager.shared
    }()
    
    lazy var audioManager: AudioManager = {
        AudioManager(coreDataStack: coreDataStack)
    }()
    
    lazy var timerManager: TimerManager = {
        TimerManager(audioManager: audioManager)
    }()
    
    // MARK: - Animation Services (Phase 1)
    lazy var animationPerformanceMonitor: AnimationPerformanceMonitor = {
        AnimationPerformanceMonitor()
    }()
    
    lazy var errorHandler: ErrorHandler = {
        ErrorHandler.shared
    }()
    
    lazy var audioSessionManager: AudioSessionManager = {
        AudioSessionManager.shared
    }()
    
    lazy var audioMixingEngine: AudioMixingEngine = {
        AudioMixingEngine.shared
    }()
    
    lazy var audioEqualizer: AudioEqualizer = {
        AudioEqualizer.shared
    }()
    
    lazy var audioEffectsProcessor: AudioEffectsProcessor = {
        AudioEffectsProcessor.shared
    }()
    
    // MARK: - Animation Services
    lazy var animationRegistry: AnimationRegistry = {
        AnimationRegistry.shared
    }()
    
    lazy var settingsManager: SettingsManager = {
        SettingsManager()
    }()
    
    lazy var brightnessManager: BrightnessManager = {
        BrightnessManager(settingsManager: settingsManager)
    }()
    
    // MARK: - ViewModels
    lazy var mainViewModel: MainViewModel = {
        // Ensure SettingsManager is fully initialized before creating ViewModels
        let settings = settingsManager
        let brightness = brightnessManager
        
        return MainViewModel(
            audioManager: audioManager,
            timerManager: timerManager,
            databaseManager: databaseManager,
            settingsManager: settings,
            audioMixingEngine: audioMixingEngine,
            brightnessManager: brightness
        )
    }()
    
    lazy var soundsViewModel: SoundsViewModel = {
        SoundsViewModel(
            databaseManager: databaseManager,
            audioManager: audioManager
        )
    }()
    
    lazy var backgroundsViewModel: BackgroundsViewModel = {
        BackgroundsViewModel(
            databaseManager: databaseManager
        )
    }()
    
    lazy var settingsViewModel: SettingsViewModel = {
        SettingsViewModel(
            settingsManager: settingsManager,
            databaseManager: databaseManager
        )
    }()
    
    lazy var timerViewModel: TimerViewModel = {
        TimerViewModel(
            timerManager: timerManager,
            settingsManager: settingsManager
        )
    }()
    
    lazy var informationViewModel: InformationViewModel = {
        InformationViewModel()
    }()
    
    // MARK: - Initialization
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        // Setup any app-wide notification observers
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAppDidEnterBackground()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAppWillTerminate()
            }
        }
    }
    
    @MainActor
    private func handleAppDidEnterBackground() {
        // Save any pending data
        databaseManager.saveContext()
        
        // Handle audio session for background playbook
        audioSessionManager.handleAppDidEnterBackground()
    }
    
    @MainActor
    private func handleAppWillTerminate() {
        // Final cleanup
        databaseManager.saveContext()
        audioManager.stopAllSounds()
        
        // Cleanup audio resources
        Task {
            await audioMixingEngine.stopAllSounds()
            await audioSessionManager.deactivateSession()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}