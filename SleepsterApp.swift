//
//  SleepsterApp.swift
//  SleepMate
//
//  Created by Claude on SwiftUI Migration
//  Complete SwiftUI app with all functionality from legacy app delegate
//

import SwiftUI
import UIKit

@main
struct SleepsterApp: App {
    // Dependency injection container
    @StateObject private var serviceContainer = ServiceContainer()
    
    // App state management
    @StateObject private var appState = AppState()
    
    // App delegate for UIKit integration
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(serviceContainer)
                .environmentObject(appState)
                .environmentObject(serviceContainer.coreDataStack)
                .environmentObject(serviceContainer.audioManager)
                .environmentObject(serviceContainer.timerManager)
                .environmentObject(serviceContainer.settingsManager)
                .environmentObject(serviceContainer.brightnessManager)
                .onAppear {
                    setupApp()
                }
                .onReceive(NotificationCenter.default.publisher(for: .shortcutItemReceived)) { notification in
                    if let shortcutType = notification.object as? String {
                        handleShortcutItem(type: shortcutType)
                    }
                }
        }
    }
    
    private func setupApp() {
        NSLog("📱 SleepsterApp: setupApp() called")
        // Pass dependencies to app delegate
        appDelegate.serviceContainer = serviceContainer
        appDelegate.appState = appState
        
        // Initialize Core Data and heavy operations asynchronously
        Task {
            NSLog("📱 SleepsterApp: Starting async initialization task")
            // Initialize Core Data stack first
            await serviceContainer.coreDataStack.initializeAsync()
            NSLog("📱 SleepsterApp: Core Data initialization complete")
            
            // Initialize color scheme from settings (after Core Data is ready)
            await MainActor.run {
                appState.updateColorScheme(isDarkMode: serviceContainer.settingsManager.isDarkModeEnabled)
                NSLog("📱 SleepsterApp: Color scheme initialized")
            }
            
            // Initialize database population in background (non-blocking)
            Task.detached(priority: .background) {
                await serviceContainer.databaseManager.prePopulate()
            }
            
            // Setup audio session in background
            Task.detached(priority: .utility) {
                await serviceContainer.audioManager.setupAudioSession()
            }
        }
    }
    
    private func handleShortcutItem(type: String) {
        if type == "com.deanware.sleepster.newmessage" {
            appState.shouldStartSleepingImmediately = true
        }
    }
}

// MARK: - UIApplicationDelegate for SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    var serviceContainer: ServiceContainer?
    var appState: AppState?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize StoreKit helper
        _ = StoreKitManager.shared
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Save Core Data context
        serviceContainer?.coreDataStack.save()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Re-populate database if needed
        Task {
            await serviceContainer?.databaseManager.prePopulate()
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Save Core Data context before termination
        serviceContainer?.coreDataStack.save()
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        NotificationCenter.default.post(
            name: .shortcutItemReceived, 
            object: shortcutItem.type
        )
        completionHandler(true)
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // Default to portrait orientation, allow landscape for specific views if needed
        return .portrait
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let shortcutItemReceived = Notification.Name("shortcutItemReceived")
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