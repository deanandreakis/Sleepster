//
//  SleepView.swift
//  SleepMate
//
//  Created by Claude on Phase 3 Migration
//

import SwiftUI

struct SleepView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coreDataStack: CoreDataStack
    
    @State private var showingTimerSettings = false
    @State private var showingBrightnessControl = false
    @StateObject private var viewModel = SharedViewModelStore.shared.mainViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundView
                
                // Main content
                VStack(spacing: 0) {
                    // Header with app title and controls
                    headerView
                    
                    Spacer()
                    
                    // Main sleep interface
                    mainContentView(geometry: geometry)
                    
                    Spacer()
                }
                .padding()
                .opacity(coreDataStack.isInitialized ? 1.0 : 0.3)
                
                // Loading overlay
                if !coreDataStack.isInitialized {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Preparing Sleep Experience...")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .background(Color(.systemBackground).opacity(0.9))
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Refresh selected sound in case it was changed in another view
            viewModel.refreshSelectedSound()
            
            // Ensure default sound is set if none selected
            viewModel.ensureDefaultSound()
            
            handleQuickSleep()
        }
        .sheet(isPresented: $showingTimerSettings) {
            TimerSettingsView()
        }
        .sheet(isPresented: $showingBrightnessControl) {
            BrightnessControlView()
        }
        .simultaneousGesture(
            TapGesture().onEnded { _ in
                // Check if brightness restoration is pending and restore if needed
                viewModel.brightnessManager.restoreOnTouchIfNeeded()
            }
        )
        // .alert(item: $viewModel.alertItem) { alert in
        //     Alert(
        //         title: Text(alert.title),
        //         message: Text(alert.message),
        //         dismissButton: alert.dismissButton
        //     )
        // }
    }
    
    // MARK: - Subviews
    
    private var backgroundView: some View {
        ZStack {
            if let backgroundImage = appState.currentBackgroundImage {
                Image(uiImage: backgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            } else {
                Color(appState.currentBackgroundColor)
                    .ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 0.5), value: appState.currentBackgroundImage)
        .animation(.easeInOut(duration: 0.5), value: appState.currentBackgroundColor)
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Sleepster")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if viewModel.isMixingMode && !viewModel.selectedSoundsForMixing.isEmpty {
                    Text("\(viewModel.selectedSoundsForMixing.count) sounds selected for mixing")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else if let soundTitle = viewModel.selectedSound?.bTitle {
                    Text(soundTitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Brightness control
            Button {
                HapticFeedback.light()
                showingBrightnessControl = true
            } label: {
                Image(systemName: "sun.max")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
        .padding(.top)
    }
    
    private func mainContentView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 32) {
            // Timer display with progress ring
            timerDisplayView
            
            // Volume control
            VolumeSliderView(
                volume: $viewModel.currentVolume,
                onVolumeChange: viewModel.updateVolume
            )
            
            // Main sleep button
            sleepButtonView
            
            // Quick timer buttons
            quickTimerButtonsView
        }
        .frame(maxWidth: min(geometry.size.width - 40, 400))
    }
    
    private var timerDisplayView: some View {
        ZStack {
            // Progress ring
            CircularProgressView(
                progress: viewModel.timerProgress,
                lineWidth: 12,
                color: viewModel.isTimerRunning ? .blue : .gray.opacity(0.3)
            )
            .frame(width: 200, height: 200)
            
            // Timer display
            VStack(spacing: 8) {
                TimerDisplayView(
                    timeText: viewModel.timerDisplayText,
                    isActive: viewModel.isTimerRunning
                )
                
                if viewModel.isTimerRunning {
                    Text("remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onTapGesture {
            HapticFeedback.light()
            showingTimerSettings = true
        }
    }
    
    private var sleepButtonView: some View {
        Button {
            HapticFeedback.medium()
            viewModel.toggleSleepMode()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: viewModel.isSleepModeActive ? "stop.fill" : "play.fill")
                    .font(.title2)
                
                Text(viewModel.isSleepModeActive ? "Stop" : "Start Sleep")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(viewModel.isSleepModeActive ? Color.red : Color.blue)
                    .shadow(color: viewModel.isSleepModeActive ? .red.opacity(0.3) : .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .scaleEffect(viewModel.isSleepModeActive ? 1.05 : 1.0)
        .animation(.easeInOut, value: viewModel.isSleepModeActive)
    }
    
    private var quickTimerButtonsView: some View {
        VStack(spacing: 16) {
            Text("Quick Timer")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                quickTimerButton("1m", minutes: 1)
                quickTimerButton("5m", minutes: 5)
                quickTimerButton("15m", minutes: 15)
                quickTimerButton("30m", minutes: 30)
                quickTimerButton("45m", minutes: 45)
                quickTimerButton("1h", minutes: 60)
                quickTimerButton("2h", minutes: 120)
            }
        }
    }
    
    private func quickTimerButton(_ title: String, minutes: Int) -> some View {
        Button {
            HapticFeedback.light()
            viewModel.setTimerDuration(TimeInterval(minutes * 60))
        } label: {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Int(viewModel.timerDuration) == minutes * 60 ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Int(viewModel.timerDuration) == minutes * 60 ? Color.blue : Color(.systemGray5))
                )
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func handleQuickSleep() {
        if appState.shouldStartSleepingImmediately {
            viewModel.sleepNow()
        }
    }
}

// MARK: - Preview
#Preview {
    SleepView()
        .environmentObject(AppState())
        .environmentObject(ServiceContainer())
}