//
//  CoreDataStack.swift
//  SleepMate
//
//  Created by Claude on Phase 1 Migration
//

import Foundation
import CoreData
import Combine

@MainActor
class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SleepsterModel")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Core Data save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func saveContext() async {
        await MainActor.run {
            save()
        }
    }
    
    // MARK: - Utility Methods
    
    func deleteAllEntities<T: NSManagedObject>(_ entityType: T.Type) async {
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: entityType))
        
        do {
            let objects = try viewContext.fetch(fetchRequest)
            for object in objects {
                viewContext.delete(object)
            }
            await saveContext()
        } catch {
            print("Error deleting entities: \(error)")
        }
    }
    
    func isDBEmpty() -> Bool {
        let soundRequest = NSFetchRequest<SoundEntity>(entityName: "Sound")
        let backgroundRequest = NSFetchRequest<BackgroundEntity>(entityName: "Background")
        
        do {
            let soundCount = try viewContext.count(for: soundRequest)
            let backgroundCount = try viewContext.count(for: backgroundRequest)
            return soundCount == 0 && backgroundCount == 0
        } catch {
            return true
        }
    }
}