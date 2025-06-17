//
//  BackgroundEntity.swift
//  SleepMate
//
//  Created by Claude on Phase 1 Migration
//

import Foundation
import CoreData

@objc(Background)
public class BackgroundEntity: NSManagedObject, Identifiable {
    
}

extension BackgroundEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<BackgroundEntity> {
        return NSFetchRequest<BackgroundEntity>(entityName: "Background")
    }
    
    @NSManaged public var animationType: String?
    @NSManaged public var isSelected: Bool
    @NSManaged public var isFavorite: Bool
    @NSManaged public var speedMultiplier: Float
    @NSManaged public var intensityLevel: Int32
    @NSManaged public var colorTheme: String?
}

// MARK: - Convenience Methods
extension BackgroundEntity {
    static func fetchAllBackgrounds() -> NSFetchRequest<BackgroundEntity> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \BackgroundEntity.animationType, ascending: true)]
        return request
    }
    
    static func fetchSelectedBackground() -> NSFetchRequest<BackgroundEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isSelected == TRUE")
        request.fetchLimit = 1
        return request
    }
    
    static func fetchFavoriteBackgrounds() -> NSFetchRequest<BackgroundEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isFavorite == TRUE")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \BackgroundEntity.animationType, ascending: true)]
        return request
    }
    
    static func fetchByCategory(_ category: BackgroundCategory) -> NSFetchRequest<BackgroundEntity> {
        let request = fetchRequest()
        let animationTypes = AnimationRegistry.shared.animationsForCategory(category).map { $0.id }
        request.predicate = NSPredicate(format: "animationType IN %@", animationTypes)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \BackgroundEntity.animationType, ascending: true)]
        return request
    }
    
    func selectBackground() {
        // Deselect all other backgrounds
        let context = self.managedObjectContext!
        let fetchRequest = BackgroundEntity.fetchRequest()
        
        do {
            let allBackgrounds = try context.fetch(fetchRequest)
            for background in allBackgrounds {
                background.isSelected = false
            }
            self.isSelected = true
        } catch {
            print("Error selecting background: \(error)")
        }
    }
    
    func toggleFavorite() {
        isFavorite.toggle()
    }
    
    var animationTitle: String {
        return AnimationRegistry.shared.animation(for: animationType ?? "")?.title ?? "Unknown Animation"
    }
    
    var category: BackgroundCategory {
        return AnimationRegistry.shared.animation(for: animationType ?? "")?.category ?? .classic
    }
}