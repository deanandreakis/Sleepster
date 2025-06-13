//
//  SoundMixingControlsView.swift
//  SleepMate
//
//  Created by Claude on Phase 3 Migration
//

import SwiftUI

struct SoundMixingControlsView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @StateObject private var viewModel = SharedViewModelStore.shared.soundsViewModel
    @StateObject private var mainViewModel = SharedViewModelStore.shared.mainViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sound Mixing Controls")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("\(viewModel.selectedSoundsForMixing.count) sounds selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Master volume control
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Master")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(
                        value: Binding(
                            get: { mainViewModel.currentVolume },
                            set: { mainViewModel.updateVolume($0) }
                        ),
                        in: 0...1
                    )
                    .frame(width: 80)
                }
            }
            .padding(.horizontal)
            
            // Individual sound controls
            if !viewModel.selectedSoundsForMixing.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.selectedSoundsForMixing, id: \.objectID) { sound in
                            SoundMixChannelView(sound: sound)
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                EmptyStateView(
                    icon: "speaker.slash",
                    title: "No Sounds Selected",
                    subtitle: "Select sounds from the list above to start mixing.",
                    actionTitle: nil,
                    action: nil
                )
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding()
    }
}

struct SoundMixChannelView: View {
    let sound: SoundEntity
    @State private var volume: Float = 1.0
    @State private var isMuted = false
    @EnvironmentObject var serviceContainer: ServiceContainer
    @StateObject private var mainViewModel = SharedViewModelStore.shared.mainViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Sound info
            VStack(alignment: .leading, spacing: 4) {
                Text(sound.bTitle ?? "Unknown Sound")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(getSoundDescription())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(minWidth: 100, alignment: .leading)
            
            Spacer()
            
            // Volume controls
            HStack(spacing: 8) {
                // Mute button
                Button {
                    HapticFeedback.light()
                    isMuted.toggle()
                    updateVolume()
                } label: {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.1.fill")
                        .foregroundColor(isMuted ? .red : .primary)
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                
                // Volume slider
                Slider(
                    value: $volume,
                    in: 0...1,
                    onEditingChanged: { _ in
                        updateVolume()
                    }
                )
                .frame(width: 80)
                .disabled(isMuted)
                .opacity(isMuted ? 0.5 : 1.0)
                
                // Volume percentage
                Text("\(Int(volume * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 35, alignment: .trailing)
                    .monospacedDigit()
            }
            
            // Remove button
            Button {
                HapticFeedback.light()
                SharedViewModelStore.shared.soundsViewModel.removeSoundFromMix(sound)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.title3)
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onAppear {
            // Initialize volume from main view model or default
            volume = mainViewModel.getSoundVolume(for: sound)
        }
    }
    
    private func updateVolume() {
        let actualVolume = isMuted ? 0.0 : volume
        
        // Update volume through the main view model
        mainViewModel.setSoundVolume(actualVolume, for: sound)
    }
    
    private func getSoundFileName() -> String {
        return sound.soundUrl1?.replacingOccurrences(of: ".mp3", with: "") ?? ""
    }
    
    private func getSoundDescription() -> String {
        guard let title = sound.bTitle?.lowercased() else { return "Nature sound" }
        
        if title.contains("rain") || title.contains("storm") {
            return "Rainfall sounds"
        } else if title.contains("ocean") || title.contains("wave") {
            return "Ocean waves"
        } else if title.contains("forest") || title.contains("bird") {
            return "Forest ambiance"
        } else if title.contains("wind") {
            return "Wind sounds"
        } else if title.contains("fire") || title.contains("campfire") {
            return "Fire ambiance"
        } else if title.contains("water") || title.contains("stream") {
            return "Water sounds"
        } else {
            return "Nature sound"
        }
    }
}

// MARK: - Preview
#Preview {
    SoundMixingControlsView()
        .environmentObject(ServiceContainer())
}