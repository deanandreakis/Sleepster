//
//  AudioSessionManager.swift
//  SleepMate
//
//  Created by Claude on Phase 4 Migration
//

import AVFoundation
import MediaPlayer
import Combine

/// Comprehensive audio session management with interruption handling
@MainActor
class AudioSessionManager: NSObject, ObservableObject {
    static let shared = AudioSessionManager()
    
    @Published var isActive = false
    @Published var currentCategory: AVAudioSession.Category = .playback
    @Published var isInterrupted = false
    @Published var interruptionReason: InterruptionReason?
    
    private let audioSession = AVAudioSession.sharedInstance()
    private var cancellables = Set<AnyCancellable>()
    
    enum InterruptionReason {
        case phoneCall
        case alarm
        case siri
        case other
        
        var description: String {
            switch self {
            case .phoneCall: return "Phone call"
            case .alarm: return "Alarm"
            case .siri: return "Siri"
            case .other: return "Other app"
            }
        }
    }
    
    private override init() {
        super.init()
        setupAudioSession()
        setupNotificationObservers()
        setupRemoteCommandCenter()
    }
    
    // MARK: - Public Interface
    
    /// Configure audio session for sleep sounds playback
    func configureSleepAudioSession() async throws {
        do {
            // Set category for background playback
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .allowAirPlay, .allowBluetoothA2DP]
            )
            
            // Set preferred sample rate and buffer size for optimal performance
            try audioSession.setPreferredSampleRate(44100.0)
            try audioSession.setPreferredIOBufferDuration(0.1)
            
            // Activate the session
            try audioSession.setActive(true)
            
            await MainActor.run {
                self.isActive = true
                self.currentCategory = .playback
            }
            
        } catch {
            throw AudioSessionError.configurationFailed(error)
        }
    }
    
    /// Configure audio session for recording (future feature)
    func configureRecordingSession() async throws {
        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetoothA2DP]
            )
            
            try audioSession.setActive(true)
            
            await MainActor.run {
                self.isActive = true
                self.currentCategory = .playAndRecord
            }
            
        } catch {
            throw AudioSessionError.configurationFailed(error)
        }
    }
    
    /// Deactivate audio session
    func deactivateSession() async {
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            isActive = false
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    /// Handle app going to background
    func handleAppDidEnterBackground() {
        // Audio will continue playing in background if properly configured
        // Just ensure the session remains active
        if !isActive {
            Task {
                try? await configureSleepAudioSession()
            }
        }
    }
    
    /// Handle app coming to foreground
    func handleAppWillEnterForeground() {
        // Reactivate session if needed
        if !isActive {
            Task {
                try? await configureSleepAudioSession()
            }
        }
    }
    
    // MARK: - Private Setup
    
    private func setupAudioSession() {
        Task {
            try? await configureSleepAudioSession()
        }
    }
    
    private func setupNotificationObservers() {
        // Audio interruption notifications
        NotificationCenter.default
            .publisher(for: AVAudioSession.interruptionNotification)
            .sink { [weak self] notification in
                self?.handleInterruption(notification)
            }
            .store(in: &cancellables)
        
        // Route change notifications (headphones plugged/unplugged)
        NotificationCenter.default
            .publisher(for: AVAudioSession.routeChangeNotification)
            .sink { [weak self] notification in
                self?.handleRouteChange(notification)
            }
            .store(in: &cancellables)
        
        // Media reset notification
        NotificationCenter.default
            .publisher(for: AVAudioSession.mediaServicesWereResetNotification)
            .sink { [weak self] _ in
                self?.handleMediaServicesReset()
            }
            .store(in: &cancellables)
        
        // App lifecycle notifications
        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppDidEnterBackground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleAppWillEnterForeground()
            }
            .store(in: &cancellables)
    }
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Enable play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.handleRemotePlay()
            return .success
        }
        
        // Enable pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.handleRemotePause()
            return .success
        }
        
        // Enable stop command
        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget { [weak self] _ in
            self?.handleRemoteStop()
            return .success
        }
        
        // Disable unnecessary commands
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.seekForwardCommand.isEnabled = false
        commandCenter.seekBackwardCommand.isEnabled = false
    }
    
    // MARK: - Event Handlers
    
    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            handleInterruptionBegan(userInfo)
        case .ended:
            handleInterruptionEnded(userInfo)
        @unknown default:
            break
        }
    }
    
    private func handleInterruptionBegan(_ userInfo: [AnyHashable: Any]) {
        isInterrupted = true
        
        // Determine interruption reason
        if let reasonValue = userInfo[AVAudioSessionInterruptionReasonKey] as? UInt,
           let reason = AVAudioSession.InterruptionReason(rawValue: reasonValue) {
            
            switch reason {
            case .default:
                interruptionReason = .other
            case .appWasSuspended:
                interruptionReason = .other
            @unknown default:
                interruptionReason = .other
            }
        }
        
        // Notify audio manager to pause playback
        NotificationCenter.default.post(
            name: NSNotification.Name("AudioInterruptionBegan"),
            object: self,
            userInfo: ["reason": interruptionReason as Any]
        )
    }
    
    private func handleInterruptionEnded(_ userInfo: [AnyHashable: Any]) {
        isInterrupted = false
        interruptionReason = nil
        
        guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
            return
        }
        
        let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
        
        if options.contains(.shouldResume) {
            // Resume playback
            Task {
                try? await configureSleepAudioSession()
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("AudioInterruptionEnded"),
                    object: self,
                    userInfo: ["shouldResume": true]
                )
            }
        } else {
            NotificationCenter.default.post(
                name: NSNotification.Name("AudioInterruptionEnded"),
                object: self,
                userInfo: ["shouldResume": false]
            )
        }
    }
    
    private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            // Headphones unplugged - pause playback
            NotificationCenter.default.post(
                name: NSNotification.Name("AudioRouteChanged"),
                object: self,
                userInfo: ["reason": "headphonesUnplugged"]
            )
            
        case .newDeviceAvailable:
            // New device connected
            NotificationCenter.default.post(
                name: NSNotification.Name("AudioRouteChanged"),
                object: self,
                userInfo: ["reason": "newDeviceConnected"]
            )
            
        default:
            break
        }
    }
    
    private func handleMediaServicesReset() {
        // Media services were reset, need to reconfigure
        Task {
            try? await configureSleepAudioSession()
        }
        
        NotificationCenter.default.post(
            name: NSNotification.Name("MediaServicesReset"),
            object: self
        )
    }
    
    // MARK: - Remote Control Handlers
    
    private func handleRemotePlay() {
        NotificationCenter.default.post(
            name: NSNotification.Name("RemoteControlPlay"),
            object: self
        )
    }
    
    private func handleRemotePause() {
        NotificationCenter.default.post(
            name: NSNotification.Name("RemoteControlPause"),
            object: self
        )
    }
    
    private func handleRemoteStop() {
        NotificationCenter.default.post(
            name: NSNotification.Name("RemoteControlStop"),
            object: self
        )
    }
    
    // MARK: - Now Playing Info
    
    func updateNowPlayingInfo(
        title: String,
        artist: String = "Sleepster",
        duration: TimeInterval? = nil,
        currentTime: TimeInterval? = nil
    ) {
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyAlbumTitle: "Sleep Sounds"
        ]
        
        if let duration = duration {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        }
        
        if let currentTime = currentTime {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}

// MARK: - Error Types

enum AudioSessionError: Error, LocalizedError {
    case configurationFailed(Error)
    case activationFailed(Error)
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .configurationFailed(let error):
            return "Failed to configure audio session: \(error.localizedDescription)"
        case .activationFailed(let error):
            return "Failed to activate audio session: \(error.localizedDescription)"
        case .permissionDenied:
            return "Audio permission denied"
        }
    }
}