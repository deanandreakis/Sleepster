//
//  MainViewModel.swift
//  SleepMate
//
//  Created by Claude on Phase 2 Migration
//

import Foundation
import SwiftUI
import Combine

@MainActor
class MainViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let audioManager: AudioManager
    private let timerManager: TimerManager
    private let databaseManager: DatabaseManager
    private let settingsManager: SettingsManager
    
    // MARK: - Published Properties
    @Published var isSleepModeActive = false
    @Published var currentVolume: Float = 0.5
    @Published var isTimerRunning = false
    @Published var timerDuration: TimeInterval = 300.0
    @Published var timeRemaining: TimeInterval = 300.0
    @Published var selectedSound: SoundEntity?
    @Published var selectedBackground: BackgroundEntity?
    @Published var isAudioPlaying = false
    @Published var errorMessage: String?
    
    // MARK: - Timer Display
    @Published var timerDisplayText = "05:00"
    @Published var timerProgress: Double = 0.0
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var timerJustStarted = false
    private var internalTimer: Timer?
    private var timerStartTime: Date?
    private var defaultSoundRetryCount = 0
    
    // MARK: - Initialization
    init(
        audioManager: AudioManager,
        timerManager: TimerManager,
        databaseManager: DatabaseManager,
        settingsManager: SettingsManager
    ) {
        self.audioManager = audioManager
        self.timerManager = timerManager
        self.databaseManager = databaseManager
        self.settingsManager = settingsManager
        
        setupBindings()
        loadInitialData()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Audio Manager bindings
        audioManager.$isPlaying
            .receive(on: DispatchQueue.main)
            .assign(to: \.isAudioPlaying, on: self)
            .store(in: &cancellables)
        
        audioManager.$volume
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentVolume, on: self)
            .store(in: &cancellables)
        
        // Timer Manager bindings
        timerManager.$isRunning
            .receive(on: DispatchQueue.main)
            .assign(to: \.isTimerRunning, on: self)
            .store(in: &cancellables)
        
        // Note: Removed timerManager.$duration binding as it was overriding our timerDuration
        // The MainViewModel manages timerDuration independently and syncs it to TimerManager when needed
        
        // Note: Disabled TimerManager timeRemaining binding to avoid 2-second jump
        // Using our own internal timer for smooth countdown display
        
        // Timer completion
        timerManager.timerCompletedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.handleTimerCompletion()
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        // Load selected sound and background
        selectedSound = databaseManager.fetchSelectedSound()
        selectedBackground = databaseManager.fetchSelectedBackground()
        
        // Set default sound if none is selected
        if selectedSound == nil {
            setDefaultSound()
        }
        
        // Load last used volume
        currentVolume = settingsManager.lastVolume
        audioManager.setVolume(currentVolume)
        
        // Set 5-minute default timer
        timerDuration = 300.0
        
        // Always show the timer duration when not running (including defaults)
        if !isTimerRunning {
            timeRemaining = timerDuration
            updateTimerDisplay()
            updateTimerProgress()
        }
        
        // Force UI update
        objectWillChange.send()
    }
    
    func refreshSelectedSound() {
        selectedSound = databaseManager.fetchSelectedSound()
    }
    
    func ensureDefaultSound() {
        if selectedSound == nil {
            setDefaultSound()
        }
    }
    
    private func setDefaultSound() {
        let allSounds = databaseManager.fetchAllSounds()
        
        // If no sounds are available yet, try again after a short delay (max 5 retries)
        if allSounds.isEmpty && defaultSoundRetryCount < 5 {
            defaultSoundRetryCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.setDefaultSound()
            }
            return
        }
        
        // Look for "Thunder Storm" first
        if let thunderstormSound = allSounds.first(where: { $0.bTitle == "Thunder Storm" }) {
            selectSound(thunderstormSound)
            print("Default sound set to Thunder Storm")
            return
        }
        
        // Fallback to first available sound if Thunder Storm not found
        if let firstSound = allSounds.first {
            selectSound(firstSound)
            print("Default sound set to: \(firstSound.bTitle ?? "Unknown")")
        } else {
            print("No sounds available for default selection")
        }
    }
    
    // MARK: - Actions
    func startSleeping() {
        // Refresh selected sound to ensure we have the latest selection
        refreshSelectedSound()
        
        guard let sound = selectedSound else {
            errorMessage = "Please select a sound first"
            return
        }
        
        isSleepModeActive = true
        
        // Start playing selected sound
        if let soundURL = sound.soundUrl1 {
            audioManager.playSound(url: soundURL, loop: true)
        }
        
        // Start timer if duration is set
        if timerDuration > 0 {
            // Ensure timeRemaining matches timerDuration before starting
            timeRemaining = timerDuration
            updateTimerDisplay()
            updateTimerProgress()
            
            // Start our own smooth countdown timer
            startInternalTimer()
            
            // Force UI update
            objectWillChange.send()
            
            // Still start TimerManager for background functionality (audio fadeout, etc.)
            timerManager.startTimer(duration: timerDuration)
        }
        
        // Disable auto-lock if setting is enabled
        if settingsManager.isAutoLockDisabled {
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    
    func stopSleeping() {
        isSleepModeActive = false
        
        // Stop our internal timer
        stopInternalTimer()
        
        // Stop audio and timer
        audioManager.stopAllSounds()
        timerManager.stopTimer()
        
        // Reset timer display to full duration
        timeRemaining = timerDuration
        updateTimerDisplay()
        updateTimerProgress()
        
        // Re-enable auto-lock
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func toggleSleepMode() {
        if isSleepModeActive {
            stopSleeping()
        } else {
            startSleeping()
        }
    }
    
    func updateVolume(_ volume: Float) {
        currentVolume = volume
        audioManager.setVolume(volume)
        settingsManager.lastVolume = volume
    }
    
    func setTimerDuration(_ duration: TimeInterval) {
        timerDuration = duration
        settingsManager.lastTimerDuration = duration
        
        // Update display to show the selected duration when timer is not running
        if !isTimerRunning {
            timeRemaining = duration
            updateTimerDisplay()
            updateTimerProgress()
        }
        
        // Force UI update
        objectWillChange.send()
    }
    
    func selectSound(_ sound: SoundEntity) {
        // Deselect previous sound
        selectedSound?.isSelected = false
        
        // Select new sound
        sound.selectSound()
        selectedSound = sound
        
        // Save to database
        databaseManager.saveContext()
        
        // If currently playing, switch to new sound
        if isSleepModeActive {
            audioManager.stopAllSounds()
            if let soundURL = sound.soundUrl1 {
                audioManager.playSound(url: soundURL, loop: true)
            }
        }
    }
    
    func selectBackground(_ background: BackgroundEntity) {
        // Deselect previous background
        selectedBackground?.isSelected = false
        
        // Select new background
        background.selectBackground()
        selectedBackground = background
        
        // Save to database
        databaseManager.saveContext()
    }
    
    // MARK: - Timer Display Updates
    private func updateTimerDisplay() {
        // Use ceiling to round up (e.g., 298.99 seconds should show as 299 seconds)
        let totalSecondsRemaining = Int(ceil(timeRemaining))
        let minutes = totalSecondsRemaining / 60
        let seconds = totalSecondsRemaining % 60
        timerDisplayText = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func updateTimerProgress() {
        if timerDuration > 0 {
            timerProgress = 1.0 - (timeRemaining / timerDuration)
        } else {
            timerProgress = 0.0
        }
    }
    
    private func handleTimerCompletion() {
        // Gradually fade out audio
        audioManager.fadeOutAndStop(duration: 10.0) { [weak self] in
            DispatchQueue.main.async {
                self?.stopSleeping()
            }
        }
    }
    
    // MARK: - Internal Timer Management
    private func startInternalTimer() {
        timerStartTime = Date()
        
        internalTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateInternalTimer()
        }
    }
    
    private func stopInternalTimer() {
        internalTimer?.invalidate()
        internalTimer = nil
        timerStartTime = nil
    }
    
    private func updateInternalTimer() {
        guard let startTime = timerStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let newTimeRemaining = max(0, timerDuration - elapsed)
        
        timeRemaining = newTimeRemaining
        updateTimerDisplay()
        updateTimerProgress()
        
        // Stop if we've reached zero (though TimerManager should handle completion)
        if newTimeRemaining <= 0 {
            stopInternalTimer()
        }
    }
    
    // MARK: - Quick Actions
    func sleepNow() {
        // Use default settings for immediate sleep
        if selectedSound == nil {
            // Reload from database in case the selectedSound wasn't loaded properly
            selectedSound = databaseManager.fetchSelectedSound()
            
            // Only auto-select if there's truly no selected sound in database
            if selectedSound == nil {
                let sounds = databaseManager.fetchAllSounds()
                if let firstSound = sounds.first {
                    selectSound(firstSound)
                }
            }
        }
        
        // Set default timer if none set
        if timerDuration == 0 {
            setTimerDuration(1800) // 30 minutes default
        }
        
        startSleeping()
    }
}