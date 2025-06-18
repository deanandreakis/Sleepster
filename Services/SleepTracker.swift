//
//  SleepTracker.swift
//  SleepMate
//
//  Created by Claude on Phase 5 Migration
//

import HealthKit
import Foundation
import Combine

/// Comprehensive sleep tracking using HealthKit
@MainActor
class SleepTracker: ObservableObject {
    static let shared = SleepTracker()
    
    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var isTracking = false
    @Published var currentSleepSession: SleepSession?
    @Published var recentSleepData: [SleepData] = []
    @Published var sleepInsights: SleepInsights?
    
    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    private var cancellables = Set<AnyCancellable>()
    
    // HealthKit types we need
    private let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    private let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
    private let respiratoryRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
    
    private init() {
        setupHealthKitObservers()
    }
    
    // MARK: - Public Methods
    
    /// Request HealthKit authorization
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            sleepAnalysisType,
            heartRateType,
            respiratoryRateType
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            sleepAnalysisType
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            
            authorizationStatus = healthStore.authorizationStatus(for: sleepAnalysisType)
            isAuthorized = authorizationStatus == .sharingAuthorized
            
            if isAuthorized {
                await loadRecentSleepData()
                await generateSleepInsights()
            }
            
        } catch {
            print("HealthKit authorization failed: \(error)")
        }
    }
    
    /// Start sleep tracking session
    func startSleepTracking() async {
        guard isAuthorized else {
            await requestAuthorization()
            return
        }
        
        let session = SleepSession(
            id: UUID(),
            startTime: Date(),
            endTime: nil,
            expectedDuration: 8 * 60 * 60, // 8 hours
            soundsUsed: [],
            backgroundUsed: nil,
            audioSettings: getCurrentAudioSettings()
        )
        
        currentSleepSession = session
        isTracking = true
        
        // Save sleep analysis to HealthKit
        await saveSleepAnalysis(session, category: .inBed)
        
        // Post notification for other app components
        NotificationCenter.default.post(
            name: NSNotification.Name("SleepTrackingStarted"),
            object: nil,
            userInfo: ["sessionId": session.id.uuidString]
        )
    }
    
    /// Stop sleep tracking session
    func stopSleepTracking() async {
        guard var session = currentSleepSession else { return }
        
        session.endTime = Date()
        session.actualDuration = session.endTime!.timeIntervalSince(session.startTime)
        
        currentSleepSession = session
        isTracking = false
        
        // Save final sleep analysis to HealthKit
        await saveSleepAnalysis(session, category: .asleep)
        
        // Store session locally
        await storeSleepSession(session)
        
        // Update insights
        await generateSleepInsights()
        
        // Clear current session
        currentSleepSession = nil
        
        // Post notification
        NotificationCenter.default.post(
            name: NSNotification.Name("SleepTrackingStopped"),
            object: nil,
            userInfo: ["sessionId": session.id.uuidString, "duration": session.actualDuration ?? 0]
        )
    }
    
    /// Load recent sleep data from HealthKit
    func loadRecentSleepData() async {
        guard isAuthorized else { return }
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: sleepAnalysisType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            
            if let error = error {
                print("Error fetching sleep data: \(error)")
                return
            }
            
            guard let sleepSamples = samples as? [HKCategorySample] else { return }
            
            Task { @MainActor in
                self?.processSleepSamples(sleepSamples)
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Get sleep statistics for a specific period
    func getSleepStatistics(for period: StatisticsPeriod) async -> SleepStatistics? {
        guard isAuthorized else { return nil }
        
        let (startDate, endDate) = period.dateRange
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepAnalysisType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                
                if let error = error {
                    print("Error fetching sleep statistics: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                Task { @MainActor in
                    let statistics = self.calculateSleepStatistics(from: sleepSamples, period: period)
                    continuation.resume(returning: statistics)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupHealthKitObservers() {
        // Observe HealthKit authorization changes
        NotificationCenter.default
            .publisher(for: .HKUserPreferencesDidChange)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.requestAuthorization()
                }
            }
            .store(in: &cancellables)
    }
    
    private func saveSleepAnalysis(_ session: SleepSession, category: HKCategoryValueSleepAnalysis) async {
        let endTime = session.endTime ?? Date()
        
        let sleepSample = HKCategorySample(
            type: sleepAnalysisType,
            value: category.rawValue,
            start: session.startTime,
            end: endTime,
            metadata: [
                HKMetadataKeyWasUserEntered: true,
                "SleepsterSessionId": session.id.uuidString
            ]
        )
        
        do {
            try await healthStore.save(sleepSample)
        } catch {
            print("Failed to save sleep analysis: \(error)")
        }
    }
    
    private func storeSleepSession(_ session: SleepSession) async {
        // Store session in UserDefaults for local access
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if (try? encoder.encode(session)) != nil {
            var sessions = getStoredSessions()
            sessions.append(session)
            
            // Keep only last 100 sessions
            if sessions.count > 100 {
                sessions = Array(sessions.suffix(100))
            }
            
            if let sessionsData = try? encoder.encode(sessions) {
                UserDefaults.standard.set(sessionsData, forKey: "StoredSleepSessions")
            }
        }
    }
    
    private func getStoredSessions() -> [SleepSession] {
        guard let data = UserDefaults.standard.data(forKey: "StoredSleepSessions") else {
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return (try? decoder.decode([SleepSession].self, from: data)) ?? []
    }
    
    private func processSleepSamples(_ samples: [HKCategorySample]) {
        let sleepData = samples.compactMap { sample -> SleepData? in
            guard let sleepValue = HKCategoryValueSleepAnalysis(rawValue: sample.value) else {
                return nil
            }
            
            return SleepData(
                id: sample.uuid,
                date: sample.startDate,
                startTime: sample.startDate,
                endTime: sample.endDate,
                duration: sample.endDate.timeIntervalSince(sample.startDate),
                category: sleepValue,
                source: sample.sourceRevision.source.name
            )
        }
        
        recentSleepData = sleepData
    }
    
    private func generateSleepInsights() async {
        guard !recentSleepData.isEmpty else { return }
        
        let insights = SleepInsights(
            averageSleepDuration: calculateAverageSleepDuration(),
            sleepEfficiency: calculateSleepEfficiency(),
            bedtimeConsistency: calculateBedtimeConsistency(),
            recommendations: generateRecommendations()
        )
        
        sleepInsights = insights
    }
    
    private func calculateAverageSleepDuration() -> TimeInterval {
        let asleepData = recentSleepData.filter { $0.category == .asleep }
        guard !asleepData.isEmpty else { return 0 }
        
        let totalDuration = asleepData.reduce(0) { $0 + $1.duration }
        return totalDuration / Double(asleepData.count)
    }
    
    private func calculateSleepEfficiency() -> Double {
        let asleepData = recentSleepData.filter { $0.category == .asleep }
        let inBedData = recentSleepData.filter { $0.category == .inBed }
        
        guard !asleepData.isEmpty, !inBedData.isEmpty else { return 0 }
        
        let totalAsleepTime = asleepData.reduce(0) { $0 + $1.duration }
        let totalInBedTime = inBedData.reduce(0) { $0 + $1.duration }
        
        return totalInBedTime > 0 ? (totalAsleepTime / totalInBedTime) * 100 : 0
    }
    
    private func calculateBedtimeConsistency() -> Double {
        let bedtimes = recentSleepData
            .filter { $0.category == .inBed }
            .map { Calendar.current.component(.hour, from: $0.startTime) }
        
        guard bedtimes.count > 1 else { return 100 }
        
        let average = bedtimes.reduce(0, +) / bedtimes.count
        let variance = bedtimes.reduce(0) { sum, bedtime in
            sum + pow(Double(bedtime - average), 2)
        } / Double(bedtimes.count)
        
        let standardDeviation = sqrt(variance)
        
        // Convert to consistency percentage (lower deviation = higher consistency)
        return max(0, 100 - (standardDeviation * 10))
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        let avgDuration = calculateAverageSleepDuration()
        let efficiency = calculateSleepEfficiency()
        let consistency = calculateBedtimeConsistency()
        
        if avgDuration < 7 * 3600 { // Less than 7 hours
            recommendations.append("Try to get at least 7-9 hours of sleep per night")
        }
        
        if efficiency < 80 {
            recommendations.append("Consider adjusting your sleep environment to improve sleep efficiency")
        }
        
        if consistency < 70 {
            recommendations.append("Try to maintain a consistent bedtime schedule")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Great job! Your sleep patterns look healthy")
        }
        
        return recommendations
    }
    
    private func calculateSleepStatistics(from samples: [HKCategorySample], period: StatisticsPeriod) -> SleepStatistics {
        let asleepSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.asleep.rawValue }
        let inBedSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.inBed.rawValue }
        
        let totalSleepTime = asleepSamples.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        let totalInBedTime = inBedSamples.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        
        let avgSleepTime = asleepSamples.isEmpty ? 0 : totalSleepTime / Double(asleepSamples.count)
        let efficiency = totalInBedTime > 0 ? (totalSleepTime / totalInBedTime) * 100 : 0
        
        return SleepStatistics(
            period: period,
            totalSleepTime: totalSleepTime,
            averageSleepTime: avgSleepTime,
            sleepEfficiency: efficiency,
            numberOfSessions: asleepSamples.count
        )
    }
    
    private func getCurrentAudioSettings() -> AudioSettings {
        return AudioSettings(
            masterVolume: AudioMixingEngine.shared.masterVolume,
            activeSounds: AudioMixingEngine.shared.activePlayers.map { $0.soundName },
            equalizerPreset: AudioEqualizer.shared.currentPreset.rawValue,
            effectsEnabled: AudioEffectsProcessor.shared.reverbEnabled || AudioEffectsProcessor.shared.delayEnabled
        )
    }
}

// MARK: - Supporting Types

struct SleepSession: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    let expectedDuration: TimeInterval
    var actualDuration: TimeInterval?
    var soundsUsed: [String]
    var backgroundUsed: String?
    let audioSettings: AudioSettings
    
    var duration: TimeInterval {
        return actualDuration ?? (endTime?.timeIntervalSince(startTime) ?? Date().timeIntervalSince(startTime))
    }
    
    var isCompleted: Bool {
        return endTime != nil
    }
}

struct SleepData: Identifiable {
    let id: UUID
    let date: Date
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let category: HKCategoryValueSleepAnalysis
    let source: String
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

struct SleepInsights {
    let averageSleepDuration: TimeInterval
    let sleepEfficiency: Double
    let bedtimeConsistency: Double
    let recommendations: [String]
    
    var formattedAverageDuration: String {
        let hours = Int(averageSleepDuration) / 3600
        let minutes = (Int(averageSleepDuration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

struct SleepStatistics {
    let period: StatisticsPeriod
    let totalSleepTime: TimeInterval
    let averageSleepTime: TimeInterval
    let sleepEfficiency: Double
    let numberOfSessions: Int
}

struct AudioSettings: Codable {
    let masterVolume: Float
    let activeSounds: [String]
    let equalizerPreset: String
    let effectsEnabled: Bool
}

enum StatisticsPeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"
    
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .week:
            let start = calendar.date(byAdding: .day, value: -7, to: now)!
            return (start, now)
        case .month:
            let start = calendar.date(byAdding: .month, value: -1, to: now)!
            return (start, now)
        case .quarter:
            let start = calendar.date(byAdding: .month, value: -3, to: now)!
            return (start, now)
        case .year:
            let start = calendar.date(byAdding: .year, value: -1, to: now)!
            return (start, now)
        }
    }
}