//
//  BackgroundsView.swift
//  SleepMate
//
//  Created by Claude on Phase 3 Migration
//

import SwiftUI

struct BackgroundsView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @StateObject private var viewModel: BackgroundsViewModel
    @EnvironmentObject var appState: AppState
    
    @State private var selectedCategory: BackgroundsViewModel.BackgroundCategory = .all
    @State private var showingSearch = false
    
    init() {
        // ViewModel will be injected via environment in real usage
        let container = ServiceContainer()
        self._viewModel = StateObject(wrappedValue: container.backgroundsViewModel)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and filter section
                if showingSearch || !viewModel.searchText.isEmpty {
                    searchSection
                }
                
                // Category filters
                categoryFiltersSection
                
                // Content
                backgroundsContent
            }
            .navigationTitle("Backgrounds")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        HapticFeedback.light()
                        withAnimation {
                            showingSearch.toggle()
                        }
                    } label: {
                        Image(systemName: showingSearch ? "xmark" : "magnifyingglass")
                    }
                    
                    Button {
                        HapticFeedback.light()
                        viewModel.refreshBackgrounds()
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
    
    private var searchSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search backgrounds...", text: $viewModel.searchText)
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
            
            if viewModel.isSearching {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Searching online...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private var categoryFiltersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BackgroundsViewModel.BackgroundCategory.allCases, id: \.self) { category in
                    categoryButton(category)
                }
                
                Divider()
                    .frame(height: 20)
                
                // Favorites toggle
                Button {
                    HapticFeedback.light()
                    viewModel.toggleFavoritesFilter()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.showingFavoritesOnly ? "heart.fill" : "heart")
                        Text("Favorites")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
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
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
    
    private func categoryButton(_ category: BackgroundsViewModel.BackgroundCategory) -> some View {
        Button {
            HapticFeedback.light()
            selectedCategory = category
            viewModel.selectCategory(category)
        } label: {
            Text(category.rawValue)
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
    
    private var backgroundsContent: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    LoadingView(message: "Loading backgrounds...")
                    Spacer()
                }
            } else if viewModel.filteredBackgrounds.isEmpty {
                VStack {
                    Spacer()
                    EmptyStateView(
                        icon: "photo.on.rectangle",
                        title: "No Backgrounds Found",
                        subtitle: selectedCategory == .all ? 
                            "Try searching for nature, landscapes, or peaceful scenes." :
                            "Try a different category or search term.",
                        actionTitle: "Reset Filters",
                        action: resetFilters
                    )
                    Spacer()
                }
            } else {
                backgroundsGrid
            }
        }
    }
    
    private var backgroundsGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(viewModel.filteredBackgrounds, id: \.objectID) { background in
                    BackgroundCardView(
                        background: background,
                        isSelected: background == viewModel.selectedBackground,
                        onSelect: {
                            HapticFeedback.medium()
                            viewModel.selectBackground(background)
                            updateAppBackground(background)
                        },
                        onFavorite: {
                            HapticFeedback.light()
                            viewModel.toggleFavorite(background)
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
        // viewModel = serviceContainer.backgroundsViewModel
        selectedCategory = viewModel.selectedCategory
    }
    
    private func resetFilters() {
        viewModel.clearSearch()
        selectedCategory = .all
        viewModel.selectCategory(.all)
        viewModel.showingFavoritesOnly = false
    }
    
    private func updateAppBackground(_ background: BackgroundEntity) {
        if background.isImage {
            if background.isLocalImage {
                // Load local image
                if let imageName = background.bFullSizeUrl,
                   let image = UIImage(named: imageName) {
                    appState.setBackground(image: image)
                }
            } else {
                // Load remote image (in a real app, this would use proper async loading)
                if let urlString = background.bFullSizeUrl,
                   let url = URL(string: urlString) {
                    Task {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            if let image = UIImage(data: data) {
                                await MainActor.run {
                                    appState.setBackground(image: image)
                                }
                            }
                        } catch {
                            print("Failed to load background image: \(error)")
                        }
                    }
                }
            }
        } else {
            // Color background
            let color = viewModel.getBackgroundColor(background)
            appState.setBackground(color: UIColor(color))
        }
    }
}

// MARK: - Background Card View
struct BackgroundCardView: View {
    let background: BackgroundEntity
    let isSelected: Bool
    let onSelect: () -> Void
    let onFavorite: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            ZStack {
                // Background content
                backgroundContent
                
                // Overlay for selection and favorite
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: onFavorite) {
                            Image(systemName: background.isFavorite ? "heart.fill" : "heart")
                                .font(.caption)
                                .foregroundColor(background.isFavorite ? .red : .white)
                                .padding(4)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    // Title overlay
                    if let title = background.bTitle {
                        Text(getDisplayName(title))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                            .lineLimit(1)
                    }
                }
                .padding(8)
                
                // Selection indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 3)
                        .background(
                            Color.blue.opacity(0.2)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        )
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .background(Color.white, in: Circle())
                        .offset(x: 35, y: -35)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var backgroundContent: some View {
        Group {
            if background.isImage {
                if background.isLocalImage {
                    // Local image
                    if let imageName = background.bThumbnailUrl {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        placeholderView
                    }
                } else {
                    // Remote image
                    AsyncImageView(
                        url: background.bThumbnailUrl,
                        contentMode: .fill
                    )
                }
            } else {
                // Color background
                backgroundColorView
            }
        }
    }
    
    private var backgroundColorView: some View {
        Rectangle()
            .fill(getBackgroundColor())
            .overlay {
                if background.bColor == "clearColor" {
                    // Show checkerboard pattern for clear color
                    CheckerboardView()
                        .opacity(0.3)
                }
            }
    }
    
    private var placeholderView: some View {
        Rectangle()
            .fill(.regularMaterial)
            .overlay {
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
            }
    }
    
    private func getBackgroundColor() -> Color {
        guard let colorName = background.bColor else { return .black }
        
        switch colorName {
        case "whiteColor": return .white
        case "blueColor": return .blue
        case "redColor": return .red
        case "greenColor": return .green
        case "blackColor": return .black
        case "darkGrayColor": return Color(.darkGray)
        case "lightGrayColor": return Color(.lightGray)
        case "grayColor": return .gray
        case "cyanColor": return .cyan
        case "yellowColor": return .yellow
        case "magentaColor": return .pink
        case "orangeColor": return .orange
        case "purpleColor": return .purple
        case "brownColor": return .brown
        case "clearColor": return .clear
        default: return .black
        }
    }
    
    private func getDisplayName(_ title: String) -> String {
        if title.hasPrefix("z_") {
            return String(title.dropFirst(2)).replacingOccurrences(of: "_", with: " ")
        }
        
        return title.replacingOccurrences(of: "Color", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

// MARK: - Preview
#Preview {
    BackgroundsView()
        .environmentObject(ServiceContainer())
        .environmentObject(AppState())
}