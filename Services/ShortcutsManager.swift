//
//  ShortcutsManager.swift
//  SleepMate
//
//  Created by Claude on Phase 5 Migration
//

import Intents
import IntentsUI
import Foundation
import Combine

/// Manages Shortcuts app integration and Siri intents
@MainActor
class ShortcutsManager: ObservableObject {
    static let shared = ShortcutsManager()
    
    @Published var donatedShortcuts: [INVoiceShortcut] = []
    @Published var isInitialized = false
    
    private init() {
        setupShortcuts()
    }
    
    // MARK: - Public Methods
    
    /// Initialize shortcuts and donate common actions
    func setupShortcuts() {
        Task {
            await donateCommonShortcuts()
            await loadExistingShortcuts()
            isInitialized = true
        }
    }
    
    /// Donate all common shortcuts to Siri
    func donateCommonShortcuts() async {
        await donateStartSleepShortcut()
        await donatePlaySoundsShortcut()
        await donateStopAudioShortcut()
        await donateSetTimerShortcut()
        await donateCheckSleepStatsShortcut()
    }
    
    /// Load existing shortcuts from the system
    func loadExistingShortcuts() async {
        do {
            let shortcuts = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[INVoiceShortcut], Error>) in
                INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: shortcuts ?? [])
                    }
                }
            }
            donatedShortcuts = shortcuts
        } catch {
            print("Failed to load existing shortcuts: \(error)")
        }
    }
    
    // MARK: - Individual Shortcut Donations
    
    /// Donate "Start Sleep" shortcut
    func donateStartSleepShortcut() async {
        let intent = StartSleepIntent()
        intent.suggestedInvocationPhrase = "Start sleeping with Sleepster"
        
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.identifier = "com.deanware.sleepmate.start-sleep"
        interaction.groupIdentifier = "com.deanware.sleepmate.sleep-actions"
        
        do {
            try await interaction.donate()
            print("Donated Start Sleep shortcut")
        } catch {
            print("Failed to donate Start Sleep shortcut: \(error)")
        }
    }
    
    /// Donate "Play Sounds" shortcut
    func donatePlaySoundsShortcut() async {
        let intent = PlaySoundsIntent()
        intent.suggestedInvocationPhrase = "Play sleep sounds"
        
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.identifier = "com.deanware.sleepmate.play-sounds"
        interaction.groupIdentifier = "com.deanware.sleepmate.audio-actions"
        
        do {
            try await interaction.donate()
            print("Donated Play Sounds shortcut")
        } catch {
            print("Failed to donate Play Sounds shortcut: \(error)")
        }
    }
    
    /// Donate "Stop Audio" shortcut
    func donateStopAudioShortcut() async {
        let intent = StopAudioIntent()
        intent.suggestedInvocationPhrase = "Stop Sleepster audio"
        
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.identifier = "com.deanware.sleepmate.stop-audio"
        interaction.groupIdentifier = "com.deanware.sleepmate.audio-actions"
        
        do {
            try await interaction.donate()
            print("Donated Stop Audio shortcut")
        } catch {
            print("Failed to donate Stop Audio shortcut: \(error)")
        }
    }
    
    /// Donate "Set Timer" shortcut
    func donateSetTimerShortcut() async {
        let intent = SetSleepTimerIntent()
        intent.suggestedInvocationPhrase = "Set sleep timer for 30 minutes"
        
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.identifier = "com.deanware.sleepmate.set-timer"
        interaction.groupIdentifier = "com.deanware.sleepmate.timer-actions"
        
        do {
            try await interaction.donate()
            print("Donated Set Timer shortcut")
        } catch {
            print("Failed to donate Set Timer shortcut: \(error)")
        }
    }
    
    /// Donate "Check Sleep Stats" shortcut
    func donateCheckSleepStatsShortcut() async {
        let intent = CheckSleepStatsIntent()
        intent.suggestedInvocationPhrase = "Check my sleep stats"
        
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.identifier = "com.deanware.sleepmate.check-stats"
        interaction.groupIdentifier = "com.deanware.sleepmate.stats-actions"
        
        do {
            try await interaction.donate()
            print("Donated Check Sleep Stats shortcut")
        } catch {
            print("Failed to donate Check Sleep Stats shortcut: \(error)")
        }
    }
    
    // MARK: - Dynamic Shortcut Donations
    
    /// Donate sound-specific shortcut when user plays a sound
    func donatePlaySpecificSound(_ soundName: String) async {
        let intent = PlaySpecificSoundIntent()
        intent.soundName = soundName
        intent.suggestedInvocationPhrase = "Play \(soundName) sound"
        
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.identifier = "com.deanware.sleepmate.play-\(soundName.lowercased().replacingOccurrences(of: " ", with: "-"))"
        interaction.groupIdentifier = "com.deanware.sleepmate.specific-sounds"
        
        do {
            try await interaction.donate()
            print("Donated Play \(soundName) shortcut")
        } catch {
            print("Failed to donate Play \(soundName) shortcut: \(error)")
        }
    }
    
    /// Donate timer-specific shortcut when user sets a timer
    func donateSpecificTimer(duration: TimeInterval) async {
        let intent = SetSpecificTimerIntent()
        intent.duration = NSNumber(value: duration)
        
        let minutes = Int(duration / 60)
        intent.suggestedInvocationPhrase = "Set sleep timer for \(minutes) minutes"
        
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.identifier = "com.deanware.sleepmate.timer-\(minutes)min"
        interaction.groupIdentifier = "com.deanware.sleepmate.specific-timers"
        
        do {
            try await interaction.donate()
            print("Donated \(minutes)-minute timer shortcut")
        } catch {
            print("Failed to donate \(minutes)-minute timer shortcut: \(error)")
        }
    }
    
    // MARK: - Shortcut Management
    
    /// Delete a specific shortcut
    func deleteShortcut(withIdentifier identifier: String) async {
        INVoiceShortcutCenter.shared.setShortcutSuggestions([])
        await loadExistingShortcuts()
        print("Deleted shortcut: \(identifier)")
    }
    
    /// Clear all donated shortcuts
    func clearAllShortcuts() async {
        do {
            let shortcuts = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[INVoiceShortcut], Error>) in
                INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: shortcuts ?? [])
                    }
                }
            }
            for shortcut in shortcuts {
                if shortcut.shortcut.intent is StartSleepIntent ||
                   shortcut.shortcut.intent is PlaySoundsIntent ||
                   shortcut.shortcut.intent is StopAudioIntent ||
                   shortcut.shortcut.intent is SetSleepTimerIntent ||
                   shortcut.shortcut.intent is CheckSleepStatsIntent {
                    INVoiceShortcutCenter.shared.setShortcutSuggestions([])
                }
            }
            await loadExistingShortcuts()
            print("Cleared all Sleepster shortcuts")
        } catch {
            print("Failed to clear shortcuts: \(error)")
        }
    }
}

// MARK: - Intent Definitions

/// Intent for starting sleep session
class StartSleepIntent: INIntent {
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        return StartSleepIntent()
    }
}

/// Intent for playing sounds
class PlaySoundsIntent: INIntent {
    @NSManaged public var soundMix: [String]?
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = PlaySoundsIntent()
        copy.soundMix = soundMix
        return copy
    }
}

/// Intent for stopping audio
class StopAudioIntent: INIntent {
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        return StopAudioIntent()
    }
}

/// Intent for setting sleep timer
class SetSleepTimerIntent: INIntent {
    @NSManaged public var duration: NSNumber?
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = SetSleepTimerIntent()
        copy.duration = duration
        return copy
    }
}

/// Intent for checking sleep statistics
class CheckSleepStatsIntent: INIntent {
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        return CheckSleepStatsIntent()
    }
}

/// Intent for playing specific sound
class PlaySpecificSoundIntent: INIntent {
    @NSManaged public var soundName: String?
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = PlaySpecificSoundIntent()
        copy.soundName = soundName
        return copy
    }
}

/// Intent for setting specific timer duration
class SetSpecificTimerIntent: INIntent {
    @NSManaged public var duration: NSNumber?
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = SetSpecificTimerIntent()
        copy.duration = duration
        return copy
    }
}