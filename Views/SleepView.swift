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
    @StateObject private var viewModel: MainViewModel
    
    @State private var showingTimerSettings = false
    @State private var showingBrightnessControl = false
    
    init() {
        // ViewModel will be injected via environment in real usage
        // This is just for initialization
        let container = ServiceContainer()
        self._viewModel = StateObject(wrappedValue: container.mainViewModel)
    }
    
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
                    
                    // Bottom controls
                    bottomControlsView
                }
                .padding()
                
                // Loading overlay
                if viewModel.isLoading {
                    LoadingView(message: "Preparing your sleep experience...")
                        .transition(.opacity)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupViewModel()
            handleQuickSleep()
        }
        .sheet(isPresented: $showingTimerSettings) {
            TimerSettingsView()
        }
        .sheet(isPresented: $showingBrightnessControl) {
            BrightnessControlView()
        }
        .alert(item: $viewModel.alertItem) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: alert.dismissButton
            )
        }
    }
    
    // MARK: - Subviews
    
    private var backgroundView: some View {
        Group {
            if let backgroundImage = appState.currentBackgroundImage {
                Image(uiImage: backgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            } else {
                appState.currentBackgroundColor
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
                
                if let soundTitle = viewModel.selectedSound?.bTitle {
                    Text(soundTitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                // Brightness control
                Button {
                    HapticFeedback.light()
                    showingBrightnessControl = true
                } label: {
                    Image(systemName: "sun.max")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                // Settings
                Button {
                    HapticFeedback.light()
                    appState.selectedTab = .settings
                } label: {
                    Image(systemName: "gearshape")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
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
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var bottomControlsView: some View {
        HStack(spacing: 24) {
            // Sounds navigation
            Button {
                HapticFeedback.light()
                appState.selectedTab = .sounds
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "speaker.wave.3")
                        .font(.title2)
                    Text("Sounds")
                        .font(.caption)
                }
                .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Timer settings
            Button {
                HapticFeedback.light()
                showingTimerSettings = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.title2)
                    Text("Timer")
                        .font(.caption)
                }
                .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Backgrounds navigation
            Button {
                HapticFeedback.light()
                appState.selectedTab = .backgrounds
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(.title2)
                    Text("Backgrounds")
                        .font(.caption)
                }
                .foregroundColor(.primary)
            }
        }
        .padding(.bottom)
    }
    
    // MARK: - Helper Methods
    
    private func setupViewModel() {
        // In real implementation, this would be handled by dependency injection
        // viewModel = serviceContainer.mainViewModel
    }
    
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