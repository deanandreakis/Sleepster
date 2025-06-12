//
//  SleepTrackerTests.swift
//  SleepMateTests
//
//  Created by Claude on Phase 6 Migration
//

import XCTest
import HealthKit
@testable import SleepMate

@MainActor
final class SleepTrackerTests: XCTestCase {
    var sleepTracker: SleepTracker!
    
    override func setUp() async throws {
        try await super.setUp()
        sleepTracker = SleepTracker.shared
    }
    
    override func tearDown() async throws {
        sleepTracker = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testSleepTrackerInitialization() throws {
        // Given/When/Then
        XCTAssertNotNil(sleepTracker)
        XCTAssertFalse(sleepTracker.isTracking)
        XCTAssertNil(sleepTracker.currentSleepSession)
        XCTAssertTrue(sleepTracker.recentSleepData.isEmpty)
    }
    
    func testInitialAuthorizationStatus() throws {
        // Given/When/Then
        XCTAssertEqual(sleepTracker.authorizationStatus, .notDetermined)
        XCTAssertFalse(sleepTracker.isAuthorized)
    }
    
    // MARK: - Sleep Session Tests
    
    func testSleepSessionCreation() throws {
        // Given
        let sessionId = UUID()
        let startTime = Date()
        let expectedDuration: TimeInterval = 8 * 60 * 60 // 8 hours
        
        // When
        let session = SleepSession(
            id: sessionId,
            startTime: startTime,
            endTime: nil,
            expectedDuration: expectedDuration,
            soundsUsed: [],
            backgroundUsed: nil,
            audioSettings: AudioSettings(
                masterVolume: 0.5,
                activeSounds: [],
                equalizerPreset: "default",
                effectsEnabled: false
            )
        )
        
        // Then
        XCTAssertEqual(session.id, sessionId)
        XCTAssertEqual(session.startTime, startTime)
        XCTAssertNil(session.endTime)
        XCTAssertEqual(session.expectedDuration, expectedDuration)
        XCTAssertFalse(session.isCompleted)
        XCTAssertNil(session.actualDuration)
    }
    
    func testSleepSessionCompletion() throws {
        // Given
        let session = createTestSleepSession()
        let endTime = Date()
        
        // When
        var completedSession = session
        completedSession.endTime = endTime
        completedSession.actualDuration = endTime.timeIntervalSince(session.startTime)
        
        // Then
        XCTAssertTrue(completedSession.isCompleted)
        XCTAssertNotNil(completedSession.actualDuration)
        XCTAssertEqual(completedSession.actualDuration, endTime.timeIntervalSince(session.startTime))
    }
    
    func testSleepSessionDuration() throws {
        // Given
        let startTime = Date()
        let session = SleepSession(
            id: UUID(),
            startTime: startTime,
            endTime: nil,
            expectedDuration: 8 * 60 * 60,
            soundsUsed: [],
            backgroundUsed: nil,
            audioSettings: AudioSettings(
                masterVolume: 0.5,
                activeSounds: [],
                equalizerPreset: "default",
                effectsEnabled: false
            )
        )
        
        // When
        let currentDuration = session.duration
        
        // Then
        XCTAssertGreaterThan(currentDuration, 0)
        XCTAssertLessThan(currentDuration, 1) // Should be very small since just created
    }
    
    // MARK: - Sleep Data Tests
    
    func testSleepDataCreation() throws {
        // Given
        let sleepDataId = UUID()
        let date = Date()
        let startTime = date
        let endTime = date.addingTimeInterval(8 * 60 * 60) // 8 hours later
        let duration = endTime.timeIntervalSince(startTime)
        
        // When
        let sleepData = SleepData(
            id: sleepDataId,
            date: date,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            category: .asleep,
            source: "SleepMate"
        )
        
        // Then
        XCTAssertEqual(sleepData.id, sleepDataId)
        XCTAssertEqual(sleepData.duration, duration)
        XCTAssertEqual(sleepData.category, .asleep)
        XCTAssertEqual(sleepData.formattedDuration, "8h 0m")
    }
    
    func testSleepDataFormattedDuration() throws {
        // Given
        let sleepData = SleepData(
            id: UUID(),
            date: Date(),
            startTime: Date(),
            endTime: Date().addingTimeInterval(7.5 * 60 * 60), // 7.5 hours
            duration: 7.5 * 60 * 60,
            category: .asleep,
            source: "SleepMate"
        )
        
        // When/Then
        XCTAssertEqual(sleepData.formattedDuration, "7h 30m")
    }
    
    // MARK: - Sleep Insights Tests
    
    func testSleepInsightsCreation() throws {
        // Given
        let averageDuration: TimeInterval = 8 * 60 * 60 // 8 hours
        let efficiency: Double = 85.0
        let consistency: Double = 90.0
        let recommendations = ["Get regular exercise", "Maintain consistent bedtime"]
        
        // When
        let insights = SleepInsights(
            averageSleepDuration: averageDuration,
            sleepEfficiency: efficiency,
            bedtimeConsistency: consistency,
            recommendations: recommendations
        )
        
        // Then
        XCTAssertEqual(insights.averageSleepDuration, averageDuration)
        XCTAssertEqual(insights.sleepEfficiency, efficiency)
        XCTAssertEqual(insights.bedtimeConsistency, consistency)
        XCTAssertEqual(insights.recommendations, recommendations)
        XCTAssertEqual(insights.formattedAverageDuration, "8h 0m")
    }
    
    // MARK: - Statistics Period Tests
    
    func testStatisticsPeriodDateRanges() throws {
        // Given
        let now = Date()
        let calendar = Calendar.current
        
        // When/Then - Week
        let weekRange = StatisticsPeriod.week.dateRange
        let expectedWeekStart = calendar.date(byAdding: .day, value: -7, to: now)!
        XCTAssertEqual(weekRange.start.timeIntervalSince1970, expectedWeekStart.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertEqual(weekRange.end.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 1.0)
        
        // When/Then - Month
        let monthRange = StatisticsPeriod.month.dateRange
        let expectedMonthStart = calendar.date(byAdding: .month, value: -1, to: now)!
        XCTAssertEqual(monthRange.start.timeIntervalSince1970, expectedMonthStart.timeIntervalSince1970, accuracy: 1.0)
        
        // When/Then - Quarter
        let quarterRange = StatisticsPeriod.quarter.dateRange
        let expectedQuarterStart = calendar.date(byAdding: .month, value: -3, to: now)!
        XCTAssertEqual(quarterRange.start.timeIntervalSince1970, expectedQuarterStart.timeIntervalSince1970, accuracy: 1.0)
        
        // When/Then - Year
        let yearRange = StatisticsPeriod.year.dateRange
        let expectedYearStart = calendar.date(byAdding: .year, value: -1, to: now)!
        XCTAssertEqual(yearRange.start.timeIntervalSince1970, expectedYearStart.timeIntervalSince1970, accuracy: 1.0)
    }
    
    // MARK: - Audio Settings Tests
    
    func testAudioSettingsCodable() throws {
        // Given
        let audioSettings = AudioSettings(
            masterVolume: 0.8,
            activeSounds: ["Rain", "Ocean"],
            equalizerPreset: "sleep",
            effectsEnabled: true
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(audioSettings)
        
        let decoder = JSONDecoder()
        let decodedSettings = try decoder.decode(AudioSettings.self, from: data)
        
        // Then
        XCTAssertEqual(decodedSettings.masterVolume, audioSettings.masterVolume)
        XCTAssertEqual(decodedSettings.activeSounds, audioSettings.activeSounds)
        XCTAssertEqual(decodedSettings.equalizerPreset, audioSettings.equalizerPreset)
        XCTAssertEqual(decodedSettings.effectsEnabled, audioSettings.effectsEnabled)
    }
    
    // MARK: - Mock Authorization Tests
    
    func testMockAuthorizationGranted() async throws {
        // Given
        sleepTracker.authorizationStatus = .sharingAuthorized
        sleepTracker.isAuthorized = true
        
        // When/Then
        XCTAssertTrue(sleepTracker.isAuthorized)
        XCTAssertEqual(sleepTracker.authorizationStatus, .sharingAuthorized)
    }
    
    func testMockAuthorizationDenied() async throws {
        // Given
        sleepTracker.authorizationStatus = .sharingDenied
        sleepTracker.isAuthorized = false
        
        // When/Then
        XCTAssertFalse(sleepTracker.isAuthorized)
        XCTAssertEqual(sleepTracker.authorizationStatus, .sharingDenied)
    }
    
    // MARK: - Performance Tests
    
    func testSleepSessionCreationPerformance() throws {
        measure {
            for _ in 0..<1000 {
                _ = createTestSleepSession()
            }
        }
    }
    
    func testSleepDataProcessingPerformance() throws {
        // Given
        let sleepDataArray = createMockSleepDataArray(count: 100)
        
        // When/Then
        measure {
            _ = sleepDataArray.filter { $0.category == .asleep }
            _ = sleepDataArray.reduce(0) { $0 + $1.duration }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestSleepSession() -> SleepSession {
        return SleepSession(
            id: UUID(),
            startTime: Date(),
            endTime: nil,
            expectedDuration: 8 * 60 * 60,
            soundsUsed: ["Rain", "Ocean"],
            backgroundUsed: "Forest",
            audioSettings: AudioSettings(
                masterVolume: 0.5,
                activeSounds: ["Rain", "Ocean"],
                equalizerPreset: "sleep",
                effectsEnabled: true
            )
        )
    }
    
    private func createMockSleepDataArray(count: Int) -> [SleepData] {
        return (0..<count).map { index in
            SleepData(
                id: UUID(),
                date: Date().addingTimeInterval(TimeInterval(-index * 24 * 60 * 60)),
                startTime: Date().addingTimeInterval(TimeInterval(-index * 24 * 60 * 60)),
                endTime: Date().addingTimeInterval(TimeInterval(-index * 24 * 60 * 60) + 8 * 60 * 60),
                duration: 8 * 60 * 60,
                category: .asleep,
                source: "SleepMate"
            )
        }
    }
}