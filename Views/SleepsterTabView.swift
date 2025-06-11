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
            MainSleepView()
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
            BackgroundsListView()
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

// MARK: - Placeholder Views (Will be implemented in Phase 3)
struct MainSleepView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Sleep Interface")
                    .font(.largeTitle)
                    .padding()
                
                Text("Main sleep controls will be implemented in Phase 3")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
                
                // Test button for now
                Button("Start Sleep Mode") {
                    appState.startSleeping()
                }
                .buttonStyle(.borderedProminent)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Sleepster")
            .background(appState.currentBackgroundColor)
        }
    }
}

struct SoundsListView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Sounds")
                    .font(.largeTitle)
                    .padding()
                
                Text("Nature sounds selection will be implemented in Phase 3")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Sounds")
        }
    }
}

struct BackgroundsListView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Backgrounds")
                    .font(.largeTitle)
                    .padding()
                
                Text("Background selection will be implemented in Phase 3")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Backgrounds")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            Form {
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $appState.isDarkModeEnabled)
                }
                
                Section("Audio") {
                    HStack {
                        Text("Volume")
                        Slider(value: $appState.currentVolume, in: 0...1)
                            .onChange(of: appState.currentVolume) { volume in
                                appState.updateVolume(volume)
                            }
                    }
                    
                    Toggle("Mute", isOn: $appState.isMuted)
                }
                
                Section("General") {
                    Toggle("Haptic Feedback", isOn: $appState.isHapticsEnabled)
                    Toggle("Disable Auto-Lock", isOn: $appState.isAutoLockDisabled)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("2.5")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct InformationView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Information")
                    .font(.largeTitle)
                    .padding()
                
                Text("App information and help will be implemented in Phase 3")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Information")
        }
    }
}

#Preview {
    SleepsterTabView()
        .environmentObject(AppState())
        .environmentObject(ServiceContainer())
}