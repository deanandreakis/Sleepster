//
//  AudioFading.swift
//  SleepMate
//
//  Created by Claude on Phase 4 Migration
//  Modern Swift implementation of audio fading functionality
//

import AVFoundation
import Foundation

// MARK: - Audio Fading Extension

extension AVAudioPlayer {
    
    /// Fade the audio player to a target volume over a specified duration
    /// - Parameters:
    ///   - targetVolume: The target volume (0.0 to 1.0)
    ///   - duration: The duration of the fade in seconds
    ///   - completion: Optional completion handler called when fade finishes
    func fadeToVolume(
        _ targetVolume: Float,
        duration: TimeInterval,
        completion: (() -> Void)? = nil
    ) {
        guard duration > 0 else {
            volume = targetVolume
            completion?()
            return
        }
        
        // Cancel any existing fade
        cancelFade()
        
        let fadeTask = FadeTask(
            player: self,
            targetVolume: targetVolume,
            duration: duration,
            completion: completion
        )
        
        AudioFadeManager.shared.startFade(fadeTask)
    }
    
    /// Stop playback with a fade out effect
    /// - Parameter duration: The duration of the fade out in seconds
    func stopWithFade(duration: TimeInterval) {
        guard isPlaying else { return }
        
        let originalVolume = volume
        
        fadeToVolume(0.0, duration: duration) { [weak self] in
            self?.pause()
            self?.currentTime = 0
            self?.volume = originalVolume
        }
    }
    
    /// Start playback with a fade in effect
    /// - Parameter duration: The duration of the fade in in seconds
    func playWithFade(duration: TimeInterval) {
        let targetVolume = volume
        
        if !isPlaying {
            volume = 0.0
            play()
        }
        
        fadeToVolume(targetVolume, duration: duration)
    }
    
    /// Cancel any ongoing fade operation
    func cancelFade() {
        AudioFadeManager.shared.cancelFade(for: self)
    }
    
    /// Check if this player is currently fading
    var isFading: Bool {
        return AudioFadeManager.shared.isFading(player: self)
    }
}

// MARK: - Fade Task

private class FadeTask {
    let player: AVAudioPlayer
    let targetVolume: Float
    let duration: TimeInterval
    let completion: (() -> Void)?
    
    private let startVolume: Float
    private let startTime: Date
    private let volumeDelta: Float
    private var timer: Timer?
    
    private static let fadeInterval: TimeInterval = 0.05
    private static let volumeThreshold: Float = 0.01
    
    init(
        player: AVAudioPlayer,
        targetVolume: Float,
        duration: TimeInterval,
        completion: (() -> Void)?
    ) {
        self.player = player
        self.targetVolume = targetVolume
        self.duration = duration
        self.completion = completion
        self.startVolume = player.volume
        self.startTime = Date()
        self.volumeDelta = targetVolume - startVolume
        
        startFading()
    }
    
    private func startFading() {
        timer = Timer.scheduledTimer(withTimeInterval: Self.fadeInterval, repeats: true) { [weak self] _ in
            self?.performFadeStep()
        }
    }
    
    private func performFadeStep() {
        let elapsed = Date().timeIntervalSince(startTime)
        let progress = min(elapsed / duration, 1.0)
        
        if progress >= 1.0 {
            // Fade complete
            finishFade()
        } else {
            // Update volume
            let currentVolume = startVolume + Float(progress) * volumeDelta
            player.volume = currentVolume
        }
    }
    
    private func finishFade() {
        timer?.invalidate()
        timer = nil
        
        player.volume = targetVolume
        completion?()
        
        // Remove from manager
        AudioFadeManager.shared.fadeCompleted(for: player)
    }
    
    func cancel() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        cancel()
    }
}

// MARK: - Audio Fade Manager

private class AudioFadeManager {
    static let shared = AudioFadeManager()
    
    private var activeFades: [ObjectIdentifier: FadeTask] = [:]
    private let queue = DispatchQueue(label: "AudioFadeManager", qos: .userInitiated)
    
    private init() {}
    
    func startFade(_ fadeTask: FadeTask) {
        queue.async { [weak self] in
            let playerID = ObjectIdentifier(fadeTask.player)
            
            // Cancel any existing fade for this player
            self?.activeFades[playerID]?.cancel()
            
            // Start new fade
            self?.activeFades[playerID] = fadeTask
        }
    }
    
    func cancelFade(for player: AVAudioPlayer) {
        queue.async { [weak self] in
            let playerID = ObjectIdentifier(player)
            self?.activeFades[playerID]?.cancel()
            self?.activeFades.removeValue(forKey: playerID)
        }
    }
    
    func fadeCompleted(for player: AVAudioPlayer) {
        queue.async { [weak self] in
            let playerID = ObjectIdentifier(player)
            self?.activeFades.removeValue(forKey: playerID)
        }
    }
    
    func isFading(player: AVAudioPlayer) -> Bool {
        return queue.sync {
            let playerID = ObjectIdentifier(player)
            return activeFades[playerID] != nil
        }
    }
    
    deinit {
        // Cancel all active fades
        for (_, fadeTask) in activeFades {
            fadeTask.cancel()
        }
    }
}

// MARK: - Convenience Methods

extension AVAudioPlayer {
    
    /// Crossfade from current sound to a new sound
    /// - Parameters:
    ///   - newPlayer: The new audio player to fade in
    ///   - duration: The duration of the crossfade
    static func crossfade(
        from currentPlayer: AVAudioPlayer?,
        to newPlayer: AVAudioPlayer,
        duration: TimeInterval
    ) {
        // Fade out current player
        currentPlayer?.fadeToVolume(0.0, duration: duration) {
            currentPlayer?.pause()
        }
        
        // Fade in new player
        newPlayer.playWithFade(duration: duration)
    }
    
    /// Create a smooth loop by fading out before the end and restarting
    /// - Parameter fadeOutDuration: Duration of fade out before restart
    func setupSmoothLoop(fadeOutDuration: TimeInterval) {
        let fadeOutTime = duration - fadeOutDuration
        
        Timer.scheduledTimer(withTimeInterval: fadeOutTime, repeats: false) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            
            self.fadeToVolume(0.0, duration: fadeOutDuration) {
                self.currentTime = 0
                self.playWithFade(duration: fadeOutDuration)
            }
        }
    }
}