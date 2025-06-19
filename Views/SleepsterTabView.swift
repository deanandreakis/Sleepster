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
    @StateObject private var mainViewModel = ServiceContainer.shared.mainViewModel
    @State private var selectedTab = 0
    
    private let tabs = [
        TabInfo(title: "Main", systemImage: "moon.fill"),
        TabInfo(title: "Sounds", systemImage: "speaker.wave.3.fill"),
        TabInfo(title: "Backgrounds", systemImage: "photo.fill"),
        TabInfo(title: "Settings", systemImage: "gearshape.fill"),
        TabInfo(title: "Info", systemImage: "info.circle.fill")
    ]
    
    var body: some View {
        ZStack {
            if mainViewModel.isSleepModeActive {
                // When in sleep mode, show only SleepView with full screen coverage
                ZStack {
                    Color.black.ignoresSafeArea(.all)
                    SleepView()
                        .ignoresSafeArea(.all)
                }
                .onAppear {
                    print("DEBUG: Sleep mode active - tab bar should be hidden")
                }
            } else {
                // Normal tab view when not in sleep mode
                VStack(spacing: 0) {
                    // Tab content
                    Group {
                        switch selectedTab {
                        case 0:
                            SleepView()
                        case 1:
                            SoundsListView()
                        case 2:
                            BackgroundsView()
                        case 3:
                            SettingsView()
                        case 4:
                            InformationView()
                        default:
                            SleepView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Custom tab bar
                    customTabBar
                }
            }
        }
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                Button {
                    selectedTab = index
                    HapticFeedback.light()
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: tabs[index].systemImage)
                            .font(.system(size: 24, weight: .medium))
                        Text(tabs[index].title)
                            .font(.caption2)
                    }
                    .foregroundColor(selectedTab == index ? .blue : .secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(height: 49) // Standard iOS tab bar height
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.1), radius: 0.5, x: 0, y: -0.5)
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
}

private struct TabInfo {
    let title: String
    let systemImage: String
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