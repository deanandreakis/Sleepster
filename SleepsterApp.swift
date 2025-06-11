//
//  SleepsterApp.swift
//  SleepMate
//
//  Created by Claude on Phase 2 Migration
//

import SwiftUI

@main
struct SleepsterApp: App {
    // Dependency injection container
    @StateObject private var serviceContainer = ServiceContainer()
    
    // App state management
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(serviceContainer)
                .environmentObject(appState)
                .environmentObject(serviceContainer.coreDataStack)
                .environmentObject(serviceContainer.audioManager)
                .environmentObject(serviceContainer.timerManager)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Initialize database if needed
        Task {
            await serviceContainer.databaseManager.prePopulate()
        }
        
        // Setup audio session
        serviceContainer.audioManager.setupAudioSession()
        
        // Handle app shortcuts (3D Touch)
        handleShortcutItems()
    }
    
    private func handleShortcutItems() {
        // Handle the "Sleep NOW!" shortcut from Info.plist
        if let shortcutItem = appState.launchedShortcutItem {
            if shortcutItem.type == "com.deanware.sleepster.newmessage" {
                appState.shouldStartSleepingImmediately = true
            }
        }
    }
}

// MARK: - Content View (Main Entry Point)
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var serviceContainer: ServiceContainer
    
    var body: some View {
        SleepsterTabView()
            .preferredColorScheme(appState.colorScheme)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Handle app becoming active
                serviceContainer.audioManager.handleAppBecameActive()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                // Handle app going to background
                serviceContainer.audioManager.handleAppWillResignActive()
            }
    }
}