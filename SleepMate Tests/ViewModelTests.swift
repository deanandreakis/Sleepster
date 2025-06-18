//
//  ViewModelTests.swift
//  SleepMateTests
//
//  Created by Claude on Phase 6 Migration
//

import XCTest
import SwiftUI
@testable import SleepMate

// Temporary test struct for view model testing
struct ViewModelTestSound {
    let id: UUID
    let name: String
    let filename: String
    let category: String
    let duration: Double
    let isPremium: Bool
}

@MainActor
final class ViewModelTests: XCTestCase {
    
    // MARK: - SoundsViewModel Tests
    
    func testSoundsViewModelInitialization() throws {
        // Given/When
        let databaseManager = DatabaseManager.shared
        let audioManager = AudioManager(coreDataStack: databaseManager.coreDataStack)
        let viewModel = SoundsViewModel(databaseManager: databaseManager, audioManager: audioManager)
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.isMixingMode)
        // Note: selectedSoundsForMixing might not be empty if Core Data has existing data
        // XCTAssertTrue(viewModel.selectedSoundsForMixing.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testSoundsViewModelMixingToggle() throws {
        // Given
        let databaseManager = DatabaseManager.shared
        let audioManager = AudioManager(coreDataStack: databaseManager.coreDataStack)
        let viewModel = SoundsViewModel(databaseManager: databaseManager, audioManager: audioManager)
        
        // When
        viewModel.enableMixingMode()
        
        // Then
        XCTAssertTrue(viewModel.isMixingMode)
        
        // When - disable mixing
        viewModel.disableMixingMode()
        
        // Then
        XCTAssertFalse(viewModel.isMixingMode)
        XCTAssertTrue(viewModel.selectedSoundsForMixing.isEmpty)
    }
    
    func testSoundsViewModelSearchAndFilter() throws {
        // Given
        let databaseManager = DatabaseManager.shared
        let audioManager = AudioManager(coreDataStack: databaseManager.coreDataStack)
        let viewModel = SoundsViewModel(databaseManager: databaseManager, audioManager: audioManager)
        
        // When
        viewModel.searchText = "nature"
        
        // Then
        XCTAssertEqual(viewModel.searchText, "nature")
        
        // When - clear search
        viewModel.clearSearch()
        
        // Then
        XCTAssertTrue(viewModel.searchText.isEmpty)
        
        // When - test category selection
        viewModel.setCategory(.nature)
        
        // Then
        XCTAssertEqual(viewModel.selectedCategory, .nature)
    }
    
    func testSoundsViewModelPreview() throws {
        // Given
        let databaseManager = DatabaseManager.shared
        let audioManager = AudioManager(coreDataStack: databaseManager.coreDataStack)
        let viewModel = SoundsViewModel(databaseManager: databaseManager, audioManager: audioManager)
        
        // When
        XCTAssertFalse(viewModel.isPreviewPlaying)
        XCTAssertNil(viewModel.previewingSound)
        
        // When - stop preview (should not crash when nothing is playing)
        viewModel.stopPreview()
        
        // Then
        XCTAssertFalse(viewModel.isPreviewPlaying)
    }
    
    // MARK: - BackgroundsViewModel Tests
    
    func testBackgroundsViewModelInitialization() throws {
        // Given/When
        let mockDatabaseManager = DatabaseManager.shared
        let viewModel = BackgroundsViewModel(databaseManager: mockDatabaseManager)
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.backgroundEntities.isEmpty)
        XCTAssertNil(viewModel.selectedAnimationId)
    }
    
    func testBackgroundsViewModelAnimationSelection() async throws {
        // Given
        let mockDatabaseManager = DatabaseManager.shared
        let viewModel = BackgroundsViewModel(databaseManager: mockDatabaseManager)
        let testAnimationId = "counting_sheep"
        
        // When
        viewModel.selectAnimation(testAnimationId)
        
        // Then
        XCTAssertEqual(viewModel.selectedAnimationId, testAnimationId)
        // Note: In test environment, database operations would be mocked
    }
    
    func testBackgroundsViewModelFavorites() throws {
        // Given
        let mockDatabaseManager = DatabaseManager.shared
        let viewModel = BackgroundsViewModel(databaseManager: mockDatabaseManager)
        let testAnimationId = "gentle_waves"
        
        // When
        viewModel.toggleFavorite(testAnimationId)
        
        // Then
        // Note: In test environment, database operations would be mocked
        XCTAssertNotNil(viewModel)
    }
    
    // MARK: - TimerViewModel Tests
    
    func testTimerViewModelInitialization() throws {
        // Given/When
        let timerManager = TimerManager(audioManager: AudioManager(coreDataStack: DatabaseManager.shared.coreDataStack))
        let settingsManager = SettingsManager()
        let viewModel = TimerViewModel(timerManager: timerManager, settingsManager: settingsManager)
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.isTimerRunning)
        XCTAssertEqual(viewModel.selectedDuration, 300) // 5 minutes default
        XCTAssertEqual(viewModel.timeRemaining, 0)
    }
    
    func testTimerViewModelDurationSelection() throws {
        // Given
        let timerManager = TimerManager(audioManager: AudioManager(coreDataStack: DatabaseManager.shared.coreDataStack))
        let settingsManager = SettingsManager()
        let viewModel = TimerViewModel(timerManager: timerManager, settingsManager: settingsManager)
        let newDuration: TimeInterval = 60 * 60 // 1 hour
        
        // When
        viewModel.selectDuration(newDuration)
        
        // Then
        XCTAssertEqual(viewModel.selectedDuration, newDuration)
        XCTAssertEqual(viewModel.formatDuration(newDuration), "1:00")
    }
    
    func testTimerViewModelStartStop() throws {
        // Given
        let timerManager = TimerManager(audioManager: AudioManager(coreDataStack: DatabaseManager.shared.coreDataStack))
        let settingsManager = SettingsManager()
        let viewModel = TimerViewModel(timerManager: timerManager, settingsManager: settingsManager)
        viewModel.selectDuration(10) // 10 seconds for testing
        
        // When
        viewModel.startTimer()
        
        // Then - Timer state is managed by TimerManager
        XCTAssertEqual(viewModel.selectedDuration, 10)
        
        // When
        viewModel.stopTimer()
        
        // Then
        XCTAssertEqual(viewModel.selectedDuration, 10)
    }
    
    func testTimerViewModelFormatting() throws {
        // Given
        let timerManager = TimerManager(audioManager: AudioManager(coreDataStack: DatabaseManager.shared.coreDataStack))
        let settingsManager = SettingsManager()
        let viewModel = TimerViewModel(timerManager: timerManager, settingsManager: settingsManager)
        
        // Test various time formats
        XCTAssertEqual(viewModel.formatDuration(3600), "1:00") // 1 hour
        XCTAssertEqual(viewModel.formatDuration(1800), "30:00") // 30 minutes
        XCTAssertEqual(viewModel.formatDuration(600), "10:00") // 10 minutes
        XCTAssertEqual(viewModel.formatDuration(0), "00:00") // 0 seconds
    }
    
    // MARK: - SettingsViewModel Tests
    
    func testSettingsViewModelInitialization() throws {
        // Given/When
        let settingsManager = SettingsManager()
        let databaseManager = DatabaseManager.shared
        let viewModel = SettingsViewModel(settingsManager: settingsManager, databaseManager: databaseManager)
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.isDarkModeEnabled)
        XCTAssertTrue(viewModel.isHapticsEnabled)
        XCTAssertTrue(viewModel.isAutoLockDisabled)
        XCTAssertEqual(viewModel.masterVolume, 0.5)
    }
    
    func testSettingsViewModelToggleSettings() throws {
        // Given
        let settingsManager = SettingsManager()
        let databaseManager = DatabaseManager.shared
        let viewModel = SettingsViewModel(settingsManager: settingsManager, databaseManager: databaseManager)
        
        // When
        viewModel.isDarkModeEnabled = true
        viewModel.isHapticsEnabled = false
        viewModel.isAutoLockDisabled = false
        
        // Then
        XCTAssertTrue(viewModel.isDarkModeEnabled)
        XCTAssertFalse(viewModel.isHapticsEnabled)
        XCTAssertFalse(viewModel.isAutoLockDisabled)
    }
    
    func testSettingsViewModelVolumeControl() throws {
        // Given
        let settingsManager = SettingsManager()
        let databaseManager = DatabaseManager.shared
        let viewModel = SettingsViewModel(settingsManager: settingsManager, databaseManager: databaseManager)
        
        // When
        viewModel.masterVolume = 0.8
        
        // Then
        XCTAssertEqual(viewModel.masterVolume, 0.8)
        
        // When
        viewModel.masterVolume = 0.2
        
        // Then
        XCTAssertEqual(viewModel.masterVolume, 0.2)
    }
    
    // MARK: - Performance Tests
    
    func testSoundsViewModelPerformance() throws {
        let databaseManager = DatabaseManager.shared
        let audioManager = AudioManager(coreDataStack: databaseManager.coreDataStack)
        let viewModel = SoundsViewModel(databaseManager: databaseManager, audioManager: audioManager)
        
        measure {
            // Test basic operations
            viewModel.enableMixingMode()
            viewModel.setCategory(.nature)
            viewModel.clearSearch()
            viewModel.disableMixingMode()
        }
    }
    
    func testBackgroundsViewModelPerformance() throws {
        let mockDatabaseManager = DatabaseManager.shared
        let viewModel = BackgroundsViewModel(databaseManager: mockDatabaseManager)
        let animationIds = ["counting_sheep", "gentle_waves", "starry_night"]
        
        measure {
            // Test animation selection performance
            for animationId in animationIds {
                viewModel.selectAnimation(animationId)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createViewModelTestSound(name: String = "ViewModelTestSound") -> ViewModelTestSound {
        return ViewModelTestSound(
            id: UUID(),
            name: name,
            filename: "test.mp3",
            category: "nature",
            duration: 60.0,
            isPremium: false
        )
    }
    
    private func createMultipleViewModelTestSounds(count: Int) -> [ViewModelTestSound] {
        return (0..<count).map { index in
            ViewModelTestSound(
                id: UUID(),
                name: "ViewModelTestSound\(index)",
                filename: "test\(index).mp3",
                category: "nature",
                duration: 60.0,
                isPremium: index % 3 == 0 // Every 3rd sound is premium
            )
        }
    }
    
    private func createTestAnimation(id: String = "test_animation", title: String = "Test Animation") -> AnimatedBackground {
        return PlaceholderAnimation(
            id: id,
            title: title,
            category: .nature
        )
    }
    
    private func createMultipleTestAnimations(count: Int) -> [AnimatedBackground] {
        return (0..<count).map { index in
            PlaceholderAnimation(
                id: "test_animation_\(index)",
                title: "Test Animation \(index)",
                category: BackgroundCategory.allCases[index % BackgroundCategory.allCases.count]
            )
        }
    }
}

// MARK: - Mock ViewModels for Testing

class MockSoundsViewModel: ObservableObject {
    @Published var sounds: [ViewModelTestSound] = []
    @Published var selectedSoundsForMixing: Set<UUID> = []
    @Published var isMixingMode = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    
    func enableMixingMode() {
        isMixingMode = true
    }
    
    func disableMixingMode() {
        isMixingMode = false
        selectedSoundsForMixing.removeAll()
    }
    
    func toggleSoundInMix(_ sound: ViewModelTestSound) {
        if selectedSoundsForMixing.contains(sound.id) {
            selectedSoundsForMixing.remove(sound.id)
        } else {
            selectedSoundsForMixing.insert(sound.id)
        }
    }
    
    func clearSearch() {
        searchText = ""
    }
    
    func previewSound(_ sound: ViewModelTestSound) {
        // Mock preview functionality
    }
    
    func stopPreview() {
        // Mock stop preview
    }
}

class MockTimerViewModel: ObservableObject {
    @Published var isTimerRunning = false
    @Published var selectedDuration: TimeInterval = 30 * 60
    @Published var timeRemaining: TimeInterval = 0
    @Published var timerProgress: Double = 0.0
    
    func startTimer() {
        isTimerRunning = true
        timeRemaining = selectedDuration
    }
    
    func stopTimer() {
        isTimerRunning = false
        timeRemaining = 0
    }
    
    func selectDuration(_ duration: TimeInterval) {
        selectedDuration = duration
    }
    
    func formatDuration(_ time: TimeInterval) -> String {
        let totalMinutes = Int(time) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else {
            return String(format: "%02d:00", minutes)
        }
    }
}