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
    @EnvironmentObject var coreDataStack: CoreDataStack
    
    var body: some View {
        TabView {
            SleepView()
                .tabItem {
                    Image(systemName: "moon.fill")
                    Text("Main")
                }
            
            SoundsListView()
                .tabItem {
                    Image(systemName: "speaker.wave.3.fill")
                    Text("Sounds")
                }
            
            BackgroundsView()
                .tabItem {
                    Image(systemName: "photo.fill")
                    Text("Backgrounds")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
            
            InformationView()
                .tabItem {
                    Image(systemName: "info.circle.fill")
                    Text("Info")
                }
        }
    }
}

// MARK: - Loading Tab View
struct LoadingTabView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text(message)
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// Note: Individual view files are now implemented separately

#Preview {
    SleepsterTabView()
        .environmentObject(AppState())
        .environmentObject(ServiceContainer())
}