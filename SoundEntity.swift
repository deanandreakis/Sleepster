//
//  SoundEntity.swift
//  SleepMate
//
//  Created by Claude on Phase 1 Migration
//

import Foundation
import CoreData

@objc(Sound)
public class SoundEntity: NSManagedObject, Identifiable {
    
}

extension SoundEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SoundEntity> {
        return NSFetchRequest<SoundEntity>(entityName: "Sound")
    }
    
    @NSManaged public var bTitle: String?
    @NSManaged public var soundUrl1: String?
    @NSManaged public var soundUrl2: String?
    @NSManaged public var isSelected: Bool
    @NSManaged public var isFavorite: Bool
    @NSManaged public var isSelectedForMixing: Bool
}

// MARK: - Convenience Methods
extension SoundEntity {
    static func fetchAllSounds() -> NSFetchRequest<SoundEntity> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SoundEntity.bTitle, ascending: true)]
        return request
    }
    
    static func fetchSelectedSound() -> NSFetchRequest<SoundEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isSelected == TRUE")
        request.fetchLimit = 1
        return request
    }
    
    static func fetchSelectedSoundsForMixing() -> NSFetchRequest<SoundEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isSelectedForMixing == TRUE")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SoundEntity.bTitle, ascending: true)]
        return request
    }
    
    static func fetchFavoriteSounds() -> NSFetchRequest<SoundEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isFavorite == TRUE")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SoundEntity.bTitle, ascending: true)]
        return request
    }
    
    func selectSound() {
        // Deselect all other sounds
        let context = self.managedObjectContext!
        let fetchRequest = SoundEntity.fetchRequest()
        
        do {
            let allSounds = try context.fetch(fetchRequest)
            for sound in allSounds {
                sound.isSelected = false
            }
            self.isSelected = true
        } catch {
            print("Error selecting sound: \(error)")
        }
    }
    
    func toggleFavorite() {
        isFavorite.toggle()
    }
    
    func addToMix() {
        isSelectedForMixing = true
    }
    
    func removeFromMix() {
        isSelectedForMixing = false
    }
    
    func toggleMixSelection() {
        isSelectedForMixing.toggle()
    }
}