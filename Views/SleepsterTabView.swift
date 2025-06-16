//
//  SleepsterTabView.swift
//  SleepMate
//
//  Created by Claude on Phase 2 Migration
//

import SwiftUI

struct SleepsterTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var serviceContainer: ServiceContainer
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            // Main Sleep Tab
            SleepView()
                .tabItem {
                    Image(systemName: TabItem.main.systemImage)
                    Text(TabItem.main.title)
                }
                .tag(TabItem.main)
            
            // Sounds Tab
            SoundsListView()
                .tabItem {
                    Image(systemName: TabItem.sounds.systemImage)
                    Text(TabItem.sounds.title)
                }
                .tag(TabItem.sounds)
            
            // Backgrounds Tab
            BackgroundsView()
                .tabItem {
                    Image(systemName: TabItem.backgrounds.systemImage)
                    Text(TabItem.backgrounds.title)
                }
                .tag(TabItem.backgrounds)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: TabItem.settings.systemImage)
                    Text(TabItem.settings.title)
                }
                .tag(TabItem.settings)
            
            // Information Tab
            InformationView()
                .tabItem {
                    Image(systemName: TabItem.information.systemImage)
                    Text(TabItem.information.title)
                }
                .tag(TabItem.information)
        }
        .accentColor(.primary)
        .onAppear {
            setupTabBarAppearance()
        }
        .onChange(of: appState.shouldStartSleepingImmediately) { shouldStart in
            if shouldStart {
                appState.selectedTab = .main
                appState.startSleeping()
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded { _ in
                // Check if brightness restoration is pending and restore if needed
                SharedViewModelStore.shared.mainViewModel.brightnessManager.restoreOnTouchIfNeeded()
            }
        )
    }
    
    private func setupTabBarAppearance() {
        // Customize tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // Set the appearance for different states
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// Note: Individual view files are now implemented separately

#Preview {
    SleepsterTabView()
        .environmentObject(AppState())
        .environmentObject(ServiceContainer())
}