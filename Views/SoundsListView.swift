//
//  SoundsListView.swift
//  SleepMate
//
//  Created by Claude on Phase 3 Migration
//

import SwiftUI

struct SoundsListView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    
    @StateObject private var viewModel = SharedViewModelStore.shared.soundsViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and filter section
                searchAndFilterSection
                
                // Mixing mode status banner
                if viewModel.isMixingMode {
                    mixingStatusBanner
                }
                
                // Content
                if viewModel.isLoading {
                    Spacer()
                    LoadingView(message: "Loading sounds...")
                    Spacer()
                } else if viewModel.filteredSounds.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "speaker.slash",
                        title: "No Sounds Found",
                        subtitle: "Try adjusting your search or filters to find more sounds.",
                        actionTitle: "Clear Filters",
                        action: clearFilters
                    )
                    Spacer()
                } else {
                    soundsGrid
                }
            }
            .navigationTitle("Sounds")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        HapticFeedback.light()
                        if viewModel.isMixingMode {
                            viewModel.disableMixingMode()
                        } else {
                            viewModel.enableMixingMode()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.isMixingMode ? "checkmark.circle.fill" : "plus.circle")
                            Text(viewModel.isMixingMode ? "Mix" : "Mix")
                        }
                        .font(.caption)
                        .foregroundColor(viewModel.isMixingMode ? .blue : .primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.isMixingMode ? Color.blue.opacity(0.1) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(viewModel.isMixingMode ? Color.blue : Color.gray, lineWidth: 1)
                                )
                        )
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticFeedback.light()
                        viewModel.refreshSounds()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            // ViewModel is accessed directly from serviceContainer
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var mixingStatusBanner: some View {
        HStack {
            Image(systemName: "speaker.wave.2.fill")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Sound Mixing Mode")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Text("\(viewModel.selectedSoundsForMixing.count) of 5 sounds selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !viewModel.selectedSoundsForMixing.isEmpty {
                Button("Clear Mix") {
                    HapticFeedback.light()
                    viewModel.clearMix()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(.blue.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.blue.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search sounds...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            // Category filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SoundCategory.allCases, id: \.self) { category in
                        categoryButton(category)
                    }
                }
                .padding(.horizontal)
            }
            
            // Favorites filter - separate row for better visibility
            HStack {
                Text("Show:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button {
                    HapticFeedback.light()
                    viewModel.toggleFavoritesFilter()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.showingFavoritesOnly ? "heart.fill" : "heart")
                        Text("Favorites Only")
                    }
                    .font(.caption)
                    .foregroundColor(viewModel.showingFavoritesOnly ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(viewModel.showingFavoritesOnly ? Color.red : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.regularMaterial, lineWidth: 1)
                            )
                    )
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private func categoryButton(_ category: SoundCategory) -> some View {
        Button {
            HapticFeedback.light()
            viewModel.setCategory(category)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                Text(category.rawValue)
            }
            .font(.caption)
            .foregroundColor(viewModel.selectedCategory == category ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(viewModel.selectedCategory == category ? Color.blue : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.regularMaterial, lineWidth: 1)
                    )
            )
        }
    }
    
    private var soundsGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                ForEach(viewModel.filteredSounds, id: \.objectID) { sound in
                    SoundCardView(
                        sound: sound,
                        isSelected: sound == viewModel.selectedSound,
                        isSelectedForMixing: sound.isSelectedForMixing,
                        isMixingMode: viewModel.isMixingMode,
                        isPreviewing: sound == viewModel.previewingSound,
                        onSelect: {
                            HapticFeedback.medium()
                            if viewModel.isMixingMode {
                                viewModel.toggleSoundInMix(sound)
                            } else {
                                viewModel.selectSound(sound)
                            }
                        },
                        onPreview: {
                            HapticFeedback.light()
                            viewModel.previewSound(sound)
                        },
                        onFavorite: {
                            HapticFeedback.light()
                            viewModel.toggleFavorite(sound)
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    private func clearFilters() {
        viewModel.clearSearch()
        viewModel.setCategory(.all)
        viewModel.showingFavoritesOnly = false
    }
}

// MARK: - Sound Card View
struct SoundCardView: View {
    let sound: SoundEntity
    let isSelected: Bool
    let isSelectedForMixing: Bool
    let isMixingMode: Bool
    let isPreviewing: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void
    let onFavorite: () -> Void
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                // Header with title and favorite button
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sound.bTitle ?? "Unknown Sound")
                            .font(.headline)
                            .lineLimit(2)
                        
                        Text(getSoundDescription())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Button(action: onFavorite) {
                        Image(systemName: sound.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(sound.isFavorite ? .red : .secondary)
                            .font(.title3)
                    }
                }
                
                // Waveform visualization (placeholder)
                waveformView
                
                // Controls
                HStack {
                    // Preview button
                    Button(action: onPreview) {
                        Image(systemName: isPreviewing ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(isPreviewing ? .red : .blue)
                    }
                    
                    Spacer()
                    
                    // Select button - different UI for mixing vs single mode
                    Button(action: onSelect) {
                        HStack(spacing: 4) {
                            if isMixingMode {
                                // Mixing mode: show checkbox-style UI
                                Image(systemName: isSelectedForMixing ? "checkmark.square.fill" : "square")
                                    .foregroundColor(isSelectedForMixing ? .blue : .gray)
                                Text(isSelectedForMixing ? "In Mix" : "Add to Mix")
                                    .foregroundColor(isSelectedForMixing ? .blue : .primary)
                            } else {
                                // Single mode: show traditional selection UI
                                if isSelected {
                                    Image(systemName: "checkmark")
                                    Text("Selected")
                                } else {
                                    Text("Select")
                                }
                            }
                        }
                        .font(.caption)
                        .foregroundColor(
                            isMixingMode ? 
                            (isSelectedForMixing ? .blue : .primary) : 
                            (isSelected ? .white : .blue)
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    isMixingMode ? 
                                    (isSelectedForMixing ? Color.blue.opacity(0.1) : Color.clear) :
                                    (isSelected ? Color.blue : Color.blue.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            isMixingMode ?
                                            (isSelectedForMixing ? Color.blue : Color.gray.opacity(0.3)) :
                                            Color.clear,
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isMixingMode ? 
                    (isSelectedForMixing ? Color.blue : Color.clear) :
                    (isSelected ? Color.blue : Color.clear), 
                    lineWidth: 2
                )
        )
        .scaleEffect(
            isMixingMode ? 
            (isSelectedForMixing ? 1.02 : 1.0) :
            (isSelected ? 1.02 : 1.0)
        )
        .animation(.easeInOut(duration: 0.2), value: isMixingMode ? isSelectedForMixing : isSelected)
    }
    
    private var waveformView: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(isPreviewing ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 3, height: CGFloat.random(in: 4...20))
                    .animation(
                        isPreviewing ? 
                        Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(index) * 0.1) :
                        .easeInOut(duration: 0.3),
                        value: isPreviewing
                    )
            }
        }
        .frame(height: 24)
    }
    
    private func getSoundDescription() -> String {
        guard let title = sound.bTitle?.lowercased() else { return "Nature sound for relaxation" }
        
        if title.contains("rain") || title.contains("storm") {
            return "Relaxing rainfall sounds"
        } else if title.contains("ocean") || title.contains("wave") {
            return "Calming ocean waves"
        } else if title.contains("forest") || title.contains("bird") {
            return "Peaceful forest ambiance"
        } else if title.contains("wind") {
            return "Gentle wind sounds"
        } else if title.contains("fire") || title.contains("campfire") {
            return "Crackling fire ambiance"
        } else if title.contains("water") || title.contains("stream") {
            return "Flowing water sounds"
        } else {
            return "Nature sound for sleep"
        }
    }
}

// MARK: - Preview
#Preview {
    SoundsListView()
        .environmentObject(ServiceContainer())
}