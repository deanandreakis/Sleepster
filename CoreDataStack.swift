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
    
    @Published var isInitialized = false
    private var _persistentContainer: NSPersistentContainer?
    
    private init() {}
    
    var persistentContainer: NSPersistentContainer {
        if let container = _persistentContainer {
            return container
        } else {
            // Fallback synchronous creation - should only happen after async init
            let container = NSPersistentContainer(name: "SleepsterModel")
            container.loadPersistentStores { _, _ in }
            container.viewContext.automaticallyMergesChangesFromParent = true
            _persistentContainer = container
            return container
        }
    }
    
    func initializeAsync() async {
        guard !isInitialized else { 
            NSLog("📱 CoreDataStack: Already initialized")
            return 
        }
        
        NSLog("📱 CoreDataStack: Starting async initialization...")
        
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                NSLog("📱 CoreDataStack: Creating persistent container...")
                let container = NSPersistentContainer(name: "SleepsterModel")
                container.loadPersistentStores { _, error in
                    if let error = error as NSError? {
                        NSLog("📱 CoreDataStack: ERROR - %@, %@", error.localizedDescription, error.userInfo.description)
                        // Don't crash the app, just log and continue
                    } else {
                        NSLog("📱 CoreDataStack: Persistent stores loaded successfully")
                    }
                    
                    container.viewContext.automaticallyMergesChangesFromParent = true
                    
                    DispatchQueue.main.async {
                        NSLog("📱 CoreDataStack: Setting isInitialized = true")
                        self?._persistentContainer = container
                        self?.isInitialized = true
                        continuation.resume()
                        NSLog("📱 CoreDataStack: Initialization complete!")
                    }
                }
            }
        }
    }
    
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