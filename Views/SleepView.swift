//
//  SleepView.swift
//  SleepMate
//
//  Created by Claude on Phase 3 Migration
//

import SwiftUI

struct SleepView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @ObservedObject var appState: AppState = AppState.shared
    @EnvironmentObject var coreDataStack: CoreDataStack
    @Environment(\.colorScheme) var colorScheme
    
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
                
                // Full-screen sleep animation overlay
                if viewModel.isSleepModeActive {
                    sleepAnimationOverlay
                        .ignoresSafeArea(.all)
                        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
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
                // Only handle brightness restoration when not in sleep mode
                // (Sleep mode overlay handles its own tap gesture)
                if !viewModel.isSleepModeActive {
                    viewModel.brightnessManager.restoreOnTouchIfNeeded()
                }
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
        // Plain white background like other tabs - no animation in normal mode
        Color(.systemBackground)
            .ignoresSafeArea()
    }
    
    // MARK: - Computed Properties
    
    private var shouldDimAnimation: Bool {
        // Dim the animation if we're in sleep mode OR if the brightness has been manually dimmed
        // But NOT just because we're in dark mode - animations should be vibrant in dark mode
        return viewModel.isSleepModeActive || appState.isDimmed
    }
    
    private var fallbackGradientColors: [Color] {
        if colorScheme == .dark {
            return [.black, .gray]
        } else {
            return [Color.blue.opacity(0.3), Color.purple.opacity(0.3), Color.white]
        }
    }
    
    private var adaptedColorTheme: ColorTheme {
        // In light mode, we want to use lighter, more vibrant themes
        // unless the user specifically selected a different theme
        if colorScheme == .light && appState.animationColorTheme == .defaultTheme {
            return .warm // Use warm theme for better light mode visibility
        }
        return appState.animationColorTheme
    }
    
    private var sleepAnimationOverlay: some View {
        ZStack {
            // Full-screen animation
            if let selectedAnimation = appState.selectedAnimation {
                selectedAnimation.createView(
                    intensity: appState.animationIntensity,
                    speed: appState.animationSpeed,
                    colorTheme: appState.animationColorTheme,
                    dimmed: true // Always dimmed in sleep mode
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black) // Ensure full coverage
            } else {
                // Fallback: Use default animation if none selected
                VStack {
                    Text("No animation selected")
                        .foregroundColor(.white)
                        .padding()
                    defaultSleepAnimation
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black) // Ensure full coverage
            }
            
            // Optional: Add subtle timer display in sleep mode
            if viewModel.isTimerRunning {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(viewModel.timerDisplayText)
                            .font(.title3.monospacedDigit())
                            .foregroundColor(.white.opacity(0.6))
                            .padding()
                        Spacer()
                    }
                    Spacer()
                        .frame(height: 50) // Keep timer away from bottom edge
                }
            }
        }
        .onTapGesture {
            // Tap anywhere to exit sleep mode
            HapticFeedback.medium()
            Task {
                await viewModel.stopSleeping()
            }
        }
    }
    
    private var defaultSleepAnimation: some View {
        // Simple default animation for when no specific animation is selected
        GeometryReader { geometry in
            ZStack {
                // Dark gradient background
                LinearGradient(
                    colors: [.black, .indigo.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Simple pulsing stars at fixed positions
                ForEach(defaultStarPositions(in: geometry.size), id: \.id) { star in
                    Circle()
                        .fill(.white.opacity(0.4))
                        .frame(width: star.size, height: star.size)
                        .position(x: star.x, y: star.y)
                        .opacity(0.3 + 0.4 * sin(Date().timeIntervalSince1970 * star.speed + star.phase))
                        .animation(
                            .easeInOut(duration: star.duration)
                            .repeatForever(autoreverses: true),
                            value: Date().timeIntervalSince1970
                        )
                }
            }
        }
    }
    
    private struct StarData: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let speed: Double
        let phase: Double
        let duration: Double
    }
    
    private func defaultStarPositions(in size: CGSize) -> [StarData] {
        // Generate consistent star positions based on screen size
        let positions: [(x: Float, y: Float)] = [
            (0.1, 0.1), (0.3, 0.05), (0.6, 0.15), (0.8, 0.1), (0.9, 0.25),
            (0.15, 0.3), (0.4, 0.25), (0.7, 0.35), (0.05, 0.45), (0.5, 0.4),
            (0.85, 0.5), (0.2, 0.6), (0.6, 0.65), (0.9, 0.7), (0.1, 0.8),
            (0.35, 0.75), (0.75, 0.85), (0.45, 0.9), (0.8, 0.95), (0.25, 0.95)
        ]
        
        return positions.enumerated().map { index, pos in
            StarData(
                x: CGFloat(pos.x) * size.width,
                y: CGFloat(pos.y) * size.height,
                size: CGFloat([1.5, 2.0, 2.5][index % 3]),
                speed: [0.5, 0.8, 1.2][index % 3],
                phase: Double(index) * 0.3,
                duration: [3.0, 4.0, 5.0][index % 3]
            )
        }
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