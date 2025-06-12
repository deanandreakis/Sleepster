//
//  DatabaseManager.swift
//  SleepMate
//
//  Created by Claude on Phase 1 Migration
//

import Foundation
import CoreData
import UIKit

class DatabaseManager: ObservableObject {
    static let shared = DatabaseManager()
    
    // Constants
    private let minNumBgObjects = 50
    private let numPermanentBgObjects = 20
    private let flickrAPIKey = "ab284ac09b04f83cf5af22e4bc3b6e56"
    
    private var isPermObjectsExist = false
    
    private init() {}
    
    // MARK: - Core Data Stack (Legacy Support)
    var coreDataStack: CoreDataStack {
        return CoreDataStack.shared
    }
    
    @MainActor
    var managedObjectContext: NSManagedObjectContext {
        return coreDataStack.viewContext
    }
    
    // MARK: - Database Operations
    
    @MainActor
    func saveContext() {
        coreDataStack.save()
    }
    
    @MainActor
    func saveContextAsync() async {
        await coreDataStack.saveContext()
    }
    
    func initializeDB() {
        let storeURL = applicationDocumentsDirectory().appendingPathComponent("SleepMate.sqlite")
        do {
            try FileManager.default.removeItem(at: storeURL)
        } catch {
            print("Error removing database: \(error)")
        }
    }
    
    @MainActor
    func deleteAllEntities(_ entityName: String) async {
        let context = managedObjectContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        
        // Only delete non-favorite items (preserving original logic)
        fetchRequest.predicate = NSPredicate(format: "isFavorite != %@", NSNumber(value: true))
        
        do {
            let objects = try context.fetch(fetchRequest)
            for object in objects {
                context.delete(object)
            }
            await saveContextAsync()
        } catch {
            print("Error deleting entities: \(error)")
        }
    }
    
    // MARK: - Database Population
    
    @MainActor
    func prePopulate() async {
        // Clean up any duplicate sounds first
        await removeDuplicateSounds()
        
        // Reset favorite status for existing default sounds
        await resetDefaultSoundsFavoriteStatus()
        
        if !isPermObjectsExist {
            await populateDefaultBackgrounds()
        }
        
        // Fetch default sounds and backgrounds from Flickr
        await fetchDefaultContent()
    }
    
    @MainActor
    private func populateDefaultBackgrounds() async {
        let colorArray = [
            "whiteColor", "blueColor", "redColor", "greenColor",
            "blackColor", "darkGrayColor", "lightGrayColor", "grayColor",
            "cyanColor", "yellowColor", "magentaColor", "orangeColor",
            "purpleColor", "brownColor", "clearColor"
        ]
        
        let context = managedObjectContext
        
        // Add color backgrounds
        for colorName in colorArray {
            guard let entity = NSEntityDescription.entity(forEntityName: "Background", in: context) else { continue }
            let background = BackgroundEntity(entity: entity, insertInto: context)
            background.bTitle = colorName
            background.bThumbnailUrl = nil
            background.bFullSizeUrl = nil
            background.bColor = colorName
            background.isFavorite = true
            background.isImage = false
            background.isLocalImage = false
            background.isSelected = false
        }
        
        // Add local image backgrounds
        let localImages = [
            ("z_Independence Grove", "igrove_1"),
            ("z_Independence Grove_1", "grove2"),
            ("z_Independence Grove_2", "grove3"),
            ("z_Independence Grove_3", "grove4"),
            ("z_Independence Grove_4", "grove5")
        ]
        
        for (title, imageName) in localImages {
            guard let entity = NSEntityDescription.entity(forEntityName: "Background", in: context) else { continue }
            let background = BackgroundEntity(entity: entity, insertInto: context)
            background.bTitle = title
            background.bThumbnailUrl = imageName
            background.bFullSizeUrl = imageName
            background.bColor = nil
            background.isFavorite = true
            background.isImage = true
            background.isLocalImage = true
            background.isSelected = false
        }
        
        await saveContextAsync()
    }
    
    private func fetchDefaultContent() async {
        // Fetch default nature sounds and backgrounds
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.populateDefaultSounds()
            }
            
            group.addTask {
                BackgroundEntity.fetchPics(completion: { _ in }, withSearchTags: "ocean,waves,rain,wind,waterfall,stream,forest,fire")
            }
        }
    }
    
    @MainActor
    private func populateDefaultSounds() async {
        let defaultSounds: [(String, String, String?)] = [
            ("Thunder Storm", "ThunderStorm.mp3", nil),
            ("Campfire", "campfire.mp3", nil),
            ("Crickets", "crickets.mp3", nil),
            ("Forest", "forest.mp3", nil),
            ("Frogs", "frogs.mp3", nil),
            ("Heavy Rain", "heavy-rain.mp3", nil),
            ("Lake Waves", "lake-waves.mp3", nil),
            ("Rain", "rain.mp3", nil),
            ("Stream", "stream.mp3", nil),
            ("Waterfall", "waterfall.mp3", nil),
            ("Waves", "waves.mp3", nil),
            ("Wind", "wind.mp3", nil)
        ]
        
        let context = managedObjectContext
        
        // Check if default sounds already exist to prevent duplicates
        let existingSounds = fetchAllSounds()
        let existingTitles = Set(existingSounds.compactMap { $0.bTitle })
        
        for (title, url1, url2) in defaultSounds {
            // Only add if this sound doesn't already exist
            if !existingTitles.contains(title) {
                guard let entity = NSEntityDescription.entity(forEntityName: "Sound", in: context) else { continue }
                let sound = SoundEntity(entity: entity, insertInto: context)
                sound.bTitle = title
                sound.soundUrl1 = url1
                sound.soundUrl2 = url2
                sound.isFavorite = false
                sound.isSelected = false
            }
        }
        
        await saveContextAsync()
    }
    
    // MARK: - Database State Checking
    
    @MainActor
    func isDBNotExist() -> Bool {
        let context = managedObjectContext
        let fetchRequest = BackgroundEntity.fetchRequest()
        
        do {
            let count = try context.count(for: fetchRequest)
            
            if count < minNumBgObjects {
                isPermObjectsExist = count >= numPermanentBgObjects
                return true
            } else {
                return false
            }
        } catch {
            print("Error checking database state: \(error)")
            return true
        }
    }
    
    // MARK: - Utility Methods
    
    private func applicationDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    }
    
    // MARK: - Data Cleanup
    
    @MainActor
    func resetDefaultSoundsFavoriteStatus() async {
        let context = managedObjectContext
        let request = SoundEntity.fetchAllSounds()
        
        do {
            let allSounds = try context.fetch(request)
            var updatedCount = 0
            
            for sound in allSounds {
                // Reset favorite status for default sounds (those with .mp3 files in bundle)
                if let soundUrl = sound.soundUrl1, soundUrl.hasSuffix(".mp3") {
                    if sound.isFavorite {
                        sound.isFavorite = false
                        updatedCount += 1
                    }
                }
            }
            
            if updatedCount > 0 {
                await saveContextAsync()
                print("Reset favorite status for \(updatedCount) default sounds")
            }
        } catch {
            print("Error resetting favorite status: \(error)")
        }
    }
    
    @MainActor
    func removeDuplicateSounds() async {
        let context = managedObjectContext
        let request = SoundEntity.fetchAllSounds()
        
        do {
            let allSounds = try context.fetch(request)
            var seenTitles: Set<String> = []
            var soundsToDelete: [SoundEntity] = []
            
            for sound in allSounds {
                guard let title = sound.bTitle else { continue }
                
                if seenTitles.contains(title) {
                    // This is a duplicate
                    soundsToDelete.append(sound)
                } else {
                    seenTitles.insert(title)
                }
            }
            
            // Delete duplicates
            for sound in soundsToDelete {
                context.delete(sound)
            }
            
            if !soundsToDelete.isEmpty {
                await saveContextAsync()
                print("Removed \(soundsToDelete.count) duplicate sounds")
            }
        } catch {
            print("Error removing duplicate sounds: \(error)")
        }
    }

    // MARK: - Entity Management
    
    @MainActor
    func fetchAllSounds() -> [SoundEntity] {
        let context = managedObjectContext
        let request = SoundEntity.fetchAllSounds()
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching sounds: \(error)")
            return []
        }
    }
    
    @MainActor
    func fetchAllBackgrounds() -> [BackgroundEntity] {
        let context = managedObjectContext
        let request = BackgroundEntity.fetchAllBackgrounds()
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching backgrounds: \(error)")
            return []
        }
    }
    
    @MainActor
    func fetchSelectedSound() -> SoundEntity? {
        let context = managedObjectContext
        let request = SoundEntity.fetchSelectedSound()
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching selected sound: \(error)")
            return nil
        }
    }
    
    @MainActor
    func fetchSelectedBackground() -> BackgroundEntity? {
        let context = managedObjectContext
        let request = BackgroundEntity.fetchSelectedBackground()
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching selected background: \(error)")
            return nil
        }
    }
}