//
//  MainViewModel.swift
//  SleepMate
//
//  Created by Claude on Phase 2 Migration
//

import Foundation
import SwiftUI
import Combine

struct TimeoutError: Error {}

@MainActor
class MainViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let audioManager: AudioManager
    private let timerManager: TimerManager
    private let databaseManager: DatabaseManager
    private let settingsManager: SettingsManager
    private let audioMixingEngine: AudioMixingEngine
    let brightnessManager: BrightnessManager
    
    // MARK: - Published Properties
    @Published var isSleepModeActive = false
    @Published var currentVolume: Float = 0.5
    @Published var isTimerRunning = false
    @Published var timerDuration: TimeInterval = 300.0
    @Published var timeRemaining: TimeInterval = 300.0
    @Published var selectedSound: SoundEntity?
    @Published var selectedBackground: BackgroundEntity?
    @Published var selectedSoundsForMixing: [SoundEntity] = []
    @Published var isMixingMode = false
    @Published var isAudioPlaying = false
    @Published var errorMessage: String?
    
    // Audio mixing state
    @Published var activeChannelPlayers: [String: AudioChannelPlayer] = [:]
    
    // MARK: - Timer Display
    @Published var timerDisplayText = "05:00"
    @Published var timerProgress: Double = 0.0
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var timerJustStarted = false
    private var defaultSoundRetryCount = 0
    
    // MARK: - Initialization
    init(
        audioManager: AudioManager,
        timerManager: TimerManager,
        databaseManager: DatabaseManager,
        settingsManager: SettingsManager,
        audioMixingEngine: AudioMixingEngine = AudioMixingEngine.shared,
        brightnessManager: BrightnessManager
    ) {
        self.audioManager = audioManager
        self.timerManager = timerManager
        self.databaseManager = databaseManager
        self.settingsManager = settingsManager
        self.audioMixingEngine = audioMixingEngine
        self.brightnessManager = brightnessManager
        
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
        
        // Timer Manager timeRemaining binding
        timerManager.$timeRemaining
            .receive(on: DispatchQueue.main)
            .sink { [weak self] timeRemaining in
                guard let self = self else { return }
                // Only update from TimerManager when timer is actually running
                if self.timerManager.isRunning {
                    self.timeRemaining = timeRemaining
                    self.updateTimerDisplay()
                    self.updateTimerProgress()
                }
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
        // Set immediate defaults for responsive UI
        timerDuration = settingsManager.lastTimerDuration
        timeRemaining = timerDuration
        currentVolume = settingsManager.lastVolume
        updateTimerDisplay()
        updateTimerProgress()
        
        // Load data asynchronously to avoid blocking UI
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            
            // Load from database on background thread
            let sound = await self.databaseManager.fetchSelectedSoundAsync()
            let background = await self.databaseManager.fetchSelectedBackgroundAsync()
            let soundsForMixing = await self.databaseManager.fetchSelectedSoundsForMixingAsync()
            
            // Update UI on main thread
            await MainActor.run {
                self.selectedSound = sound
                self.selectedBackground = background
                self.selectedSoundsForMixing = soundsForMixing
                self.isMixingMode = !soundsForMixing.isEmpty
                
                // Set default sound if none is selected
                if sound == nil && soundsForMixing.isEmpty {
                    self.setDefaultSound()
                }
                
                // Set volume after audio manager is ready
                self.audioManager.setVolume(self.currentVolume)
                
                // Force UI update
                self.objectWillChange.send()
            }
        }
    }
    
    func refreshSelectedSound() {
        selectedSound = databaseManager.fetchSelectedSound()
    }
    
    func refreshSelectedSounds() {
        selectedSound = databaseManager.fetchSelectedSound()
        selectedSoundsForMixing = databaseManager.fetchSelectedSoundsForMixing()
        isMixingMode = !selectedSoundsForMixing.isEmpty
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
    
    // MARK: - Sound Mixing
    private func startMixedAudio() {
        print("🎵 startMixedAudio called")
        
        // Force stop any existing audio immediately
        audioMixingEngine.forceStopAll()
        
        // Clear UI state immediately
        activeChannelPlayers.removeAll()
        
        // Start audio setup in background - completely detached
        Task {
            // Small delay to ensure clean start
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            // Start each selected sound
            for sound in selectedSoundsForMixing {
                if let soundName = sound.soundUrl1?.replacingOccurrences(of: ".mp3", with: "") {
                    if let channelPlayer = await audioMixingEngine.playSound(named: soundName, volume: 1.0, loop: true) {
                        activeChannelPlayers[soundName] = channelPlayer
                    }
                }
            }
            
            print("🎵 Audio setup complete")
        }
    }
    
    func addSoundToMix(_ sound: SoundEntity) {
        // Check maximum sounds limit (5)
        guard selectedSoundsForMixing.count < 5 else {
            errorMessage = "Maximum 5 sounds can be mixed simultaneously"
            return
        }
        
        sound.addToMix()
        databaseManager.saveContext()
        refreshSelectedSounds()
    }
    
    func removeSoundFromMix(_ sound: SoundEntity) {
        sound.removeFromMix()
        databaseManager.saveContext()
        refreshSelectedSounds()
    }
    
    func toggleSoundInMix(_ sound: SoundEntity) {
        if sound.isSelectedForMixing {
            removeSoundFromMix(sound)
        } else {
            addSoundToMix(sound)
        }
    }
    
    func setSoundVolume(_ volume: Float, for sound: SoundEntity) {
        guard let soundName = sound.soundUrl1?.replacingOccurrences(of: ".mp3", with: ""),
              let channelPlayer = activeChannelPlayers[soundName] else { return }
        
        audioMixingEngine.setVolume(volume, for: channelPlayer)
    }
    
    func getSoundVolume(for sound: SoundEntity) -> Float {
        guard let soundName = sound.soundUrl1?.replacingOccurrences(of: ".mp3", with: ""),
              let channelPlayer = activeChannelPlayers[soundName] else { return 1.0 }
        
        return channelPlayer.volume
    }
    
    // MARK: - Actions
    func startSleeping() {
        print("🎬 startSleeping called")
        
        // Refresh selected sounds
        refreshSelectedSounds()
        
        // Update UI state IMMEDIATELY
        isSleepModeActive = true
        
        // Start timer if duration is set
        if timerDuration > 0 {
            // Start TimerManager - it will handle all timer functionality
            timerManager.startTimer(duration: timerDuration)
        }
        
        // Disable auto-lock if setting is enabled
        if settingsManager.isAutoLockDisabled {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        // Auto-adjust brightness if enabled
        brightnessManager.dimForSleep()
        
        print("🎬 UI state updated, starting audio in background")
        
        // Start audio based on mode
        if isMixingMode && !selectedSoundsForMixing.isEmpty {
            startMixedAudio()
        } else if let sound = selectedSound {
            // Fallback to single sound mode
            if let soundURL = sound.soundUrl1 {
                audioManager.playSound(url: soundURL, loop: true)
            }
        } else {
            errorMessage = "Please select a sound first"
            isSleepModeActive = false
            return
        }
        
        print("🎬 startSleeping complete - audio starting in background")
    }
    
    func stopSleeping() {
        print("🛑 stopSleeping called")
        
        // Update UI state immediately
        isSleepModeActive = false
        timerManager.stopTimer()
        UIApplication.shared.isIdleTimerDisabled = false
        
        // Restore brightness if auto-adjust was enabled
        brightnessManager.restoreFromSleep()
        
        // Stop legacy audio manager
        audioManager.stopAllSounds()
        
        // Clear UI state
        activeChannelPlayers.removeAll()
        
        // Force stop all audio mixing (nuclear option - stops entire engine)
        audioMixingEngine.forceStopAll()
        
        print("🛑 stopSleeping complete")
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
        // Use standard rounding for smooth display (avoids visual jumps)
        let totalSecondsRemaining = Int(round(timeRemaining))
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
        // Update UI state immediately to maintain responsiveness
        isSleepModeActive = false
        UIApplication.shared.isIdleTimerDisabled = false
        
        // Schedule brightness restoration for user touch instead of immediate restore
        brightnessManager.scheduleRestoreOnTouch()
        
        // Handle audio cleanup with a simpler non-blocking approach
        // Use a short fade duration and immediate cleanup to avoid UI blocking
        audioManager.fadeOutAndStop(duration: 2.0) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                // Stop legacy audio manager
                self.audioManager.stopAllSounds()
                
                // Clear UI state
                self.activeChannelPlayers.removeAll()
                
                // Force stop all audio mixing with minimal delay
                DispatchQueue.global(qos: .background).async {
                    self.audioMixingEngine.forceStopAll()
                }
            }
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