//
//  AudioMixingEngineTests.swift
//  SleepMateTests
//
//  Created by Claude on Phase 6 Migration
//

import XCTest
import AVFoundation
@testable import SleepMate

@MainActor
final class AudioMixingEngineTests: XCTestCase {
    var audioEngine: AudioMixingEngine!
    
    override func setUp() async throws {
        try await super.setUp()
        audioEngine = AudioMixingEngine.shared
    }
    
    override func tearDown() async throws {
        await audioEngine.stopAllSounds()
        audioEngine = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testAudioEngineInitialization() throws {
        // Given/When/Then
        XCTAssertNotNil(audioEngine)
        XCTAssertTrue(audioEngine.activePlayers.isEmpty)
        XCTAssertEqual(audioEngine.masterVolume, 1.0)
        XCTAssertFalse(audioEngine.isAnyPlaying)
    }
    
    func testInitialConfiguration() throws {
        // Given/When/Then
        XCTAssertEqual(audioEngine.maxConcurrentSounds, 5)
        XCTAssertFalse(audioEngine.isEngineRunning)
    }
    
    // MARK: - Volume Control Tests
    
    func testMasterVolumeControl() async throws {
        // Given
        let testVolume: Float = 0.5
        
        // When
        await audioEngine.setMasterVolume(testVolume)
        
        // Then
        XCTAssertEqual(audioEngine.masterVolume, testVolume)
    }
    
    func testVolumeConstraints() async throws {
        // Test minimum volume
        await audioEngine.setMasterVolume(-1.0)
        XCTAssertEqual(audioEngine.masterVolume, 0.0)
        
        // Test maximum volume
        await audioEngine.setMasterVolume(2.0)
        XCTAssertEqual(audioEngine.masterVolume, 1.0)
        
        // Test normal range
        await audioEngine.setMasterVolume(0.75)
        XCTAssertEqual(audioEngine.masterVolume, 0.75)
    }
    
    // MARK: - Sound Player Tests
    
    func testSoundPlayerCreation() throws {
        // Given
        let testSound = createTestSound()
        
        // When
        let player = AudioSoundPlayer(sound: testSound, engine: audioEngine)
        
        // Then
        XCTAssertNotNil(player)
        XCTAssertEqual(player.soundName, testSound.name)
        XCTAssertEqual(player.volume, 1.0)
        XCTAssertFalse(player.isPlaying)
        XCTAssertFalse(player.isMuted)
    }
    
    func testSoundPlayerConfiguration() throws {
        // Given
        let testSound = createTestSound()
        let player = AudioSoundPlayer(sound: testSound, engine: audioEngine)
        
        // When
        player.volume = 0.5
        player.isMuted = true
        
        // Then
        XCTAssertEqual(player.volume, 0.5)
        XCTAssertTrue(player.isMuted)
    }
    
    // MARK: - Mock Sound Loading Tests
    
    func testMockSoundPlayback() async throws {
        // Given
        let testSound = createTestSound()
        
        // When
        await audioEngine.playSound(testSound)
        
        // Then
        XCTAssertEqual(audioEngine.activePlayers.count, 1)
        XCTAssertEqual(audioEngine.activePlayers.first?.soundName, testSound.name)
    }
    
    func testMultipleSoundPlayback() async throws {
        // Given
        let sounds = createMultipleTestSounds(count: 3)
        
        // When
        for sound in sounds {
            await audioEngine.playSound(sound)
        }
        
        // Then
        XCTAssertEqual(audioEngine.activePlayers.count, 3)
        XCTAssertTrue(audioEngine.isAnyPlaying)
    }
    
    func testMaxConcurrentSoundsLimit() async throws {
        // Given
        let sounds = createMultipleTestSounds(count: 10)
        
        // When
        for sound in sounds {
            await audioEngine.playSound(sound)
        }
        
        // Then
        XCTAssertLessThanOrEqual(audioEngine.activePlayers.count, audioEngine.maxConcurrentSounds)
    }
    
    func testStopSpecificSound() async throws {
        // Given
        let testSound = createTestSound()
        await audioEngine.playSound(testSound)
        XCTAssertEqual(audioEngine.activePlayers.count, 1)
        
        // When
        await audioEngine.stopSound(testSound)
        
        // Then
        XCTAssertEqual(audioEngine.activePlayers.count, 0)
        XCTAssertFalse(audioEngine.isAnyPlaying)
    }
    
    func testStopAllSounds() async throws {
        // Given
        let sounds = createMultipleTestSounds(count: 3)
        for sound in sounds {
            await audioEngine.playSound(sound)
        }
        XCTAssertEqual(audioEngine.activePlayers.count, 3)
        
        // When
        await audioEngine.stopAllSounds()
        
        // Then
        XCTAssertEqual(audioEngine.activePlayers.count, 0)
        XCTAssertFalse(audioEngine.isAnyPlaying)
    }
    
    // MARK: - Sound Volume Tests
    
    func testIndividualSoundVolumeControl() async throws {
        // Given
        let testSound = createTestSound()
        await audioEngine.playSound(testSound)
        let player = audioEngine.activePlayers.first!
        
        // When
        await audioEngine.setSoundVolume(testSound, volume: 0.3)
        
        // Then
        XCTAssertEqual(player.volume, 0.3)
    }
    
    func testSoundMuting() async throws {
        // Given
        let testSound = createTestSound()
        await audioEngine.playSound(testSound)
        let player = audioEngine.activePlayers.first!
        
        // When
        await audioEngine.muteSounds([testSound])
        
        // Then
        XCTAssertTrue(player.isMuted)
        
        // When
        await audioEngine.unmuteSounds([testSound])
        
        // Then
        XCTAssertFalse(player.isMuted)
    }
    
    // MARK: - Fade Effects Tests
    
    func testFadeInEffect() async throws {
        // Given
        let testSound = createTestSound()
        
        // When
        await audioEngine.playSound(testSound)
        await audioEngine.fadeIn(testSound, duration: 0.1) // Short duration for testing
        
        // Then
        let player = audioEngine.activePlayers.first
        XCTAssertNotNil(player)
        // Volume should be set by fade effect
    }
    
    func testFadeOutEffect() async throws {
        // Given
        let testSound = createTestSound()
        await audioEngine.playSound(testSound)
        
        // When
        await audioEngine.fadeOut(testSound, duration: 0.1) // Short duration for testing
        
        // Then
        // Player should be removed after fade out completes
        try await Task.sleep(nanoseconds: 200_000_000) // Wait for fade to complete
        XCTAssertEqual(audioEngine.activePlayers.count, 0)
    }
    
    func testCrossfadeEffect() async throws {
        // Given
        let sound1 = createTestSound(name: "Sound1")
        let sound2 = createTestSound(name: "Sound2")
        
        await audioEngine.playSound(sound1)
        XCTAssertEqual(audioEngine.activePlayers.count, 1)
        
        // When
        await audioEngine.crossfade(from: sound1, to: sound2, duration: 0.1)
        
        // Then
        try await Task.sleep(nanoseconds: 200_000_000) // Wait for crossfade to complete
        XCTAssertEqual(audioEngine.activePlayers.count, 1)
        XCTAssertEqual(audioEngine.activePlayers.first?.soundName, sound2.name)
    }
    
    // MARK: - Audio Session Tests
    
    func testEngineStartStop() async throws {
        // Given
        XCTAssertFalse(audioEngine.isEngineRunning)
        
        // When
        await audioEngine.startEngine()
        
        // Then
        XCTAssertTrue(audioEngine.isEngineRunning)
        
        // When
        await audioEngine.stopEngine()
        
        // Then
        XCTAssertFalse(audioEngine.isEngineRunning)
    }
    
    // MARK: - Error Handling Tests
    
    func testPlayInvalidSound() async throws {
        // Given
        let invalidSound = Sound(
            id: UUID(),
            name: "Invalid",
            filename: "nonexistent.mp3",
            category: .nature,
            duration: 0,
            isPremium: false
        )
        
        // When
        await audioEngine.playSound(invalidSound)
        
        // Then
        // Should handle gracefully without crashing
        XCTAssertEqual(audioEngine.activePlayers.count, 0)
    }
    
    func testStopNonPlayingSound() async throws {
        // Given
        let testSound = createTestSound()
        
        // When/Then - Should not crash
        await audioEngine.stopSound(testSound)
        XCTAssertEqual(audioEngine.activePlayers.count, 0)
    }
    
    // MARK: - Performance Tests
    
    func testSoundPlaybackPerformance() throws {
        let sounds = createMultipleTestSounds(count: 5)
        
        measure {
            Task {
                for sound in sounds {
                    await audioEngine.playSound(sound)
                }
                await audioEngine.stopAllSounds()
            }
        }
    }
    
    func testVolumeControlPerformance() throws {
        let testSound = createTestSound()
        
        measure {
            Task {
                await audioEngine.playSound(testSound)
                for i in 0..<100 {
                    let volume = Float(i) / 100.0
                    await audioEngine.setSoundVolume(testSound, volume: volume)
                }
                await audioEngine.stopSound(testSound)
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
                isPremium: false
            )
        }
    }
}