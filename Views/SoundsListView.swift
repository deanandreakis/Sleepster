//
//  SoundsListView.swift
//  SleepMate
//
//  Created by Claude on Phase 3 Migration
//

import SwiftUI

struct SoundsListView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @StateObject private var viewModel: SoundsViewModel
    
    @State private var showingFavoritesOnly = false
    @State private var selectedCategory: SoundCategory = .all
    
    enum SoundCategory: String, CaseIterable {
        case all = "All"
        case nature = "Nature"
        case water = "Water"
        case weather = "Weather"
        case ambient = "Ambient"
        
        var icon: String {
            switch self {
            case .all: return "music.note.list"
            case .nature: return "leaf"
            case .water: return "drop"
            case .weather: return "cloud.rain"
            case .ambient: return "waveform"
            }
        }
    }
    
    init() {
        // ViewModel will be injected via environment in real usage
        let container = ServiceContainer()
        self._viewModel = StateObject(wrappedValue: container.soundsViewModel)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and filter section
                searchAndFilterSection
                
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
            setupViewModel()
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
                    
                    Divider()
                        .frame(height: 20)
                    
                    // Favorites toggle
                    Button {
                        HapticFeedback.light()
                        viewModel.toggleFavoritesFilter()
                        showingFavoritesOnly = viewModel.showingFavoritesOnly
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: showingFavoritesOnly ? "heart.fill" : "heart")
                            Text("Favorites")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(showingFavoritesOnly ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(showingFavoritesOnly ? Color.red : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.regularMaterial, lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private func categoryButton(_ category: SoundCategory) -> some View {
        Button {
            HapticFeedback.light()
            selectedCategory = category
            // Filter sounds by category
        } label: {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                Text(category.rawValue)
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(selectedCategory == category ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(selectedCategory == category ? Color.blue : Color.clear)
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
                        isPreviewing: sound == viewModel.previewingSound,
                        onSelect: {
                            HapticFeedback.medium()
                            viewModel.selectSound(sound)
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
    
    private func setupViewModel() {
        // In real implementation, this would be handled by dependency injection
        // viewModel = serviceContainer.soundsViewModel
    }
    
    private func clearFilters() {
        viewModel.clearSearch()
        selectedCategory = .all
        showingFavoritesOnly = false
        viewModel.showingFavoritesOnly = false
    }
}

// MARK: - Sound Card View
struct SoundCardView: View {
    let sound: SoundEntity
    let isSelected: Bool
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
                    
                    // Select button
                    Button(action: onSelect) {
                        HStack(spacing: 4) {
                            if isSelected {
                                Image(systemName: "checkmark")
                                Text("Selected")
                            } else {
                                Text("Select")
                            }
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
                        )
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
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