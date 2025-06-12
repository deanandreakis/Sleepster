//
//  AudioEqualizer.swift
//  SleepMate
//
//  Created by Claude on Phase 4 Migration
//

import AVFoundation
import Foundation
import Combine

/// Advanced audio equalizer with preset configurations
@MainActor
class AudioEqualizer: ObservableObject {
    static let shared = AudioEqualizer()
    
    @Published var isEnabled = false
    @Published var currentPreset: EqualizerPreset = .flat
    @Published var customBands: [Float] = Array(repeating: 0.0, count: 10)
    
    // Frequency bands (Hz)
    private let frequencyBands: [Float] = [
        32, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000
    ]
    
    private var audioEngine: AVAudioEngine?
    private var eqNode: AVAudioUnitEQ?
    
    private init() {
        setupEqualizer()
    }
    
    // MARK: - Public Interface
    
    /// Apply equalizer to audio engine
    func attachToAudioEngine(_ engine: AVAudioEngine, inputNode: AVAudioNode, outputNode: AVAudioNode) {
        guard let eqNode = eqNode else { return }
        
        audioEngine = engine
        
        // Attach EQ node to engine
        engine.attach(eqNode)
        
        // Connect: input -> EQ -> output
        engine.connect(inputNode, to: eqNode, format: nil)
        engine.connect(eqNode, to: outputNode, format: nil)
        
        // Apply current settings
        applyCurrentSettings()
    }
    
    /// Set equalizer preset
    func setPreset(_ preset: EqualizerPreset) {
        currentPreset = preset
        customBands = preset.bandValues
        applyCurrentSettings()
    }
    
    /// Set custom band value
    func setBandValue(_ value: Float, for bandIndex: Int) {
        guard bandIndex < customBands.count else { return }
        customBands[bandIndex] = value
        currentPreset = .custom
        applyBandValue(value, for: bandIndex)
    }
    
    /// Enable/disable equalizer
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        eqNode?.bypass = !enabled
    }
    
    /// Reset all bands to flat
    func resetToFlat() {
        setPreset(.flat)
    }
    
    // MARK: - Private Methods
    
    private func setupEqualizer() {
        // Create 10-band parametric EQ
        eqNode = AVAudioUnitEQ(numberOfBands: frequencyBands.count)
        
        guard let eqNode = eqNode else { return }
        
        // Configure each band
        for (index, frequency) in frequencyBands.enumerated() {
            let band = eqNode.bands[index]
            band.frequency = frequency
            band.gain = 0.0
            band.bandwidth = 1.0
            band.filterType = .parametric
        }
        
        // Set initial state
        eqNode.bypass = !isEnabled
    }
    
    private func applyCurrentSettings() {
        guard let eqNode = eqNode else { return }
        
        for (index, gain) in customBands.enumerated() {
            if index < eqNode.bands.count {
                eqNode.bands[index].gain = gain
            }
        }
    }
    
    private func applyBandValue(_ gain: Float, for bandIndex: Int) {
        guard let eqNode = eqNode,
              bandIndex < eqNode.bands.count else { return }
        
        eqNode.bands[bandIndex].gain = gain
    }
}

// MARK: - Equalizer Presets

enum EqualizerPreset: String, CaseIterable {
    case flat = "Flat"
    case rock = "Rock"
    case pop = "Pop"
    case jazz = "Jazz"
    case classical = "Classical"
    case electronic = "Electronic"
    case sleepOptimized = "Sleep Optimized"
    case bassBoost = "Bass Boost"
    case trebleBoost = "Treble Boost"
    case vocal = "Vocal Enhancement"
    case custom = "Custom"
    
    var displayName: String {
        return rawValue
    }
    
    var description: String {
        switch self {
        case .flat:
            return "No EQ applied, neutral sound"
        case .rock:
            return "Enhanced bass and treble for rock music"
        case .pop:
            return "Balanced sound for popular music"
        case .jazz:
            return "Warm mids with smooth highs"
        case .classical:
            return "Natural dynamics for orchestral music"
        case .electronic:
            return "Enhanced bass and crisp highs"
        case .sleepOptimized:
            return "Reduced harsh frequencies for relaxation"
        case .bassBoost:
            return "Enhanced low frequencies"
        case .trebleBoost:
            return "Enhanced high frequencies"
        case .vocal:
            return "Enhanced mid-range for clear vocals"
        case .custom:
            return "User-defined settings"
        }
    }
    
    /// Gain values for each frequency band (in dB)
    var bandValues: [Float] {
        switch self {
        case .flat:
            return [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        case .rock:
            return [3, 2, -1, -2, 0, 1, 2, 3, 4, 3]
        case .pop:
            return [1, 2, 3, 2, 0, -1, 1, 2, 3, 2]
        case .jazz:
            return [2, 1, 0, 1, 2, 1, 0, -1, 1, 2]
        case .classical:
            return [0, 0, 0, 0, 0, 0, -1, -1, 0, 0]
        case .electronic:
            return [4, 3, 1, 0, -1, 0, 1, 2, 3, 4]
        case .sleepOptimized:
            return [2, 1, 1, 0, 0, -1, -2, -3, -2, -1]
        case .bassBoost:
            return [6, 4, 2, 1, 0, 0, 0, 0, 0, 0]
        case .trebleBoost:
            return [0, 0, 0, 0, 0, 1, 2, 3, 4, 5]
        case .vocal:
            return [-1, 0, 1, 2, 3, 3, 2, 1, 0, -1]
        case .custom:
            return [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] // Will be overridden
        }
    }
    
    var icon: String {
        switch self {
        case .flat:
            return "slider.horizontal.3"
        case .rock:
            return "guitars"
        case .pop:
            return "music.note"
        case .jazz:
            return "piano"
        case .classical:
            return "music.quarternote.3"
        case .electronic:
            return "waveform"
        case .sleepOptimized:
            return "moon.stars"
        case .bassBoost:
            return "speaker.wave.3"
        case .trebleBoost:
            return "speaker.wave.2"
        case .vocal:
            return "mic"
        case .custom:
            return "slider.vertical.3"
        }
    }
}

// MARK: - Audio Processing Effects

@MainActor
class AudioEffectsProcessor: ObservableObject {
    static let shared = AudioEffectsProcessor()
    
    @Published var reverbEnabled = false
    @Published var reverbType: ReverbType = .room
    @Published var reverbWetDryMix: Float = 0.3
    
    @Published var delayEnabled = false
    @Published var delayTime: TimeInterval = 0.1
    @Published var delayFeedback: Float = 0.2
    @Published var delayWetDryMix: Float = 0.2
    
    private var reverbNode: AVAudioUnitReverb?
    private var delayNode: AVAudioUnitDelay?
    
    enum ReverbType: String, CaseIterable {
        case room = "Room"
        case hall = "Hall"
        case cathedral = "Cathedral"
        case plate = "Plate"
        
        var avPreset: AVAudioUnitReverbPreset {
            switch self {
            case .room:
                return .smallRoom
            case .hall:
                return .mediumHall
            case .cathedral:
                return .cathedral
            case .plate:
                return .plate
            }
        }
    }
    
    private init() {
        setupEffects()
    }
    
    // MARK: - Public Interface
    
    func attachToAudioEngine(
        _ engine: AVAudioEngine,
        inputNode: AVAudioNode,
        outputNode: AVAudioNode
    ) {
        guard let reverbNode = reverbNode,
              let delayNode = delayNode else { return }
        
        engine.attach(reverbNode)
        engine.attach(delayNode)
        
        // Connect chain: input -> delay -> reverb -> output
        engine.connect(inputNode, to: delayNode, format: nil)
        engine.connect(delayNode, to: reverbNode, format: nil)
        engine.connect(reverbNode, to: outputNode, format: nil)
        
        applyCurrentSettings()
    }
    
    func setReverbEnabled(_ enabled: Bool) {
        reverbEnabled = enabled
        reverbNode?.bypass = !enabled
    }
    
    func setReverbType(_ type: ReverbType) {
        reverbType = type
        reverbNode?.loadFactoryPreset(type.avPreset)
    }
    
    func setReverbWetDryMix(_ mix: Float) {
        reverbWetDryMix = mix
        reverbNode?.wetDryMix = mix * 100 // AVAudioUnitReverb expects 0-100
    }
    
    func setDelayEnabled(_ enabled: Bool) {
        delayEnabled = enabled
        delayNode?.bypass = !enabled
    }
    
    func setDelayTime(_ time: TimeInterval) {
        delayTime = time
        delayNode?.delayTime = time
    }
    
    func setDelayFeedback(_ feedback: Float) {
        delayFeedback = feedback
        delayNode?.feedback = feedback * 100 // 0-100 range
    }
    
    func setDelayWetDryMix(_ mix: Float) {
        delayWetDryMix = mix
        delayNode?.wetDryMix = mix * 100
    }
    
    // MARK: - Private Methods
    
    private func setupEffects() {
        reverbNode = AVAudioUnitReverb()
        delayNode = AVAudioUnitDelay()
        
        reverbNode?.bypass = !reverbEnabled
        delayNode?.bypass = !delayEnabled
    }
    
    private func applyCurrentSettings() {
        setReverbType(reverbType)
        setReverbWetDryMix(reverbWetDryMix)
        setDelayTime(delayTime)
        setDelayFeedback(delayFeedback)
        setDelayWetDryMix(delayWetDryMix)
    }
}

// MARK: - Audio Preset Manager

struct AudioPresetManager {
    static let shared = AudioPresetManager()
    
    private let userDefaults = UserDefaults.standard
    private let presetsKey = "SavedAudioPresets"
    
    private init() {}
    
    // MARK: - Preset Management
    
    func savePreset(_ preset: SavedAudioPreset) {
        var savedPresets = loadPresets()
        savedPresets.append(preset)
        
        if let data = try? JSONEncoder().encode(savedPresets) {
            userDefaults.set(data, forKey: presetsKey)
        }
    }
    
    func loadPresets() -> [SavedAudioPreset] {
        guard let data = userDefaults.data(forKey: presetsKey),
              let presets = try? JSONDecoder().decode([SavedAudioPreset].self, from: data) else {
            return []
        }
        return presets
    }
    
    func deletePreset(withId id: UUID) {
        let presets = loadPresets().filter { $0.id != id }
        
        if let data = try? JSONEncoder().encode(presets) {
            userDefaults.set(data, forKey: presetsKey)
        }
    }
}

// MARK: - Saved Audio Preset Model

struct SavedAudioPreset: Codable, Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let equalizerPreset: String
    let customEQBands: [Float]
    let masterVolume: Float
    let reverbEnabled: Bool
    let reverbType: String
    let reverbWetDryMix: Float
    let delayEnabled: Bool
    let delayTime: Double
    let delayFeedback: Float
    let delayWetDryMix: Float
    let createdAt: Date
    
    @MainActor
    init(
        name: String,
        description: String,
        equalizer: AudioEqualizer,
        effects: AudioEffectsProcessor,
        masterVolume: Float
    ) {
        self.name = name
        self.description = description
        self.equalizerPreset = equalizer.currentPreset.rawValue
        self.customEQBands = equalizer.customBands
        self.masterVolume = masterVolume
        self.reverbEnabled = effects.reverbEnabled
        self.reverbType = effects.reverbType.rawValue
        self.reverbWetDryMix = effects.reverbWetDryMix
        self.delayEnabled = effects.delayEnabled
        self.delayTime = effects.delayTime
        self.delayFeedback = effects.delayFeedback
        self.delayWetDryMix = effects.delayWetDryMix
        self.createdAt = Date()
    }
}