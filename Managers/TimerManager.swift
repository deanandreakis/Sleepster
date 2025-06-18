//
//  TimerManager.swift
//  SleepMate
//
//  Created by Claude on Phase 2 Migration
//

import Foundation
import Combine
import UserNotifications

@MainActor
class TimerManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var duration: TimeInterval = 0
    @Published var timeRemaining: TimeInterval = 0
    @Published var progress: Double = 0.0
    
    // MARK: - Dependencies
    private let audioManager: AudioManager
    
    // MARK: - Timer Components
    private var cancellables = Set<AnyCancellable>()
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0
    private var fadeOutDuration: TimeInterval = 10.0
    
    // MARK: - Publishers
    private let timerCompletedSubject = PassthroughSubject<Void, Never>()
    var timerCompletedPublisher: AnyPublisher<Void, Never> {
        timerCompletedSubject.eraseToAnyPublisher()
    }
    
    private let timerUpdatedSubject = PassthroughSubject<TimeInterval, Never>()
    var timerUpdatedPublisher: AnyPublisher<TimeInterval, Never> {
        timerUpdatedSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    init(audioManager: AudioManager) {
        self.audioManager = audioManager
    }
    
    // MARK: - Timer Control
    func startTimer(duration: TimeInterval, fadeOutDuration: TimeInterval = 10.0) {
        stopTimer() // Stop any existing timer
        
        self.duration = duration
        self.timeRemaining = duration
        self.fadeOutDuration = fadeOutDuration
        self.startTime = Date()
        self.pausedTime = 0
        self.isPaused = false
        self.isRunning = true
        
        startInternalTimer()
        updateProgress()
    }
    
    func stopTimer() {
        cancellables.removeAll()
        isRunning = false
        isPaused = false
        timeRemaining = 0
        progress = 0.0
        startTime = nil
        pausedTime = 0
    }
    
    func pauseTimer() {
        guard isRunning && !isPaused else { return }
        
        cancellables.removeAll()
        isPaused = true
        
        // Store how much time has passed
        if let startTime = startTime {
            pausedTime += Date().timeIntervalSince(startTime)
        }
    }
    
    func resumeTimer() {
        guard isRunning && isPaused else { return }
        
        isPaused = false
        startTime = Date()
        startInternalTimer()
    }
    
    func resetTimer() {
        stopTimer()
    }
    
    func addTime(_ additionalTime: TimeInterval) {
        guard isRunning else { return }
        
        duration += additionalTime
        timeRemaining += additionalTime
        updateProgress()
    }
    
    // MARK: - Internal Timer
    private func startInternalTimer() {
        // Use SwiftUI's Timer.publish for non-blocking timer
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
            .store(in: &cancellables)
    }
    
    private func updateTimer() {
        guard let startTime = startTime else { return }
        
        let elapsedTime = pausedTime + Date().timeIntervalSince(startTime)
        timeRemaining = max(0, duration - elapsedTime)
        
        updateProgress()
        timerUpdatedSubject.send(timeRemaining)
        
        if timeRemaining <= 0 {
            timerCompleted()
        }
    }
    
    private func updateProgress() {
        if duration > 0 {
            progress = 1.0 - (timeRemaining / duration)
        } else {
            progress = 0.0
        }
    }
    
    private func timerCompleted() {
        cancellables.removeAll()
        isRunning = false
        isPaused = false
        timeRemaining = 0
        progress = 1.0
        
        // Send completion signal immediately - let MainViewModel handle audio fade
        timerCompletedSubject.send()
    }
    
    // MARK: - Timer State
    var formattedTimeRemaining: String {
        let totalSeconds = Int(round(timeRemaining))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var remainingPercentage: Double {
        guard duration > 0 else { return 0.0 }
        return (timeRemaining / duration) * 100
    }
    
    // MARK: - Quick Timer Presets
    func startQuickTimer(minutes: Int) {
        let duration = TimeInterval(minutes * 60)
        startTimer(duration: duration)
    }
    
    func start5MinuteTimer() {
        startQuickTimer(minutes: 5)
    }
    
    func start10MinuteTimer() {
        startQuickTimer(minutes: 10)
    }
    
    func start15MinuteTimer() {
        startQuickTimer(minutes: 15)
    }
    
    func start30MinuteTimer() {
        startQuickTimer(minutes: 30)
    }
    
    func start60MinuteTimer() {
        startQuickTimer(minutes: 60)
    }
    
    // MARK: - Timer Notifications (for background support)
    func scheduleLocalNotification() {
        guard isRunning && timeRemaining > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Sleepster"
        content.body = "Your sleep timer has completed"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeRemaining, repeats: false)
        let request = UNNotificationRequest(identifier: "sleepster.timer.completed", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    func cancelLocalNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["sleepster.timer.completed"])
    }
    
    // MARK: - Background Support
    func handleAppWillResignActive() {
        if isRunning {
            scheduleLocalNotification()
        }
    }
    
    func handleAppDidBecomeActive() {
        cancelLocalNotification()
        
        // Recalculate time remaining if timer was running
        if isRunning && !isPaused, let startTime = startTime {
            let elapsedTime = pausedTime + Date().timeIntervalSince(startTime)
            timeRemaining = max(0, duration - elapsedTime)
            
            if timeRemaining <= 0 {
                timerCompleted()
            } else {
                updateProgress()
            }
        }
    }
    
    deinit {
        // Clean up synchronously in deinit to avoid capturing self
        cancellables.removeAll()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["sleepster.timer.completed"])
    }
}