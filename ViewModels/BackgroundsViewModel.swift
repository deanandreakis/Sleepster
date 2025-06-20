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
    private var isSelectingAnimation = false
    private var isInitializing = false
    
    // MARK: - Initialization
    init(databaseManager: DatabaseManager) {
        self.databaseManager = databaseManager
        print("🏗️ BackgroundsViewModel initializing...")
        isInitializing = true
        
        // First, ensure clean state by fixing any existing corruption
        loadBackgroundEntities()
        fixStateInconsistencies()
        
        // Then load animations and selected state
        loadAnimations()
        loadSelectedAnimation()
        
        isInitializing = false
        print("🏗️ BackgroundsViewModel initialization complete")
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
        print("🎯 DEBUG: selectAnimation called with ID: \(animationId)")
        
        // Debug: Map the ID to title for verification
        if let animation = AnimationRegistry.shared.animation(for: animationId) {
            print("🎯 DEBUG: This ID maps to animation: '\(animation.title)'")
        } else {
            print("❌ DEBUG: No animation found for ID: \(animationId)")
        }
        
        guard !isSelectingAnimation else {
            print("⚠️ Selection already in progress, ignoring: \(animationId)")
            return
        }
        
        guard !isInitializing else {
            print("⚠️ ViewModel is initializing, deferring selection: \(animationId)")
            return
        }
        
        // Check if already selected by verifying both viewModel state AND Core Data state
        let isAlreadySelectedInViewModel = selectedAnimationId == animationId
        let isAlreadySelectedInCoreData = backgroundEntities.first { $0.animationType == animationId }?.isSelected ?? false
        
        // Only skip if BOTH states agree it's already selected
        if isAlreadySelectedInViewModel && isAlreadySelectedInCoreData {
            print("⚠️ Animation \(animationId) is already selected in both states, ignoring")
            return
        }
        
        // If states are inconsistent, log and proceed with selection to fix synchronization
        if isAlreadySelectedInViewModel != isAlreadySelectedInCoreData {
            print("⚠️ State inconsistency detected for \(animationId): ViewModel=\(isAlreadySelectedInViewModel), CoreData=\(isAlreadySelectedInCoreData)")
        }
        
        isSelectingAnimation = true
        print("🎯 Selecting animation: \(animationId)")
        print("📍 Call stack: \(Thread.callStackSymbols.prefix(3).joined(separator: "\n"))")
        
        // Debug: Log current state before selection
        print("🔍 PRE-SELECTION STATE:")
        print("   Current selectedAnimationId: \(selectedAnimationId ?? "nil")")
        if let currentSelected = backgroundEntities.first(where: { $0.isSelected }) {
            print("   Current selected entity: \(currentSelected.animationType ?? "nil")")
        } else {
            print("   No entity currently selected")
        }
        
        // Update selectedAnimationId IMMEDIATELY for UI responsiveness
        selectedAnimationId = animationId
        print("✅ Updated selectedAnimationId to: \(animationId)")
        
        // Perform Core Data updates with smooth state update
        withAnimation(.easeInOut(duration: 0.3)) {
            // Enforce unique selection before making changes
            enforceUniqueSelection()
            
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
                
                // Debug: Log final state after selection
                print("🔍 POST-SELECTION STATE:")
                print("   Final selectedAnimationId: \(selectedAnimationId ?? "nil")")
                print("   Final selected entity: \(entity.animationType ?? "nil")")
                
                // Verify no other entities are selected
                let selectedEntities = backgroundEntities.filter { $0.isSelected }
                print("   Total entities marked as selected: \(selectedEntities.count)")
                for selectedEntity in selectedEntities {
                    print("     -> \(selectedEntity.animationType ?? "nil")")
                }
            } else {
                print("❌ Could not find entity for animation ID: \(animationId)")
                // Even if entity not found, keep selectedAnimationId updated for UI consistency
                
                // Debug: Show available entities
                print("🔍 Available entities:")
                for entity in backgroundEntities {
                    print("   - \(entity.animationType ?? "nil")")
                }
            }
        }
        
        isSelectingAnimation = false
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
            
            // Immediately check for and fix any multiple selections
            let selectedEntities = backgroundEntities.filter { $0.isSelected }
            if selectedEntities.count > 1 {
                print("🔧 Found \(selectedEntities.count) selected entities during load, fixing immediately...")
                
                // Keep only the first selected entity
                for (index, entity) in selectedEntities.enumerated() {
                    entity.isSelected = (index == 0)
                }
                
                databaseManager.saveContext()
                print("✅ Fixed multiple selections during entity load")
            }
        } catch {
            print("Error loading background entities: \(error)")
            backgroundEntities = []
        }
    }
    
    private func loadSelectedAnimation() {
        print("🔍 Loading selected animation from Core Data...")
        let request = BackgroundEntity.fetchSelectedBackground()
        let context = databaseManager.managedObjectContext
        
        do {
            let selectedBackgrounds = try context.fetch(request)
            print("🔍 Found \(selectedBackgrounds.count) selected backgrounds in Core Data")
            
            // Fix data corruption: ensure only one background is selected
            if selectedBackgrounds.count > 1 {
                print("⚠️ Found \(selectedBackgrounds.count) selected backgrounds, fixing...")
                for (index, background) in selectedBackgrounds.enumerated() {
                    print("   [\(index)] \(background.animationType ?? "nil") - will \(index == 0 ? "keep" : "deselect")")
                    background.isSelected = (index == 0)
                }
                databaseManager.saveContext()
            }
            
            if let selected = selectedBackgrounds.first {
                selectedAnimationId = selected.animationType
                print("📱 Loaded selected animation: \(selected.animationType ?? "nil")")
                
                // Check if this matches AppState
                let appStateAnimationId = AppState.shared.selectedAnimation?.id
                print("🎬 AppState currently has: \(appStateAnimationId ?? "nil")")
                
                // Load settings from entity
                animationSettings.speed = selected.speedMultiplier
                animationSettings.intensity = Float(selected.intensityLevel) / 3.0
                animationSettings.colorTheme = ColorTheme(rawValue: selected.colorTheme ?? "default") ?? .defaultTheme
                
                // Update AppState with the loaded selection
                if let animationType = selected.animationType,
                   let animation = AnimationRegistry.shared.animation(for: animationType) {
                    print("🎬 Loading saved AppState animation: \(animation.title)")
                    Task { @MainActor in
                        AppState.shared.setAnimation(animation)
                        AppState.shared.updateAnimationSettings(
                            intensity: animationSettings.intensity,
                            speed: animationSettings.speed,
                            colorTheme: animationSettings.colorTheme
                        )
                    }
                } else {
                    print("❌ Could not find animation for ID: \(selected.animationType ?? "nil")")
                }
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
        
        // Select default animation if none is selected (only if loadSelectedAnimation didn't find one)
        // BUT only during initialization - never overwrite existing selections
        if selectedAnimationId == nil && isInitializing, let firstAnimation = animations.first {
            print("🎯 No animation selected during initialization, setting default: \(firstAnimation.id)")
            
            // Double-check that no other entity is selected
            let alreadySelectedEntities = backgroundEntities.filter { $0.isSelected }
            if alreadySelectedEntities.isEmpty {
                // Find or create the entity for the first animation
                if let entity = backgroundEntities.first(where: { $0.animationType == firstAnimation.id }) {
                    entity.isSelected = true
                    selectedAnimationId = firstAnimation.id
                    
                    // Update AppState directly without triggering full selection flow
                    if let animation = AnimationRegistry.shared.animation(for: firstAnimation.id) {
                        print("🎬 Setting default AppState animation: \(animation.title)")
                        Task { @MainActor in
                            AppState.shared.setAnimation(animation)
                            AppState.shared.updateAnimationSettings(
                                intensity: animationSettings.intensity,
                                speed: animationSettings.speed,
                                colorTheme: animationSettings.colorTheme
                            )
                        }
                    }
                }
            } else {
                print("⚠️ Found \(alreadySelectedEntities.count) already selected entities, skipping default selection")
            }
        } else {
            print("📋 Using previously loaded animation: \(selectedAnimationId ?? "nil")")
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
    
    /// Fixes any state inconsistencies between selectedAnimationId and Core Data
    func fixStateInconsistencies() {
        print("🔧 Checking for state inconsistencies...")
        
        // Check if selectedAnimationId matches any Core Data entity
        let coreDataSelectedEntities = backgroundEntities.filter { $0.isSelected }
        
        print("🔍 Current state before fix:")
        print("   ViewModel selectedAnimationId: \(selectedAnimationId ?? "nil")")
        print("   Core Data selected entities: \(coreDataSelectedEntities.count)")
        for entity in coreDataSelectedEntities {
            print("     -> \(entity.animationType ?? "nil")")
        }
        
        if coreDataSelectedEntities.count > 1 {
            print("⚠️ Multiple entities selected in Core Data, fixing...")
            // Get current AppState to determine which should really be selected
            let currentAppStateAnimation = AppState.shared.selectedAnimation
            let appStateAnimationId = currentAppStateAnimation?.id
            print("🎬 AppState current animation: \(appStateAnimationId ?? "nil")")
            
            // Find the entity that matches AppState if possible
            var entityToKeep: BackgroundEntity? = nil
            if let appStateId = appStateAnimationId {
                entityToKeep = coreDataSelectedEntities.first { $0.animationType == appStateId }
            }
            
            // If no AppState match, keep the first one
            if entityToKeep == nil {
                entityToKeep = coreDataSelectedEntities.first
            }
            
            // Deselect all except the one to keep
            for entity in coreDataSelectedEntities {
                entity.isSelected = (entity == entityToKeep)
            }
            
            // Update ViewModel to match the kept entity
            selectedAnimationId = entityToKeep?.animationType
            print("✅ Fixed multiple selections - kept: \(entityToKeep?.animationType ?? "nil")")
            
            databaseManager.saveContext()
        }
        
        let coreDataSelected = coreDataSelectedEntities.first?.animationType
        
        if selectedAnimationId != coreDataSelected {
            print("⚠️ State inconsistency: ViewModel=\(selectedAnimationId ?? "nil"), CoreData=\(coreDataSelected ?? "nil")")
            
            // Check AppState to help resolve the conflict
            let appStateAnimationId = AppState.shared.selectedAnimation?.id
            print("🎬 AppState animation for reference: \(appStateAnimationId ?? "nil")")
            
            // Prefer AppState if it's different from both
            if let appStateId = appStateAnimationId, appStateId != selectedAnimationId && appStateId != coreDataSelected {
                print("🔄 AppState differs from both - syncing to AppState: \(appStateId)")
                selectedAnimationId = appStateId
                
                // Update Core Data to match AppState
                for entity in backgroundEntities {
                    entity.isSelected = (entity.animationType == appStateId)
                }
                databaseManager.saveContext()
                print("✅ Fixed: Synced both to AppState")
                
            } else if let coreDataSelected = coreDataSelected {
                selectedAnimationId = coreDataSelected
                print("✅ Fixed: Updated ViewModel to match Core Data")
            } else if let viewModelSelected = selectedAnimationId {
                // Core Data has no selection, update it to match ViewModel
                if let entity = backgroundEntities.first(where: { $0.animationType == viewModelSelected }) {
                    entity.isSelected = true
                    databaseManager.saveContext()
                    print("✅ Fixed: Updated Core Data to match ViewModel")
                }
            }
        } else {
            print("✅ States are consistent")
        }
    }
    
    func resetToCountingSheep() {
        print("🔄 Resetting to Counting Sheep (Dreamy Meadow)")
        selectAnimation("counting_sheep")
    }
    
    // MARK: - Data Integrity Methods
    
    /// Ensures only one animation is ever selected in Core Data
    private func enforceUniqueSelection() {
        let selectedEntities = backgroundEntities.filter { $0.isSelected }
        
        if selectedEntities.count > 1 {
            print("🔧 ENFORCING unique selection: found \(selectedEntities.count) selected entities")
            
            // Use AppState as the source of truth if available
            let appStateAnimationId = AppState.shared.selectedAnimation?.id
            var entityToKeep: BackgroundEntity?
            
            if let appStateId = appStateAnimationId {
                entityToKeep = selectedEntities.first { $0.animationType == appStateId }
                print("🎬 Using AppState as source of truth: \(appStateId)")
            }
            
            // If AppState doesn't match any selected entity, keep the first one
            if entityToKeep == nil {
                entityToKeep = selectedEntities.first
                print("📋 Using first selected entity as source of truth")
            }
            
            // Deselect all others
            for entity in selectedEntities {
                entity.isSelected = (entity == entityToKeep)
            }
            
            // Update ViewModel to match
            selectedAnimationId = entityToKeep?.animationType
            
            databaseManager.saveContext()
            print("✅ Enforced unique selection: \(entityToKeep?.animationType ?? "nil")")
        }
    }
    
    // MARK: - Debug Methods
    
    func debugAnimationOrdering() {
        print("🔍 DEBUG: Animation Registry Full List:")
        let allAnimations = AnimationRegistry.shared.animations
        for (index, animation) in allAnimations.enumerated() {
            print("   [\(index)] \(animation.id) → '\(animation.title)' (\(animation.category))")
        }
        
        print("🔍 DEBUG: Nature Category Filtered List:")
        let natureAnimations = AnimationRegistry.shared.animationsForCategory(.nature)
        for (index, animation) in natureAnimations.enumerated() {
            print("   [\(index)] \(animation.id) → '\(animation.title)'")
        }
    }
    
    func debugAnimationSelectionIssue() {
        print("🔍 === DEBUGGING ANIMATION SELECTION ISSUE ===")
        
        // 1. Check Animation Registry
        print("🔍 Animation Registry state:")
        let animations = AnimationRegistry.shared.animations
        for (index, animation) in animations.enumerated() {
            print("   [\(index)] \(animation.id) → '\(animation.title)' (\(animation.category))")
        }
        
        // 2. Check ViewModel State
        print("🔍 ViewModel state:")
        print("   selectedAnimationId: \(selectedAnimationId ?? "nil")")
        print("   backgroundEntities count: \(backgroundEntities.count)")
        
        // 3. Check Core Data entities
        print("🔍 Core Data entities:")
        for (index, entity) in backgroundEntities.enumerated() {
            let animationType = entity.animationType ?? "nil"
            let isSelected = entity.isSelected
            print("   [\(index)] \(animationType) → Selected: \(isSelected)")
        }
        
        // 4. Check specific problematic animations
        print("🔍 Specific animation checks:")
        let gentleWavesEntity = backgroundEntities.first { $0.animationType == "gentle_waves" }
        let fireflyMeadowEntity = backgroundEntities.first { $0.animationType == "firefly_meadow" }
        
        print("   gentle_waves entity: \(gentleWavesEntity?.isSelected ?? false) (should be Mystic Ocean)")
        print("   firefly_meadow entity: \(fireflyMeadowEntity?.isSelected ?? false) (should be Enchanted Garden)")
        
        // 5. Verify Registry to Entity mapping
        print("🔍 Registry to Entity mapping verification:")
        for animation in animations {
            let entity = backgroundEntities.first { $0.animationType == animation.id }
            let entityExists = entity != nil
            print("   \(animation.id) ('\(animation.title)') → Entity exists: \(entityExists)")
        }
        
        print("🔍 === END DEBUG ===")
    }
    
    func forceStateReset() {
        print("🔄 FORCE RESETTING ALL ANIMATION STATE")
        
        // Clear view model state
        selectedAnimationId = nil
        
        // Clear all Core Data selections
        for entity in backgroundEntities {
            entity.isSelected = false
        }
        
        // Set default to counting_sheep
        if let defaultEntity = backgroundEntities.first(where: { $0.animationType == "counting_sheep" }) {
            defaultEntity.isSelected = true
            selectedAnimationId = "counting_sheep"
        }
        
        databaseManager.saveContext()
        print("✅ Force reset complete")
    }
}
