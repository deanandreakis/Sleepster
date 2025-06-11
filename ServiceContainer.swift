//
//  ServiceContainer.swift
//  SleepMate
//
//  Created by Claude on Phase 2 Migration
//

import Foundation
import SwiftUI

@MainActor
class ServiceContainer: ObservableObject {
    
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
    
    lazy var flickrAPIClient: FlickrAPIClient = {
        FlickrAPIClient.shared
    }()
    
    lazy var settingsManager: SettingsManager = {
        SettingsManager()
    }()
    
    // MARK: - ViewModels
    lazy var mainViewModel: MainViewModel = {
        MainViewModel(
            audioManager: audioManager,
            timerManager: timerManager,
            databaseManager: databaseManager,
            settingsManager: settingsManager
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
    }
    
    private func handleAppWillTerminate() {
        // Final cleanup
        databaseManager.saveContext()
        audioManager.stopAllSounds()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}