//
//  AudioManager.swift
//  SleepMate
//
//  Created by Claude on Phase 2 Migration
//

import Foundation
import AVFoundation
import Combine

@MainActor
class AudioManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var volume: Float = 0.5
    @Published var isMuted = false
    @Published var currentSoundURL: String?
    @Published var isLooping = false
    
    // MARK: - Audio Engine Components
    private let audioEngine = AVAudioEngine()
    private let audioPlayerNode = AVAudioPlayerNode()
    private let audioMixer = AVAudioMixerNode()
    private var audioBuffer: AVAudioPCMBuffer?
    private var audioFile: AVAudioFile?
    
    // MARK: - Legacy AVAudioPlayer (for compatibility)
    private var audioPlayer: AVAudioPlayer?
    private var fadeTimer: Timer?
    
    // MARK: - Core Data
    private let coreDataStack: CoreDataStack
    
    // MARK: - Audio Session
    private let audioSession = AVAudioSession.sharedInstance()
    
    // MARK: - Completion Handlers
    private var fadeCompletionHandler: (() -> Void)?
    private var playCompletionHandler: (() -> Void)?
    
    // MARK: - State
    private var isEngineSetup = false
    private var isSessionSetup = false
    
    // MARK: - Initialization
    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
        super.init()
        
        setupAudioSession()
        setupAudioEngine()
        setupNotifications()
    }
    
    // MARK: - Audio Session Setup
    func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetoothA2DP])
            try audioSession.setActive(true)
            isSessionSetup = true
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Audio Engine Setup
    private func setupAudioEngine() {
        // Attach nodes to engine
        audioEngine.attach(audioPlayerNode)
        audioEngine.attach(audioMixer)
        
        // Connect nodes
        audioEngine.connect(audioPlayerNode, to: audioMixer, format: nil)
        audioEngine.connect(audioMixer, to: audioEngine.outputNode, format: nil)
        
        // Set initial volume
        audioMixer.outputVolume = volume
        
        do {
            try audioEngine.start()
            isEngineSetup = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    // MARK: - Notifications Setup
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: audioSession
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: audioSession
        )
    }
    
    // MARK: - Audio Playback
    func playSound(url: String, loop: Bool = false, completion: (() -> Void)? = nil) {
        stopAllSounds()
        
        currentSoundURL = url
        isLooping = loop
        playCompletionHandler = completion
        
        // Try to load from bundle first
        if let soundPath = Bundle.main.path(forResource: url.replacingOccurrences(of: ".mp3", with: ""), ofType: "mp3") {
            playLocalSound(path: soundPath, loop: loop)
        } else if let soundURL = URL(string: url) {
            if soundURL.scheme != nil {
                // Remote URL
                playRemoteSound(url: soundURL, loop: loop)
            } else {
                // Treat as local filename
                playLocalSound(path: url, loop: loop)
            }
        }
    }
    
    private func playLocalSound(path: String, loop: Bool) {
        do {
            let soundURL = URL(fileURLWithPath: path)
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.delegate = self
            audioPlayer?.numberOfLoops = loop ? -1 : 0
            audioPlayer?.volume = isMuted ? 0 : volume
            audioPlayer?.prepareToPlay()
            
            let success = audioPlayer?.play() ?? false
            if success {
                isPlaying = true
            }
        } catch {
            print("Failed to play local sound: \(error)")
        }
    }
    
    private func playRemoteSound(url: URL, loop: Bool) {
        // Download and cache the remote sound
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Failed to download remote sound: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                do {
                    self?.audioPlayer = try AVAudioPlayer(data: data)
                    self?.audioPlayer?.delegate = self
                    self?.audioPlayer?.numberOfLoops = loop ? -1 : 0
                    self?.audioPlayer?.volume = self?.isMuted == true ? 0 : (self?.volume ?? 0.5)
                    self?.audioPlayer?.prepareToPlay()
                    
                    let success = self?.audioPlayer?.play() ?? false
                    if success {
                        self?.isPlaying = true
                    }
                } catch {
                    print("Failed to play remote sound: \(error)")
                }
            }
        }.resume()
    }
    
    // MARK: - Audio Control
    func stopAllSounds() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        
        audioPlayer?.stop()
        audioPlayer = nil
        audioPlayerNode.stop()
        
        isPlaying = false
        currentSoundURL = nil
    }
    
    func pauseAudio() {
        audioPlayer?.pause()
        audioPlayerNode.pause()
        isPlaying = false
    }
    
    func resumeAudio() {
        audioPlayer?.play()
        audioPlayerNode.play()
        isPlaying = audioPlayer?.isPlaying ?? false
    }
    
    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        
        if !isMuted {
            audioPlayer?.volume = volume
            audioMixer.outputVolume = volume
        }
    }
    
    func toggleMute() {
        isMuted.toggle()
        
        if isMuted {
            audioPlayer?.volume = 0
            audioMixer.outputVolume = 0
        } else {
            audioPlayer?.volume = volume
            audioMixer.outputVolume = volume
        }
    }
    
    // MARK: - Fade Effects
    func fadeOutAndStop(duration: TimeInterval, completion: (() -> Void)? = nil) {
        fadeCompletionHandler = completion
        
        guard let player = audioPlayer, player.isPlaying else {
            completion?()
            return
        }
        
        let originalVolume = player.volume
        let fadeSteps = 20
        let stepDuration = duration / Double(fadeSteps)
        let volumeStep = originalVolume / Float(fadeSteps)
        
        var currentStep = 0
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            currentStep += 1
            let newVolume = originalVolume - (volumeStep * Float(currentStep))
            
            if newVolume <= 0 || currentStep >= fadeSteps {
                timer.invalidate()
                self?.stopAllSounds()
                self?.fadeCompletionHandler?()
                self?.fadeCompletionHandler = nil
            } else {
                player.volume = newVolume
            }
        }
    }
    
    func fadeIn(duration: TimeInterval) {
        guard let player = audioPlayer else { return }
        
        player.volume = 0
        let targetVolume = volume
        let fadeSteps = 20
        let stepDuration = duration / Double(fadeSteps)
        let volumeStep = targetVolume / Float(fadeSteps)
        
        var currentStep = 0
        
        Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            currentStep += 1
            let newVolume = volumeStep * Float(currentStep)
            
            if newVolume >= targetVolume || currentStep >= fadeSteps {
                timer.invalidate()
                player.volume = targetVolume
            } else {
                player.volume = newVolume
            }
        }
    }
    
    // MARK: - App Lifecycle Handling
    func handleAppBecameActive() {
        if !audioEngine.isRunning && isEngineSetup {
            do {
                try audioEngine.start()
            } catch {
                print("Failed to restart audio engine: \(error)")
            }
        }
        
        if !audioSession.isOtherAudioPlaying {
            try? audioSession.setActive(true)
        }
    }
    
    func handleAppWillResignActive() {
        // Keep playing in background if user wants
        // Audio session is configured for .playback category
    }
    
    // MARK: - Audio Session Interruption Handling
    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Interruption began - pause audio
            if isPlaying {
                pauseAudio()
            }
            
        case .ended:
            // Interruption ended - potentially resume audio
            guard let optionsValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // Resume audio
                resumeAudio()
            }
            
        @unknown default:
            break
        }
    }
    
    @objc private func handleAudioSessionRouteChange(notification: Notification) {
        guard let reasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            // Headphones were unplugged - pause audio
            pauseAudio()
            
        default:
            break
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        fadeTimer?.invalidate()
        Task { @MainActor in
            stopAllSounds()
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag && !isLooping {
            isPlaying = false
            currentSoundURL = nil
            playCompletionHandler?()
            playCompletionHandler = nil
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio player decode error: \(error?.localizedDescription ?? "Unknown error")")
        Task { @MainActor in
            isPlaying = false
            currentSoundURL = nil
        }
    }
}