//
//  AudioMixingEngine.swift
//  SleepMate
//
//  Created by Claude on Phase 4 Migration
//

import AVFoundation
import Foundation
import Combine

/// Advanced audio mixing engine for multiple simultaneous sounds
@MainActor
class AudioMixingEngine: ObservableObject {
    static let shared = AudioMixingEngine()
    
    @Published var activePlayers: [AudioChannelPlayer] = []
    @Published var masterVolume: Float = 1.0
    @Published var isPlaying = false
    
    private let maxConcurrentSounds = 5
    private var cancellables = Set<AnyCancellable>()
    
    // Audio engine components
    private let audioEngine = AVAudioEngine()
    private let masterMixerNode = AVAudioMixerNode()
    private var audioPlayerNodes: [AudioChannelPlayer: AVAudioPlayerNode] = [:]
    private var audioFiles: [AudioChannelPlayer: AVAudioFile] = [:]
    
    private init() {
        setupAudioEngine()
        setupNotificationObservers()
    }
    
    // MARK: - Public Interface
    
    /// Play a sound with specified parameters
    func playSound(
        named soundName: String,
        volume: Float = 1.0,
        loop: Bool = true,
        fadeInDuration: TimeInterval = 0.0
    ) async -> AudioChannelPlayer? {
        
        guard activePlayers.count < maxConcurrentSounds else {
            print("Maximum concurrent sounds reached")
            return nil
        }
        
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            print("Sound file not found: \(soundName)")
            return nil
        }
        
        do {
            let audioFile = try AVAudioFile(forReading: soundURL)
            let playerNode = AVAudioPlayerNode()
            
            // Create channel player
            let channelPlayer = AudioChannelPlayer(
                id: UUID(),
                soundName: soundName,
                volume: volume,
                isLooping: loop,
                playerNode: playerNode
            )
            
            // Connect to audio engine
            audioEngine.attach(playerNode)
            audioEngine.connect(playerNode, to: masterMixerNode, format: audioFile.processingFormat)
            
            // Store references
            audioPlayerNodes[channelPlayer] = playerNode
            audioFiles[channelPlayer] = audioFile
            
            // Schedule audio buffer
            if loop {
                scheduleLoopingBuffer(for: channelPlayer, audioFile: audioFile)
            } else {
                scheduleBuffer(for: channelPlayer, audioFile: audioFile)
            }
            
            // Set initial volume
            playerNode.volume = volume * masterVolume
            
            // Start playback
            playerNode.play()
            
            // Add to active players
            activePlayers.append(channelPlayer)
            updatePlayingState()
            
            // Handle fade in
            if fadeInDuration > 0 {
                await fadeIn(channelPlayer, duration: fadeInDuration)
            }
            
            return channelPlayer
            
        } catch {
            print("Failed to load audio file: \(error)")
            return nil
        }
    }
    
    /// Stop a specific sound
    func stopSound(_ channelPlayer: AudioChannelPlayer, fadeOutDuration: TimeInterval = 0.0) async {
        guard let playerNode = audioPlayerNodes[channelPlayer] else { return }
        
        if fadeOutDuration > 0 {
            await fadeOut(channelPlayer, duration: fadeOutDuration)
        }
        
        playerNode.stop()
        cleanup(channelPlayer)
    }
    
    /// Stop all sounds
    func stopAllSounds(fadeOutDuration: TimeInterval = 0.0) async {
        let playersToStop = activePlayers
        
        if fadeOutDuration > 0 {
            // Fade out all sounds simultaneously
            await withTaskGroup(of: Void.self) { group in
                for player in playersToStop {
                    group.addTask {
                        await self.fadeOut(player, duration: fadeOutDuration)
                    }
                }
            }
        }
        
        // Stop all players
        for player in playersToStop {
            audioPlayerNodes[player]?.stop()
            cleanup(player)
        }
    }
    
    /// Set volume for a specific sound
    func setVolume(_ volume: Float, for channelPlayer: AudioChannelPlayer) {
        guard let playerNode = audioPlayerNodes[channelPlayer] else { return }
        
        channelPlayer.volume = volume
        playerNode.volume = volume * masterVolume
    }
    
    /// Set master volume (affects all sounds)
    func setMasterVolume(_ volume: Float) {
        masterVolume = volume
        
        // Update all active players
        for channelPlayer in activePlayers {
            if let playerNode = audioPlayerNodes[channelPlayer] {
                playerNode.volume = channelPlayer.volume * masterVolume
            }
        }
    }
    
    /// Create a preset mix of sounds
    func playPresetMix(_ preset: AudioPreset) async {
        // Stop current sounds
        await stopAllSounds(fadeOutDuration: 1.0)
        
        // Play preset sounds
        for soundConfig in preset.sounds {
            await playSound(
                named: soundConfig.name,
                volume: soundConfig.volume,
                loop: soundConfig.loop,
                fadeInDuration: soundConfig.fadeInDuration
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAudioEngine() {
        // Attach and connect master mixer
        audioEngine.attach(masterMixerNode)
        audioEngine.connect(masterMixerNode, to: audioEngine.outputNode, format: nil)
        
        // Start the engine
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func setupNotificationObservers() {
        // Listen for audio session interruptions
        NotificationCenter.default
            .publisher(for: NSNotification.Name("AudioInterruptionBegan"))
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleInterruption()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default
            .publisher(for: NSNotification.Name("AudioInterruptionEnded"))
            .sink { [weak self] notification in
                Task { @MainActor in
                    if let userInfo = notification.userInfo,
                       let shouldResume = userInfo["shouldResume"] as? Bool,
                       shouldResume {
                        await self?.resumePlayback()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func scheduleBuffer(for channelPlayer: AudioChannelPlayer, audioFile: AVAudioFile) {
        guard let playerNode = audioPlayerNodes[channelPlayer] else { return }
        
        guard let buffer = createBuffer(from: audioFile) else { return }
        
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: { [weak self] in
            Task { @MainActor in
                self?.cleanup(channelPlayer)
            }
        })
    }
    
    private func scheduleLoopingBuffer(for channelPlayer: AudioChannelPlayer, audioFile: AVAudioFile) {
        guard let playerNode = audioPlayerNodes[channelPlayer] else { return }
        
        guard let buffer = createBuffer(from: audioFile) else { return }
        
        // Schedule buffer in a loop
        func scheduleNext() {
            guard audioPlayerNodes[channelPlayer] != nil else { return }
            
            playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: scheduleNext)
        }
        
        scheduleNext()
    }
    
    private func createBuffer(from audioFile: AVAudioFile) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: audioFile.processingFormat,
            frameCapacity: AVAudioFrameCount(audioFile.length)
        ) else {
            return nil
        }
        
        do {
            try audioFile.read(into: buffer)
            return buffer
        } catch {
            print("Failed to read audio file into buffer: \(error)")
            return nil
        }
    }
    
    private func cleanup(_ channelPlayer: AudioChannelPlayer) {
        guard let playerNode = audioPlayerNodes[channelPlayer] else { return }
        
        // Disconnect and detach from engine
        audioEngine.disconnectNodeInput(playerNode)
        audioEngine.detach(playerNode)
        
        // Remove references
        audioPlayerNodes.removeValue(forKey: channelPlayer)
        audioFiles.removeValue(forKey: channelPlayer)
        
        // Remove from active players
        activePlayers.removeAll { $0.id == channelPlayer.id }
        updatePlayingState()
    }
    
    private func updatePlayingState() {
        isPlaying = !activePlayers.isEmpty
    }
    
    private func handleInterruption() async {
        // Pause all players
        for (_, playerNode) in audioPlayerNodes {
            playerNode.pause()
        }
        updatePlayingState()
    }
    
    private func resumePlayback() async {
        // Resume all players
        for (_, playerNode) in audioPlayerNodes {
            playerNode.play()
        }
        updatePlayingState()
    }
    
    // MARK: - Fade Effects
    
    private func fadeIn(_ channelPlayer: AudioChannelPlayer, duration: TimeInterval) async {
        guard let playerNode = audioPlayerNodes[channelPlayer] else { return }
        
        let targetVolume = channelPlayer.volume * masterVolume
        let steps = Int(duration / 0.05) // 50ms intervals
        let volumeStep = targetVolume / Float(steps)
        
        playerNode.volume = 0.0
        
        for step in 1...steps {
            let currentVolume = volumeStep * Float(step)
            playerNode.volume = currentVolume
            
            try? await Task.sleep(nanoseconds: UInt64(0.05 * 1_000_000_000))
        }
        
        playerNode.volume = targetVolume
    }
    
    private func fadeOut(_ channelPlayer: AudioChannelPlayer, duration: TimeInterval) async {
        guard let playerNode = audioPlayerNodes[channelPlayer] else { return }
        
        let startVolume = playerNode.volume
        let steps = Int(duration / 0.05) // 50ms intervals
        let volumeStep = startVolume / Float(steps)
        
        for step in 1...steps {
            let currentVolume = startVolume - (volumeStep * Float(step))
            playerNode.volume = max(0, currentVolume)
            
            try? await Task.sleep(nanoseconds: UInt64(0.05 * 1_000_000_000))
        }
        
        playerNode.volume = 0.0
    }
}

// MARK: - Supporting Types

class AudioChannelPlayer: ObservableObject, Identifiable, Hashable {
    let id: UUID
    let soundName: String
    @Published var volume: Float
    @Published var isLooping: Bool
    
    let playerNode: AVAudioPlayerNode
    
    init(
        id: UUID,
        soundName: String,
        volume: Float,
        isLooping: Bool,
        playerNode: AVAudioPlayerNode
    ) {
        self.id = id
        self.soundName = soundName
        self.volume = volume
        self.isLooping = isLooping
        self.playerNode = playerNode
    }
    
    static func == (lhs: AudioChannelPlayer, rhs: AudioChannelPlayer) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct AudioPreset {
    let name: String
    let description: String
    let sounds: [SoundConfiguration]
    
    struct SoundConfiguration {
        let name: String
        let volume: Float
        let loop: Bool
        let fadeInDuration: TimeInterval
    }
}

// MARK: - Predefined Presets

extension AudioPreset {
    static let oceanBreeze = AudioPreset(
        name: "Ocean Breeze",
        description: "Gentle ocean waves with light wind",
        sounds: [
            SoundConfiguration(name: "waves", volume: 0.8, loop: true, fadeInDuration: 2.0),
            SoundConfiguration(name: "wind", volume: 0.3, loop: true, fadeInDuration: 3.0)
        ]
    )
    
    static let forestNight = AudioPreset(
        name: "Forest Night",
        description: "Peaceful forest with crickets and gentle breeze",
        sounds: [
            SoundConfiguration(name: "forest", volume: 0.6, loop: true, fadeInDuration: 2.0),
            SoundConfiguration(name: "crickets", volume: 0.4, loop: true, fadeInDuration: 4.0)
        ]
    )
    
    static let thunderstorm = AudioPreset(
        name: "Thunderstorm",
        description: "Rain with distant thunder",
        sounds: [
            SoundConfiguration(name: "rain", volume: 0.7, loop: true, fadeInDuration: 2.0),
            SoundConfiguration(name: "thunder", volume: 0.5, loop: true, fadeInDuration: 3.0)
        ]
    )
    
    static let allPresets: [AudioPreset] = [
        .oceanBreeze, .forestNight, .thunderstorm
    ]
}