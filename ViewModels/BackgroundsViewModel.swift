//
//  BackgroundsViewModel.swift
//  SleepMate
//
//  Created by Claude on Phase 1 Migration - Animated Backgrounds
//

import Foundation
import SwiftUI
import CoreData
import Combine

@MainActor
class BackgroundsViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let databaseManager: DatabaseManager
    
    // MARK: - Published Properties
    @Published var backgroundEntities: [BackgroundEntity] = []
    @Published var selectedAnimationId: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var animationSettings = AnimationSettings.default
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(databaseManager: DatabaseManager) {
        self.databaseManager = databaseManager
        loadAnimations()
        loadSelectedAnimation()
    }
    
    // MARK: - Public Methods
    func loadAnimations() {
        isLoading = true
        
        // Load existing entities from Core Data
        loadBackgroundEntities()
        
        // Create entities for new animations if they don't exist
        createDefaultAnimationEntities()
        
        isLoading = false
    }
    
    func selectAnimation(_ animationId: String) {
        print("🎯 Selecting animation: \(animationId)")
        
        // Perform selection with smooth state update
        withAnimation(.easeInOut(duration: 0.3)) {
            // Deselect all current selections
            for entity in backgroundEntities {
                if entity.isSelected {
                    print("📤 Deselecting: \(entity.animationType ?? "nil")")
                }
                entity.isSelected = false
            }
            
            // Select the new animation
            if let entity = backgroundEntities.first(where: { $0.animationType == animationId }) {
                entity.isSelected = true
                selectedAnimationId = animationId
                print("✅ Selected animation: \(animationId)")
                
                // Save settings to entity
                entity.speedMultiplier = animationSettings.speed
                entity.intensityLevel = Int32(animationSettings.intensity * 3) // 0-3 scale
                entity.colorTheme = animationSettings.colorTheme.rawValue
                
                // Update app state with smooth transition
                if let animation = AnimationRegistry.shared.animation(for: animationId) {
                    print("🎬 Setting AppState animation: \(animation.title)")
                    Task { @MainActor in
                        AppState.shared.setAnimation(animation)
                        AppState.shared.updateAnimationSettings(
                            intensity: animationSettings.intensity,
                            speed: animationSettings.speed,
                            colorTheme: animationSettings.colorTheme
                        )
                    }
                } else {
                    print("❌ Could not find animation for ID: \(animationId)")
                }
                
                databaseManager.saveContext()
            } else {
                print("❌ Could not find entity for animation ID: \(animationId)")
            }
        }
    }
    
    func toggleFavorite(_ animationId: String) {
        if let entity = backgroundEntities.first(where: { $0.animationType == animationId }) {
            entity.toggleFavorite()
            databaseManager.saveContext()
        }
    }
    
    func updateSettings(_ settings: AnimationSettings) {
        // Update with smooth animation
        withAnimation(.easeInOut(duration: 0.2)) {
            animationSettings = settings
        }
        
        // Update the selected entity and app state
        if let selectedId = selectedAnimationId,
           let entity = backgroundEntities.first(where: { $0.animationType == selectedId }) {
            entity.speedMultiplier = settings.speed
            entity.intensityLevel = Int32(settings.intensity * 3)
            entity.colorTheme = settings.colorTheme.rawValue
            
            // Update app state for immediate effect
            AppState.shared.updateAnimationSettings(
                intensity: settings.intensity,
                speed: settings.speed,
                colorTheme: settings.colorTheme
            )
            
            databaseManager.saveContext()
        }
    }
    
    // MARK: - Private Methods
    private func loadBackgroundEntities() {
        let request = BackgroundEntity.fetchAllBackgrounds()
        let context = databaseManager.managedObjectContext
        
        do {
            backgroundEntities = try context.fetch(request)
        } catch {
            print("Error loading background entities: \(error)")
            backgroundEntities = []
        }
    }
    
    private func loadSelectedAnimation() {
        let request = BackgroundEntity.fetchSelectedBackground()
        let context = databaseManager.managedObjectContext
        
        do {
            let selectedBackgrounds = try context.fetch(request)
            
            // Fix data corruption: ensure only one background is selected
            if selectedBackgrounds.count > 1 {
                print("⚠️ Found \(selectedBackgrounds.count) selected backgrounds, fixing...")
                // Deselect all but the first
                for (index, background) in selectedBackgrounds.enumerated() {
                    background.isSelected = (index == 0)
                }
                databaseManager.saveContext()
            }
            
            if let selected = selectedBackgrounds.first {
                selectedAnimationId = selected.animationType
                print("📱 Loaded selected animation: \(selected.animationType ?? "nil")")
                
                // Load settings from entity
                animationSettings.speed = selected.speedMultiplier
                animationSettings.intensity = Float(selected.intensityLevel) / 3.0
                animationSettings.colorTheme = ColorTheme(rawValue: selected.colorTheme ?? "default") ?? .defaultTheme
            } else {
                print("📱 No selected animation found, will use default")
            }
        } catch {
            print("❌ Error loading selected background: \(error)")
        }
    }
    
    private func createDefaultAnimationEntities() {
        let animations = AnimationRegistry.shared.animations
        let context = databaseManager.managedObjectContext
        
        for animation in animations {
            // Check if entity already exists
            let request = BackgroundEntity.fetchRequest()
            request.predicate = NSPredicate(format: "animationType == %@", animation.id)
            
            do {
                let existingEntities = try context.fetch(request)
                if existingEntities.isEmpty {
                    // Create new entity
                    let entity = BackgroundEntity(context: context)
                    entity.animationType = animation.id
                    entity.isSelected = false
                    entity.isFavorite = false
                    entity.speedMultiplier = 1.0
                    entity.intensityLevel = 2 // Medium intensity
                    entity.colorTheme = ColorTheme.defaultTheme.rawValue
                    
                    backgroundEntities.append(entity)
                }
            } catch {
                print("Error checking for existing animation entity: \(error)")
            }
        }
        
        // Select default animation if none is selected
        if selectedAnimationId == nil, let firstAnimation = animations.first {
            selectAnimation(firstAnimation.id)
        }
        
        databaseManager.saveContext()
    }
    
    // MARK: - Computed Properties
    var selectedAnimation: AnimatedBackground? {
        guard let selectedId = selectedAnimationId else { return nil }
        return AnimationRegistry.shared.animation(for: selectedId)
    }
    
    var favoriteAnimations: [BackgroundEntity] {
        return backgroundEntities.filter { $0.isFavorite }
    }
    
    func animationsForCategory(_ category: BackgroundCategory) -> [BackgroundEntity] {
        let animationIds = AnimationRegistry.shared.animationsForCategory(category).map { $0.id }
        return backgroundEntities.filter { entity in
            guard let animationType = entity.animationType else { return false }
            return animationIds.contains(animationType)
        }
    }
    
    func isFavorite(_ animationId: String) -> Bool {
        return backgroundEntities.first { $0.animationType == animationId }?.isFavorite ?? false
    }
    
    // MARK: - Debug and Reset Methods
    
    func debugCurrentSelection() {
        print("🔍 Current BackgroundsViewModel state:")
        print("   selectedAnimationId: \(selectedAnimationId ?? "nil")")
        print("   backgroundEntities count: \(backgroundEntities.count)")
        
        for entity in backgroundEntities {
            print("   Entity: \(entity.animationType ?? "nil") - Selected: \(entity.isSelected)")
        }
        
        let request = BackgroundEntity.fetchSelectedBackground()
        let context = databaseManager.managedObjectContext
        do {
            let selected = try context.fetch(request)
            print("   Core Data selected count: \(selected.count)")
            for background in selected {
                print("     -> \(background.animationType ?? "nil")")
            }
        } catch {
            print("   Core Data fetch error: \(error)")
        }
    }
    
    func resetToCountingSheep() {
        print("🔄 Resetting to Counting Sheep (Dreamy Meadow)")
        selectAnimation("counting_sheep")
    }
}