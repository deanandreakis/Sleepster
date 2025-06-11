//
//  TimerViewModel.swift
//  SleepMate
//
//  Created by Claude on Phase 2 Migration
//

import Foundation
import SwiftUI
import Combine

@MainActor
class TimerViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let timerManager: TimerManager
    private let settingsManager: SettingsManager
    
    // MARK: - Published Properties
    @Published var selectedDuration: TimeInterval = 1800 // 30 minutes default
    @Published var customDuration: TimeInterval = 1800
    @Published var isCustomDurationMode = false
    @Published var fadeOutDuration: TimeInterval = 10.0
    @Published var isTimerRunning = false
    @Published var timeRemaining: TimeInterval = 0
    @Published var timerProgress: Double = 0.0
    
    // MARK: - Timer Display
    @Published var timerDisplayText = "30:00"
    @Published var remainingDisplayText = "00:00"
    
    // MARK: - Predefined Durations
    let predefinedDurations: [TimeInterval] = [
        300,   // 5 minutes
        600,   // 10 minutes
        900,   // 15 minutes
        1200,  // 20 minutes
        1800,  // 30 minutes
        2700,  // 45 minutes
        3600,  // 1 hour
        5400,  // 1.5 hours
        7200   // 2 hours
    ]
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(timerManager: TimerManager, settingsManager: SettingsManager) {
        self.timerManager = timerManager
        self.settingsManager = settingsManager
        
        loadSettings()
        setupBindings()
        updateDisplayTexts()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Timer Manager bindings
        timerManager.$isRunning
            .receive(on: DispatchQueue.main)
            .assign(to: \.isTimerRunning, on: self)
            .store(in: &cancellables)
        
        timerManager.$timeRemaining
            .receive(on: DispatchQueue.main)
            .sink { [weak self] timeRemaining in
                self?.timeRemaining = timeRemaining
                self?.updateRemainingDisplayText()
                self?.updateProgress()
            }
            .store(in: &cancellables)
        
        // Duration changes
        $selectedDuration
            .sink { [weak self] duration in
                self?.updateTimerDisplayText()
                self?.saveSelectedDuration()
            }
            .store(in: &cancellables)
        
        $customDuration
            .sink { [weak self] duration in
                if self?.isCustomDurationMode == true {
                    self?.selectedDuration = duration
                }
            }
            .store(in: &cancellables)
        
        $fadeOutDuration
            .dropFirst()
            .sink { [weak self] duration in
                self?.settingsManager.timerFadeOutDuration = duration
            }
            .store(in: &cancellables)
    }
    
    private func loadSettings() {
        selectedDuration = settingsManager.defaultTimerDuration
        customDuration = selectedDuration
        fadeOutDuration = settingsManager.timerFadeOutDuration
        
        // Check if selected duration is in predefined list
        isCustomDurationMode = !predefinedDurations.contains(selectedDuration)
    }
    
    private func saveSelectedDuration() {
        settingsManager.defaultTimerDuration = selectedDuration
    }
    
    // MARK: - Timer Controls
    func startTimer() {
        timerManager.startTimer(duration: selectedDuration, fadeOutDuration: fadeOutDuration)
    }
    
    func stopTimer() {
        timerManager.stopTimer()
    }
    
    func pauseTimer() {
        timerManager.pauseTimer()
    }
    
    func resumeTimer() {
        timerManager.resumeTimer()
    }
    
    func resetTimer() {
        timerManager.resetTimer()
        timeRemaining = 0
        timerProgress = 0.0
        updateRemainingDisplayText()
    }
    
    func addTime(_ minutes: Int) {
        let additionalTime = TimeInterval(minutes * 60)
        timerManager.addTime(additionalTime)
    }
    
    // MARK: - Duration Selection
    func selectDuration(_ duration: TimeInterval) {
        selectedDuration = duration
        isCustomDurationMode = !predefinedDurations.contains(duration)
        
        if isCustomDurationMode {
            customDuration = duration
        }
    }
    
    func selectCustomDuration() {
        isCustomDurationMode = true
        selectedDuration = customDuration
    }
    
    func selectPredefinedDuration(_ duration: TimeInterval) {
        isCustomDurationMode = false
        selectedDuration = duration
    }
    
    // MARK: - Display Updates
    private func updateDisplayTexts() {
        updateTimerDisplayText()
        updateRemainingDisplayText()
    }
    
    private func updateTimerDisplayText() {
        timerDisplayText = formatDuration(selectedDuration)
    }
    
    private func updateRemainingDisplayText() {
        remainingDisplayText = formatDuration(timeRemaining)
    }
    
    private func updateProgress() {
        if selectedDuration > 0 {
            timerProgress = 1.0 - (timeRemaining / selectedDuration)
        } else {
            timerProgress = 0.0
        }
    }
    
    // MARK: - Helper Methods
    func formatDuration(_ duration: TimeInterval) -> String {
        let totalMinutes = Int(duration) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else {
            return String(format: "%02d:00", minutes)
        }
    }
    
    func formatDetailedDuration(_ duration: TimeInterval) -> String {
        let totalMinutes = Int(duration) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(hours)h"
            }
        } else {
            return "\(minutes)m"
        }
    }
    
    func getDurationDescription(_ duration: TimeInterval) -> String {
        switch duration {
        case 300: return "Quick nap"
        case 600: return "Power nap"
        case 900: return "Short rest"
        case 1200: return "Medium rest"
        case 1800: return "Standard sleep"
        case 2700: return "Extended rest"
        case 3600: return "Deep sleep"
        case 5400: return "Long sleep"
        case 7200: return "Full cycle"
        default: return "Custom duration"
        }
    }
    
    // MARK: - Validation
    func isValidDuration(_ duration: TimeInterval) -> Bool {
        return duration >= 60 && duration <= 28800 // 1 minute to 8 hours
    }
    
    func isValidFadeOutDuration(_ duration: TimeInterval) -> Bool {
        return duration >= 1 && duration <= 300 // 1 second to 5 minutes
    }
    
    // MARK: - Quick Actions
    func add5Minutes() {
        addTime(5)
    }
    
    func add10Minutes() {
        addTime(10)
    }
    
    func add15Minutes() {
        addTime(15)
    }
    
    // MARK: - Timer State
    var canStart: Bool {
        return !isTimerRunning && selectedDuration > 0
    }
    
    var canPause: Bool {
        return isTimerRunning && !timerManager.isPaused
    }
    
    var canResume: Bool {
        return isTimerRunning && timerManager.isPaused
    }
    
    var canStop: Bool {
        return isTimerRunning
    }
    
    var canAddTime: Bool {
        return isTimerRunning
    }
}