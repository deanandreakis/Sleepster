//
//  TimerSettingsView.swift
//  SleepMate
//
//  Created by Claude on Phase 3 Migration
//

import SwiftUI

struct TimerSettingsView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @StateObject private var viewModel: TimerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var customHours = 0
    @State private var customMinutes = 30
    @State private var showingCustomPicker = false
    
    init() {
        // ViewModel will be injected via environment in real usage
        let container = ServiceContainer()
        self._viewModel = StateObject(wrappedValue: container.timerViewModel)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Current timer display
                    currentTimerSection
                    
                    // Predefined durations
                    predefinedDurationsSection
                    
                    // Custom duration
                    customDurationSection
                    
                    // Fade out settings
                    fadeOutSettingsSection
                    
                    // Timer controls (if timer is running)
                    if viewModel.isTimerRunning {
                        timerControlsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Timer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticFeedback.success()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            setupViewModel()
            updateCustomTime()
        }
        .sheet(isPresented: $showingCustomPicker) {
            customTimePickerSheet
        }
    }
    
    // MARK: - Subviews
    
    private var currentTimerSection: some View {
        CardView {
            VStack(spacing: 16) {
                Text("Current Timer")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if viewModel.isTimerRunning {
                    VStack(spacing: 8) {
                        Text(viewModel.remainingDisplayText)
                            .font(.system(size: 42, weight: .light, design: .monospaced))
                            .foregroundColor(.blue)
                        
                        Text("remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Progress bar
                        ProgressView(value: viewModel.timerProgress)
                            .tint(.blue)
                            .scaleEffect(y: 2)
                    }
                } else {
                    VStack(spacing: 8) {
                        Text(viewModel.timerDisplayText)
                            .font(.system(size: 42, weight: .light, design: .monospaced))
                            .foregroundColor(.primary)
                        
                        Text("selected duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var predefinedDurationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Select")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(viewModel.predefinedDurations, id: \.self) { duration in
                    predefinedDurationButton(duration)
                }
            }
        }
    }
    
    private func predefinedDurationButton(_ duration: TimeInterval) -> some View {
        Button {
            HapticFeedback.light()
            viewModel.selectPredefinedDuration(duration)
        } label: {
            VStack(spacing: 4) {
                Text(viewModel.formatDuration(duration))
                    .font(.title3)
                
                Text(viewModel.getDurationDescription(duration))
                    .font(.caption2)
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(viewModel.selectedDuration == duration ? .white : .primary)
            .padding()
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.selectedDuration == duration ? Color.blue : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.selectedDuration == duration ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private var customDurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom Duration")
                .font(.headline)
                .foregroundColor(.primary)
            
            Button {
                HapticFeedback.light()
                showingCustomPicker = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Set Custom Time")
                            .font(.subheadline)
                                        
                        if viewModel.isCustomDurationMode {
                            Text(viewModel.formatDetailedDuration(viewModel.customDuration))
                                .font(.caption)
                                .foregroundColor(.blue)
                        } else {
                            Text("Tap to set a custom duration")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .foregroundColor(.primary)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var fadeOutSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fade Out")
                .font(.headline)
                .foregroundColor(.primary)
            
            CardView {
                VStack(spacing: 16) {
                    HStack {
                        Text("Fade Duration")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(Int(viewModel.fadeOutDuration))s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: $viewModel.fadeOutDuration,
                        in: 1...60,
                        step: 1
                    )
                    .tint(.blue)
                    
                    Text("Audio will gradually fade out over this duration when the timer expires")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    private var timerControlsSection: some View {
        VStack(spacing: 16) {
            Text("Timer Controls")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                if viewModel.canPause {
                    SecondaryButton("Pause") {
                        HapticFeedback.medium()
                        viewModel.pauseTimer()
                    }
                }
                
                if viewModel.canResume {
                    PrimaryButton("Resume") {
                        HapticFeedback.medium()
                        viewModel.resumeTimer()
                    }
                }
                
                if viewModel.canStop {
                    SecondaryButton("Stop") {
                        HapticFeedback.heavy()
                        viewModel.stopTimer()
                    }
                }
            }
            
            // Add time buttons
            if viewModel.canAddTime {
                VStack(spacing: 12) {
                    Text("Add Time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        addTimeButton("+5m", minutes: 5)
                        addTimeButton("+10m", minutes: 10)
                        addTimeButton("+15m", minutes: 15)
                    }
                }
                .padding(.top)
            }
        }
    }
    
    private func addTimeButton(_ title: String, minutes: Int) -> some View {
        Button {
            HapticFeedback.light()
            viewModel.addTime(minutes)
        } label: {
            Text(title)
                .font(.caption)
                    .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var customTimePickerSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Time picker
                HStack {
                    Picker("Hours", selection: $customHours) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour)h").tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    
                    Picker("Minutes", selection: $customMinutes) {
                        ForEach(Array(stride(from: 0, through: 59, by: 5)), id: \.self) { minute in
                            Text("\(minute)m").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                .padding()
                
                Spacer()
                
                // Preview
                Text("Duration: \(customHours)h \(customMinutes)m")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Custom Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingCustomPicker = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Set") {
                        let totalSeconds = TimeInterval((customHours * 3600) + (customMinutes * 60))
                        if viewModel.isValidDuration(totalSeconds) {
                            viewModel.customDuration = totalSeconds
                            viewModel.selectCustomDuration()
                            HapticFeedback.success()
                        } else {
                            HapticFeedback.error()
                        }
                        showingCustomPicker = false
                    }
                }
            }
        }
        // .presentationDetents([.medium]) // iOS 16+ only
    }
    
    // MARK: - Helper Methods
    
    private func setupViewModel() {
        // In real implementation, this would be handled by dependency injection
        // viewModel = serviceContainer.timerViewModel
    }
    
    private func updateCustomTime() {
        let duration = viewModel.customDuration
        customHours = Int(duration) / 3600
        customMinutes = (Int(duration) % 3600) / 60
    }
}

// MARK: - Preview
#Preview {
    TimerSettingsView()
        .environmentObject(ServiceContainer())
}