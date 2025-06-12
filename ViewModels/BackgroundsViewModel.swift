//
//  BackgroundsViewModel.swift
//  SleepMate
//
//  Created by Claude on Phase 2 Migration
//

import Foundation
import SwiftUI
import CoreData
import Combine

@MainActor
class BackgroundsViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let databaseManager: DatabaseManager
    private let flickrAPIClient: FlickrAPIClient
    
    // MARK: - Published Properties
    @Published var backgrounds: [BackgroundEntity] = []
    @Published var favoriteBackgrounds: [BackgroundEntity] = []
    @Published var selectedBackground: BackgroundEntity?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var showingFavoritesOnly = false
    @Published var isSearching = false
    @Published var searchResults: [BackgroundEntity] = []
    
    // MARK: - Search Categories
    @Published var selectedCategory: BackgroundCategory = .all
    
    enum BackgroundCategory: String, CaseIterable {
        case all = "All"
        case colors = "Colors"
        case nature = "Nature"
        case local = "Local"
        case flickr = "Online"
        
        var searchTags: String {
            switch self {
            case .all: return ""
            case .colors: return ""
            case .nature: return "nature,landscape,forest,mountain,ocean"
            case .local: return ""
            case .flickr: return "peaceful,calm,relaxing,meditation"
            }
        }
    }
    
    // MARK: - Computed Properties
    var filteredBackgrounds: [BackgroundEntity] {
        var backgroundsToFilter = showingFavoritesOnly ? favoriteBackgrounds : backgrounds
        
        // Filter by category
        switch selectedCategory {
        case .all:
            break // Show all
        case .colors:
            backgroundsToFilter = backgroundsToFilter.filter { !$0.isImage }
        case .nature:
            backgroundsToFilter = backgroundsToFilter.filter { $0.isImage && !$0.isLocalImage }
        case .local:
            backgroundsToFilter = backgroundsToFilter.filter { $0.isLocalImage }
        case .flickr:
            backgroundsToFilter = backgroundsToFilter.filter { $0.isImage && !$0.isLocalImage }
        }
        
        // Filter by search text
        if searchText.isEmpty {
            return backgroundsToFilter
        } else {
            return backgroundsToFilter.filter { background in
                background.bTitle?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init(databaseManager: DatabaseManager, flickrAPIClient: FlickrAPIClient) {
        self.databaseManager = databaseManager
        self.flickrAPIClient = flickrAPIClient
        
        loadBackgrounds()
        setupSearchDebounce()
    }
    
    // MARK: - Setup
    private func setupSearchDebounce() {
        // Debounce search to avoid too many API calls
        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] searchText in
                if !searchText.isEmpty && self?.selectedCategory != .colors && self?.selectedCategory != .local {
                    self?.searchFlickrImages(for: searchText)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    func loadBackgrounds() {
        isLoading = true
        
        Task {
            let allBackgrounds = databaseManager.fetchAllBackgrounds()
            let favorites = allBackgrounds.filter { $0.isFavorite }
            let selected = databaseManager.fetchSelectedBackground()
            
            await MainActor.run {
                self.backgrounds = allBackgrounds
                self.favoriteBackgrounds = favorites
                self.selectedBackground = selected
                self.isLoading = false
            }
        }
    }
    
    func refreshBackgrounds() {
        loadBackgrounds()
    }
    
    // MARK: - Actions
    func selectBackground(_ background: BackgroundEntity) {
        // Deselect current background
        selectedBackground?.isSelected = false
        
        // Select new background
        background.selectBackground()
        selectedBackground = background
        
        // Save changes
        databaseManager.saveContext()
        
        // Update UI
        objectWillChange.send()
    }
    
    func toggleFavorite(_ background: BackgroundEntity) {
        background.toggleFavorite()
        databaseManager.saveContext()
        
        // Update favorites list
        if background.isFavorite {
            if !favoriteBackgrounds.contains(background) {
                favoriteBackgrounds.append(background)
            }
        } else {
            favoriteBackgrounds.removeAll { $0 == background }
        }
        
        objectWillChange.send()
    }
    
    func toggleFavoritesFilter() {
        showingFavoritesOnly.toggle()
    }
    
    func selectCategory(_ category: BackgroundCategory) {
        selectedCategory = category
        
        // Clear search if switching to local categories
        if category == .colors || category == .local {
            searchText = ""
        }
    }
    
    // MARK: - Search
    func searchFlickrImages(for query: String) {
        // Cancel previous search
        searchTask?.cancel()
        
        guard !query.isEmpty else { return }
        
        searchTask = Task {
            isSearching = true
            
            do {
                let flickrPhotos = try await flickrAPIClient.searchPhotos(tags: query, perPage: 20)
                
                await MainActor.run {
                    // Convert Flickr photos to BackgroundEntity objects
                    self.createBackgroundsFromFlickrPhotos(flickrPhotos)
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Search failed: \(error.localizedDescription)"
                    self.isSearching = false
                }
            }
        }
    }
    
    private func createBackgroundsFromFlickrPhotos(_ photos: [FlickrPhoto]) {
        let context = databaseManager.coreDataStack.viewContext
        var newBackgrounds: [BackgroundEntity] = []
        
        for photo in photos {
            // Check if this background already exists
            let existingBackground = backgrounds.first { background in
                background.bFullSizeUrl == photo.mediumURL?.absoluteString
            }
            
            if existingBackground == nil {
                guard let entity = NSEntityDescription.entity(forEntityName: "Background", in: context) else { continue }
                let background = BackgroundEntity(entity: entity, insertInto: context)
                background.bTitle = photo.title
                background.bThumbnailUrl = photo.thumbnailURL?.absoluteString
                background.bFullSizeUrl = photo.mediumURL?.absoluteString
                background.bColor = nil
                background.isImage = true
                background.isLocalImage = false
                background.isFavorite = false
                background.isSelected = false
                
                newBackgrounds.append(background)
            }
        }
        
        if !newBackgrounds.isEmpty {
            // Save new backgrounds
            databaseManager.saveContext()
            
            // Add to backgrounds array
            backgrounds.append(contentsOf: newBackgrounds)
        }
    }
    
    func clearSearch() {
        searchText = ""
        searchResults = []
    }
    
    // MARK: - Background Management
    func deleteBackground(_ background: BackgroundEntity) {
        // Don't allow deletion of favorite local backgrounds
        if background.isLocalImage && background.isFavorite {
            errorMessage = "Cannot delete built-in backgrounds"
            return
        }
        
        // Remove from Core Data
        let context = databaseManager.coreDataStack.viewContext
        context.delete(background)
        databaseManager.saveContext()
        
        // Remove from arrays
        backgrounds.removeAll { $0 == background }
        favoriteBackgrounds.removeAll { $0 == background }
        
        // Select a different background if this was selected
        if selectedBackground == background {
            selectedBackground = backgrounds.first { $0.isFavorite }
            selectedBackground?.selectBackground()
            databaseManager.saveContext()
        }
    }
    
    // MARK: - Helper Methods
    func getBackgroundColor(_ background: BackgroundEntity) -> Color {
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
    
    func getBackgroundImage(_ background: BackgroundEntity) -> UIImage? {
        guard background.isImage else { return nil }
        
        if background.isLocalImage {
            // Load from bundle
            guard let imageName = background.bThumbnailUrl else { return nil }
            return UIImage(named: imageName)
        } else {
            // For remote images, this would need to be loaded asynchronously
            // In Phase 3, we'll implement proper async image loading
            return nil
        }
    }
    
    func getDisplayName(_ background: BackgroundEntity) -> String {
        guard let title = background.bTitle else { return "Unknown" }
        
        // Clean up title for display
        if title.hasPrefix("z_") {
            return String(title.dropFirst(2)).replacingOccurrences(of: "_", with: " ")
        }
        
        return title.replacingOccurrences(of: "Color", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}