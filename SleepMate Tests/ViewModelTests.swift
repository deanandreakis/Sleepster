//
//  ViewModelTests.swift
//  SleepMateTests
//
//  Created by Claude on Phase 6 Migration
//

import XCTest
import SwiftUI
@testable import SleepMate

@MainActor
final class ViewModelTests: XCTestCase {
    
    // MARK: - SoundsViewModel Tests
    
    func testSoundsViewModelInitialization() throws {
        // Given/When
        let viewModel = SoundsViewModel()
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.sounds.isEmpty)
        XCTAssertTrue(viewModel.selectedSounds.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testSoundsViewModelSoundSelection() throws {
        // Given
        let viewModel = SoundsViewModel()
        let testSound = createTestSound()
        viewModel.sounds = [testSound]
        
        // When
        viewModel.toggleSoundSelection(testSound)
        
        // Then
        XCTAssertTrue(viewModel.selectedSounds.contains(testSound.id))
        XCTAssertTrue(viewModel.isSelected(testSound))
        
        // When - toggle again
        viewModel.toggleSoundSelection(testSound)
        
        // Then
        XCTAssertFalse(viewModel.selectedSounds.contains(testSound.id))
        XCTAssertFalse(viewModel.isSelected(testSound))
    }
    
    func testSoundsViewModelPlaybackControl() async throws {
        // Given
        let viewModel = SoundsViewModel()
        let testSound = createTestSound()
        
        // When
        await viewModel.playSound(testSound)
        
        // Then
        XCTAssertTrue(viewModel.playingSounds.contains(testSound.id))
        XCTAssertTrue(viewModel.isPlaying(testSound))
        
        // When
        await viewModel.stopSound(testSound)
        
        // Then
        XCTAssertFalse(viewModel.playingSounds.contains(testSound.id))
        XCTAssertFalse(viewModel.isPlaying(testSound))
    }
    
    func testSoundsViewModelStopAll() async throws {
        // Given
        let viewModel = SoundsViewModel()
        let sounds = createMultipleTestSounds(count: 3)
        
        for sound in sounds {
            await viewModel.playSound(sound)
        }
        XCTAssertEqual(viewModel.playingSounds.count, 3)
        
        // When
        await viewModel.stopAllSounds()
        
        // Then
        XCTAssertTrue(viewModel.playingSounds.isEmpty)
        XCTAssertFalse(viewModel.isAnyPlaying)
    }
    
    // MARK: - BackgroundsViewModel Tests
    
    func testBackgroundsViewModelInitialization() throws {
        // Given/When
        let viewModel = BackgroundsViewModel()
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.backgrounds.isEmpty)
        XCTAssertNil(viewModel.selectedBackground)
        XCTAssertTrue(viewModel.searchText.isEmpty)
    }
    
    func testBackgroundsViewModelSearch() async throws {
        // Given
        let viewModel = BackgroundsViewModel()
        let searchQuery = "forest"
        
        // When
        viewModel.searchText = searchQuery
        await viewModel.searchBackgrounds()
        
        // Then
        XCTAssertEqual(viewModel.searchText, searchQuery)
        // Note: In test environment, search results would be mocked
    }
    
    func testBackgroundsViewModelSelection() throws {
        // Given
        let viewModel = BackgroundsViewModel()
        let testBackground = createTestBackground()
        
        // When
        viewModel.selectBackground(testBackground)
        
        // Then
        XCTAssertEqual(viewModel.selectedBackground?.id, testBackground.id)
    }
    
    // MARK: - TimerViewModel Tests
    
    func testTimerViewModelInitialization() throws {
        // Given/When
        let viewModel = TimerViewModel()
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.isTimerActive)
        XCTAssertEqual(viewModel.selectedDuration, 30 * 60) // 30 minutes default
        XCTAssertEqual(viewModel.timeRemaining, 0)
    }
    
    func testTimerViewModelDurationSelection() throws {
        // Given
        let viewModel = TimerViewModel()
        let newDuration: TimeInterval = 60 * 60 // 1 hour
        
        // When
        viewModel.selectedDuration = newDuration
        
        // Then
        XCTAssertEqual(viewModel.selectedDuration, newDuration)
        XCTAssertEqual(viewModel.formattedSelectedDuration, "60:00")
    }
    
    func testTimerViewModelStartStop() async throws {
        // Given
        let viewModel = TimerViewModel()
        viewModel.selectedDuration = 10 // 10 seconds for testing
        
        // When
        await viewModel.startTimer()
        
        // Then
        XCTAssertTrue(viewModel.isTimerActive)
        XCTAssertGreaterThan(viewModel.timeRemaining, 0)
        
        // When
        await viewModel.stopTimer()
        
        // Then
        XCTAssertFalse(viewModel.isTimerActive)
        XCTAssertEqual(viewModel.timeRemaining, 0)
    }
    
    func testTimerViewModelFormatting() throws {
        // Given
        let viewModel = TimerViewModel()
        
        // Test various time formats
        XCTAssertEqual(viewModel.formatTime(3661), "61:01") // 1 hour, 1 minute, 1 second
        XCTAssertEqual(viewModel.formatTime(3600), "60:00") // 1 hour
        XCTAssertEqual(viewModel.formatTime(61), "1:01") // 1 minute, 1 second
        XCTAssertEqual(viewModel.formatTime(59), "0:59") // 59 seconds
        XCTAssertEqual(viewModel.formatTime(0), "0:00") // 0 seconds
    }
    
    // MARK: - SettingsViewModel Tests
    
    func testSettingsViewModelInitialization() throws {
        // Given/When
        let viewModel = SettingsViewModel()
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.notificationsEnabled)
        XCTAssertFalse(viewModel.darkModeEnabled)
        XCTAssertFalse(viewModel.hapticFeedbackEnabled)
        XCTAssertEqual(viewModel.audioQuality, .high)
    }
    
    func testSettingsViewModelToggleSettings() throws {
        // Given
        let viewModel = SettingsViewModel()
        
        // When
        viewModel.notificationsEnabled = true
        viewModel.darkModeEnabled = true
        viewModel.hapticFeedbackEnabled = true
        
        // Then
        XCTAssertTrue(viewModel.notificationsEnabled)
        XCTAssertTrue(viewModel.darkModeEnabled)
        XCTAssertTrue(viewModel.hapticFeedbackEnabled)
    }
    
    func testSettingsViewModelAudioQuality() throws {
        // Given
        let viewModel = SettingsViewModel()
        
        // When
        viewModel.audioQuality = .medium
        
        // Then
        XCTAssertEqual(viewModel.audioQuality, .medium)
        
        // When
        viewModel.audioQuality = .low
        
        // Then
        XCTAssertEqual(viewModel.audioQuality, .low)
    }
    
    // MARK: - Performance Tests
    
    func testSoundsViewModelPerformance() throws {
        let viewModel = SoundsViewModel()
        let sounds = createMultipleTestSounds(count: 100)
        
        measure {
            viewModel.sounds = sounds
            for sound in sounds.prefix(10) {
                viewModel.toggleSoundSelection(sound)
            }
        }
    }
    
    func testBackgroundsViewModelPerformance() throws {
        let viewModel = BackgroundsViewModel()
        let backgrounds = createMultipleTestBackgrounds(count: 100)
        
        measure {
            viewModel.backgrounds = backgrounds
            for background in backgrounds.prefix(10) {
                viewModel.selectBackground(background)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestSound(name: String = "TestSound") -> Sound {
        return Sound(
            id: UUID(),
            name: name,
            filename: "test.mp3",
            category: .nature,
            duration: 60.0,
            isPremium: false
        )
    }
    
    private func createMultipleTestSounds(count: Int) -> [Sound] {
        return (0..<count).map { index in
            Sound(
                id: UUID(),
                name: "TestSound\(index)",
                filename: "test\(index).mp3",
                category: .nature,
                duration: 60.0,
                isPremium: index % 3 == 0 // Every 3rd sound is premium
            )
        }
    }
    
    private func createTestBackground(name: String = "TestBackground") -> Background {
        return Background(
            id: UUID(),
            name: name,
            thumbnailURL: "https://example.com/thumb.jpg",
            fullImageURL: "https://example.com/full.jpg",
            category: .nature,
            isPremium: false
        )
    }
    
    private func createMultipleTestBackgrounds(count: Int) -> [Background] {
        return (0..<count).map { index in
            Background(
                id: UUID(),
                name: "TestBackground\(index)",
                thumbnailURL: "https://example.com/thumb\(index).jpg",
                fullImageURL: "https://example.com/full\(index).jpg",
                category: .nature,
                isPremium: index % 4 == 0 // Every 4th background is premium
            )
        }
    }
}

// MARK: - Mock ViewModels for Testing

class MockSoundsViewModel: ObservableObject {
    @Published var sounds: [Sound] = []
    @Published var selectedSounds: Set<UUID> = []
    @Published var playingSounds: Set<UUID> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var isAnyPlaying: Bool {
        !playingSounds.isEmpty
    }
    
    func isSelected(_ sound: Sound) -> Bool {
        selectedSounds.contains(sound.id)
    }
    
    func isPlaying(_ sound: Sound) -> Bool {
        playingSounds.contains(sound.id)
    }
    
    func toggleSoundSelection(_ sound: Sound) {
        if selectedSounds.contains(sound.id) {
            selectedSounds.remove(sound.id)
        } else {
            selectedSounds.insert(sound.id)
        }
    }
    
    func playSound(_ sound: Sound) async {
        playingSounds.insert(sound.id)
    }
    
    func stopSound(_ sound: Sound) async {
        playingSounds.remove(sound.id)
    }
    
    func stopAllSounds() async {
        playingSounds.removeAll()
    }
}

class MockTimerViewModel: ObservableObject {
    @Published var isTimerActive = false
    @Published var selectedDuration: TimeInterval = 30 * 60
    @Published var timeRemaining: TimeInterval = 0
    
    var formattedSelectedDuration: String {
        formatTime(selectedDuration)
    }
    
    var formattedTimeRemaining: String {
        formatTime(timeRemaining)
    }
    
    func startTimer() async {
        isTimerActive = true
        timeRemaining = selectedDuration
    }
    
    func stopTimer() async {
        isTimerActive = false
        timeRemaining = 0
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}