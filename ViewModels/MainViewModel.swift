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
    @Published var timerDuration: TimeInterval = 0
    @Published var timeRemaining: TimeInterval = 0
    @Published var selectedSound: SoundEntity?
    @Published var selectedBackground: BackgroundEntity?
    @Published var isAudioPlaying = false
    @Published var errorMessage: String?
    
    // MARK: - Timer Display
    @Published var timerDisplayText = "00:00"
    @Published var timerProgress: Double = 0.0
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
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
        
        timerManager.$duration
            .receive(on: DispatchQueue.main)
            .assign(to: \.timerDuration, on: self)
            .store(in: &cancellables)
        
        timerManager.$timeRemaining
            .receive(on: DispatchQueue.main)
            .sink { [weak self] timeRemaining in
                self?.timeRemaining = timeRemaining
                self?.updateTimerDisplay()
                self?.updateTimerProgress()
            }
            .store(in: &cancellables)
        
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
        
        // Load last used volume
        currentVolume = settingsManager.lastVolume
        audioManager.setVolume(currentVolume)
        
        // Load last used timer duration and display it
        timerDuration = settingsManager.lastTimerDuration
        if timerDuration > 0 && !isTimerRunning {
            timeRemaining = timerDuration
            updateTimerDisplay()
            updateTimerProgress()
        }
    }
    
    // MARK: - Actions
    func startSleeping() {
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
            timerManager.startTimer(duration: timerDuration)
        }
        
        // Disable auto-lock if setting is enabled
        if settingsManager.isAutoLockDisabled {
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    
    func stopSleeping() {
        isSleepModeActive = false
        
        // Stop audio and timer
        audioManager.stopAllSounds()
        timerManager.stopTimer()
        
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
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
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
    
    // MARK: - Quick Actions
    func sleepNow() {
        // Use default settings for immediate sleep
        if selectedSound == nil {
            // Select first available sound
            let sounds = databaseManager.fetchAllSounds()
            if let firstSound = sounds.first {
                selectSound(firstSound)
            }
        }
        
        // Set default timer if none set
        if timerDuration == 0 {
            setTimerDuration(1800) // 30 minutes default
        }
        
        startSleeping()
    }
}