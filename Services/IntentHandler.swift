//
//  IntentHandler.swift
//  SleepMate
//
//  Created by Claude on Phase 5 Migration
//

import Intents
import Foundation

/// Handles intent execution from Shortcuts and Siri
@MainActor
class IntentHandler: NSObject {
    static let shared = IntentHandler()
    
    private let serviceContainer = ServiceContainer.shared
    
    private override init() {
        super.init()
    }
    
    // MARK: - Intent Execution
    
    /// Execute Start Sleep intent
    func handleStartSleep(_ intent: StartSleepIntent) async -> StartSleepIntentResponse {
        // Start sleep tracking
        await SleepTracker.shared.startSleepTracking()
        
        // Start audio if user has preferred sounds
        let userDefaults = UserDefaults.standard
        if let preferredSounds = userDefaults.array(forKey: "PreferredSleepSounds") as? [String],
           !preferredSounds.isEmpty {
            
            for soundName in preferredSounds.prefix(3) { // Limit to 3 sounds
                // Use DatabaseManager to find sounds by name
                let allSounds = DatabaseManager.shared.fetchAllSounds()
                if let sound = allSounds.first(where: { $0.bTitle == soundName }) {
                    _ = await AudioMixingEngine.shared.playSound(named: sound.bTitle ?? "")
                }
            }
        }
        
        // Set default timer if configured
        if let defaultTimer = userDefaults.object(forKey: "DefaultSleepTimer") as? TimeInterval,
           defaultTimer > 0 {
            serviceContainer.timerManager.startTimer(duration: defaultTimer)
        }
        
        return StartSleepIntentResponse.success(message: "Sleep session started successfully")
    }
    
    /// Execute Play Sounds intent
    func handlePlaySounds(_ intent: PlaySoundsIntent) async -> PlaySoundsIntentResponse {
        if let soundMix = intent.soundMix, !soundMix.isEmpty {
            // Play specific sounds
            let allSounds = DatabaseManager.shared.fetchAllSounds()
            for soundName in soundMix {
                if let sound = allSounds.first(where: { $0.bTitle == soundName }) {
                    _ = await AudioMixingEngine.shared.playSound(named: sound.bTitle ?? "")
                }
            }
            
            let soundList = soundMix.joined(separator: ", ")
            return PlaySoundsIntentResponse.success(message: "Playing sounds: \(soundList)")
            
        } else {
            // Play default/recent sounds
            let userDefaults = UserDefaults.standard
            let allSounds = DatabaseManager.shared.fetchAllSounds()
            if let recentSounds = userDefaults.array(forKey: "RecentlyPlayedSounds") as? [String],
               let firstSound = recentSounds.first,
               let sound = allSounds.first(where: { $0.bTitle == firstSound }) {
                
                _ = await AudioMixingEngine.shared.playSound(named: sound.bTitle ?? "")
                return PlaySoundsIntentResponse.success(message: "Playing \(firstSound)")
            } else {
                // Play a default sound
                if let defaultSound = allSounds.first {
                    _ = await AudioMixingEngine.shared.playSound(named: defaultSound.bTitle ?? "")
                    return PlaySoundsIntentResponse.success(message: "Playing \(defaultSound.bTitle ?? "default sound")")
                }
            }
        }
        
        return PlaySoundsIntentResponse.failure(error: "No sounds available to play")
    }
    
    /// Execute Stop Audio intent
    func handleStopAudio(_ intent: StopAudioIntent) async -> StopAudioIntentResponse {
        // Stop all audio
        await AudioMixingEngine.shared.stopAllSounds()
        
        // Stop sleep tracking if active
        if SleepTracker.shared.isTracking {
            await SleepTracker.shared.stopSleepTracking()
        }
        
        // Stop timer if running
        if serviceContainer.timerManager.isRunning {
            serviceContainer.timerManager.stopTimer()
        }
        
        return StopAudioIntentResponse.success(message: "All audio stopped")
    }
    
    /// Execute Set Sleep Timer intent
    func handleSetSleepTimer(_ intent: SetSleepTimerIntent) async -> SetSleepTimerIntentResponse {
        let duration: TimeInterval
        
        if let intentDuration = intent.duration?.doubleValue {
            duration = intentDuration * 60 // Convert minutes to seconds
        } else {
            // Use default timer duration (30 minutes)
            duration = 30 * 60
        }
        
        serviceContainer.timerManager.startTimer(duration: duration)
        
        let minutes = Int(duration / 60)
        return SetSleepTimerIntentResponse.success(message: "Sleep timer set for \(minutes) minutes")
    }
    
    /// Execute Check Sleep Stats intent
    func handleCheckSleepStats(_ intent: CheckSleepStatsIntent) async -> CheckSleepStatsIntentResponse {
        // Get recent sleep insights
        await SleepTracker.shared.loadRecentSleepData()
        
        guard let insights = SleepTracker.shared.sleepInsights else {
            return CheckSleepStatsIntentResponse.success(message: "No sleep data available yet. Start tracking your sleep to see insights!")
        }
        
        let avgDuration = insights.formattedAverageDuration
        let efficiency = String(format: "%.0f", insights.sleepEfficiency)
        let consistency = String(format: "%.0f", insights.bedtimeConsistency)
        
        let message = """
        Your recent sleep stats:
        Average duration: \(avgDuration)
        Sleep efficiency: \(efficiency)%
        Bedtime consistency: \(consistency)%
        """
        
        return CheckSleepStatsIntentResponse.success(message: message)
    }
    
    /// Execute Play Specific Sound intent
    func handlePlaySpecificSound(_ intent: PlaySpecificSoundIntent) async -> PlaySpecificSoundIntentResponse {
        guard let soundName = intent.soundName else {
            return PlaySpecificSoundIntentResponse.failure(error: "No sound specified")
        }
        
        let allSounds = DatabaseManager.shared.fetchAllSounds()
        guard let sound = allSounds.first(where: { $0.bTitle == soundName }) else {
            return PlaySpecificSoundIntentResponse.failure(error: "Sound '\(soundName)' not found")
        }
        
        _ = await AudioMixingEngine.shared.playSound(named: sound.bTitle ?? "")
        return PlaySpecificSoundIntentResponse.success(message: "Playing \(soundName)")
    }
    
    /// Execute Set Specific Timer intent
    func handleSetSpecificTimer(_ intent: SetSpecificTimerIntent) async -> SetSpecificTimerIntentResponse {
        guard let duration = intent.duration?.doubleValue else {
            return SetSpecificTimerIntentResponse.failure(error: "No duration specified")
        }
        
        serviceContainer.timerManager.startTimer(duration: duration)
        
        let minutes = Int(duration / 60)
        return SetSpecificTimerIntentResponse.success(message: "Timer set for \(minutes) minutes")
    }
}

// MARK: - Intent Response Types

/// Response for Start Sleep intent
enum StartSleepIntentResponse {
    case success(message: String)
    case failure(error: String)
    
    var userActivity: NSUserActivity {
        let activity = NSUserActivity(activityType: "com.deanware.sleepmate.start-sleep")
        
        switch self {
        case .success(let message):
            activity.title = "Sleep Started"
            activity.userInfo = ["result": "success", "message": message]
        case .failure(let error):
            activity.title = "Sleep Start Failed"
            activity.userInfo = ["result": "failure", "error": error]
        }
        
        return activity
    }
}

/// Response for Play Sounds intent
enum PlaySoundsIntentResponse {
    case success(message: String)
    case failure(error: String)
    
    var userActivity: NSUserActivity {
        let activity = NSUserActivity(activityType: "com.deanware.sleepmate.play-sounds")
        
        switch self {
        case .success(let message):
            activity.title = "Sounds Playing"
            activity.userInfo = ["result": "success", "message": message]
        case .failure(let error):
            activity.title = "Sound Playback Failed"
            activity.userInfo = ["result": "failure", "error": error]
        }
        
        return activity
    }
}

/// Response for Stop Audio intent
enum StopAudioIntentResponse {
    case success(message: String)
    case failure(error: String)
    
    var userActivity: NSUserActivity {
        let activity = NSUserActivity(activityType: "com.deanware.sleepmate.stop-audio")
        
        switch self {
        case .success(let message):
            activity.title = "Audio Stopped"
            activity.userInfo = ["result": "success", "message": message]
        case .failure(let error):
            activity.title = "Stop Audio Failed"
            activity.userInfo = ["result": "failure", "error": error]
        }
        
        return activity
    }
}

/// Response for Set Sleep Timer intent
enum SetSleepTimerIntentResponse {
    case success(message: String)
    case failure(error: String)
    
    var userActivity: NSUserActivity {
        let activity = NSUserActivity(activityType: "com.deanware.sleepmate.set-timer")
        
        switch self {
        case .success(let message):
            activity.title = "Timer Set"
            activity.userInfo = ["result": "success", "message": message]
        case .failure(let error):
            activity.title = "Set Timer Failed"
            activity.userInfo = ["result": "failure", "error": error]
        }
        
        return activity
    }
}

/// Response for Check Sleep Stats intent
enum CheckSleepStatsIntentResponse {
    case success(message: String)
    case failure(error: String)
    
    var userActivity: NSUserActivity {
        let activity = NSUserActivity(activityType: "com.deanware.sleepmate.check-stats")
        
        switch self {
        case .success(let message):
            activity.title = "Sleep Stats"
            activity.userInfo = ["result": "success", "message": message]
        case .failure(let error):
            activity.title = "Check Stats Failed"
            activity.userInfo = ["result": "failure", "error": error]
        }
        
        return activity
    }
}

/// Response for Play Specific Sound intent
enum PlaySpecificSoundIntentResponse {
    case success(message: String)
    case failure(error: String)
    
    var userActivity: NSUserActivity {
        let activity = NSUserActivity(activityType: "com.deanware.sleepmate.play-specific-sound")
        
        switch self {
        case .success(let message):
            activity.title = "Sound Playing"
            activity.userInfo = ["result": "success", "message": message]
        case .failure(let error):
            activity.title = "Sound Playback Failed"
            activity.userInfo = ["result": "failure", "error": error]
        }
        
        return activity
    }
}

/// Response for Set Specific Timer intent
enum SetSpecificTimerIntentResponse {
    case success(message: String)
    case failure(error: String)
    
    var userActivity: NSUserActivity {
        let activity = NSUserActivity(activityType: "com.deanware.sleepmate.set-specific-timer")
        
        switch self {
        case .success(let message):
            activity.title = "Timer Set"
            activity.userInfo = ["result": "success", "message": message]
        case .failure(let error):
            activity.title = "Set Timer Failed"
            activity.userInfo = ["result": "failure", "error": error]
        }
        
        return activity
    }
}