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
    
    // MARK: - Phase 4 Modern Services
    lazy var networkMonitor: NetworkMonitor = {
        NetworkMonitor.shared
    }()
    
    lazy var flickrService: FlickrService = {
        FlickrService.shared
    }()
    
    lazy var imageCache: ImageCache = {
        ImageCache.shared
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
    
    // MARK: - Legacy Services (for backward compatibility)
    lazy var flickrAPIClient: FlickrAPIClient = {
        FlickrAPIClient.shared
    }()
    
    lazy var settingsManager: SettingsManager = {
        SettingsManager()
    }()
    
    // MARK: - ViewModels
    lazy var mainViewModel: MainViewModel = {
        // Ensure SettingsManager is fully initialized before creating ViewModels
        let settings = settingsManager
        
        return MainViewModel(
            audioManager: audioManager,
            timerManager: timerManager,
            databaseManager: databaseManager,
            settingsManager: settings,
            audioMixingEngine: audioMixingEngine
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
            databaseManager: databaseManager,
            flickrAPIClient: flickrAPIClient
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
            self?.handleAppDidEnterBackground()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppWillTerminate()
        }
    }
    
    private func handleAppDidEnterBackground() {
        // Save any pending data
        databaseManager.saveContext()
        
        // Handle audio session for background playback
        audioSessionManager.handleAppDidEnterBackground()
    }
    
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