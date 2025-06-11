//
//  SoundsViewModel.swift
//  SleepMate
//
//  Created by Claude on Phase 2 Migration
//

import Foundation
import SwiftUI
import CoreData
import Combine

@MainActor
class SoundsViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let databaseManager: DatabaseManager
    private let audioManager: AudioManager
    
    // MARK: - Published Properties
    @Published var sounds: [SoundEntity] = []
    @Published var favoriteSounds: [SoundEntity] = []
    @Published var selectedSound: SoundEntity?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var showingFavoritesOnly = false
    @Published var isPreviewPlaying = false
    @Published var previewingSound: SoundEntity?
    
    // MARK: - Computed Properties
    var filteredSounds: [SoundEntity] {
        let soundsToFilter = showingFavoritesOnly ? favoriteSounds : sounds
        
        if searchText.isEmpty {
            return soundsToFilter
        } else {
            return soundsToFilter.filter { sound in
                sound.bTitle?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(databaseManager: DatabaseManager, audioManager: AudioManager) {
        self.databaseManager = databaseManager
        self.audioManager = audioManager
        
        setupBindings()
        loadSounds()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Listen for audio state changes
        audioManager.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaying in
                if !isPlaying {
                    self?.isPreviewPlaying = false
                    self?.previewingSound = nil
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    func loadSounds() {
        isLoading = true
        
        Task {
            do {
                // Fetch all sounds
                let allSounds = databaseManager.fetchAllSounds()
                let favorites = allSounds.filter { $0.isFavorite }
                let selected = databaseManager.fetchSelectedSound()
                
                await MainActor.run {
                    self.sounds = allSounds
                    self.favoriteSounds = favorites
                    self.selectedSound = selected
                    self.isLoading = false
                }
            }
        }
    }
    
    func refreshSounds() {
        loadSounds()
    }
    
    // MARK: - Actions
    func selectSound(_ sound: SoundEntity) {
        // Deselect current sound
        selectedSound?.isSelected = false
        
        // Select new sound
        sound.selectSound()
        selectedSound = sound
        
        // Save changes
        databaseManager.saveContext()
        
        // Stop any preview
        stopPreview()
        
        // Update UI
        objectWillChange.send()
    }
    
    func toggleFavorite(_ sound: SoundEntity) {
        sound.toggleFavorite()
        databaseManager.saveContext()
        
        // Update favorites list
        if sound.isFavorite {
            if !favoriteSounds.contains(sound) {
                favoriteSounds.append(sound)
            }
        } else {
            favoriteSounds.removeAll { $0 == sound }
        }
        
        objectWillChange.send()
    }
    
    func previewSound(_ sound: SoundEntity) {
        // Stop current preview
        stopPreview()
        
        guard let soundURL = sound.soundUrl1 else {
            errorMessage = "Sound file not found"
            return
        }
        
        // Start preview
        previewingSound = sound
        isPreviewPlaying = true
        
        // Play sound with lower volume for preview
        let originalVolume = audioManager.volume
        audioManager.setVolume(originalVolume * 0.7) // Quieter for preview
        
        audioManager.playSound(url: soundURL, loop: false) { [weak self] in
            DispatchQueue.main.async {
                self?.isPreviewPlaying = false
                self?.previewingSound = nil
                self?.audioManager.setVolume(originalVolume) // Restore volume
            }
        }
    }
    
    func stopPreview() {
        if isPreviewPlaying {
            audioManager.stopAllSounds()
            isPreviewPlaying = false
            previewingSound = nil
        }
    }
    
    func toggleFavoritesFilter() {
        showingFavoritesOnly.toggle()
    }
    
    // MARK: - Search
    func clearSearch() {
        searchText = ""
    }
    
    // MARK: - Validation
    func canSelectSound(_ sound: SoundEntity) -> Bool {
        // Check if sound file exists
        guard let soundURL = sound.soundUrl1 else { return false }
        
        // For local files, check if they exist in bundle
        if !soundURL.contains("http") {
            return Bundle.main.path(forResource: soundURL.replacingOccurrences(of: ".mp3", with: ""), ofType: "mp3") != nil
        }
        
        return true
    }
    
    // MARK: - Helper Methods
    func getSoundDuration(_ sound: SoundEntity) -> String {
        // This would require loading the audio file to get duration
        // For now, return a placeholder
        return "Unknown"
    }
    
    func getSoundDescription(_ sound: SoundEntity) -> String {
        guard let title = sound.bTitle else { return "Unknown Sound" }
        
        // Generate description based on sound type
        let descriptions = [
            "rain": "Gentle rainfall for peaceful sleep",
            "ocean": "Calming ocean waves",
            "forest": "Peaceful forest ambiance",
            "thunder": "Distant thunder sounds",
            "wind": "Gentle wind through trees",
            "stream": "Babbling brook sounds",
            "waves": "Rhythmic wave sounds",
            "crickets": "Evening cricket chorus",
            "waterfall": "Cascading water sounds",
            "campfire": "Crackling campfire ambiance"
        ]
        
        for (keyword, description) in descriptions {
            if title.lowercased().contains(keyword) {
                return description
            }
        }
        
        return "Nature sound for relaxation"
    }
}