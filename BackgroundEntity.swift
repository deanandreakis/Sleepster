//
//  BackgroundEntity.swift
//  SleepMate
//
//  Created by Claude on Phase 1 Migration
//

import Foundation
import CoreData
import Alamofire
import SwiftyJSON

typealias PicsBlock = ([BackgroundEntity]) -> Void

@objc(BackgroundEntity)
public class BackgroundEntity: NSManagedObject, Identifiable {
    
}

extension BackgroundEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<BackgroundEntity> {
        return NSFetchRequest<BackgroundEntity>(entityName: "Background")
    }
    
    @NSManaged public var bTitle: String?
    @NSManaged public var bFullSizeUrl: String?
    @NSManaged public var bThumbnailUrl: String?
    @NSManaged public var bColor: String?
    @NSManaged public var isImage: Bool
    @NSManaged public var isFavorite: Bool
    @NSManaged public var isSelected: Bool
    @NSManaged public var isLocalImage: Bool
}

// MARK: - Convenience Methods
extension BackgroundEntity {
    static func fetchAllBackgrounds() -> NSFetchRequest<BackgroundEntity> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \BackgroundEntity.bTitle, ascending: true)]
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
        request.sortDescriptors = [NSSortDescriptor(keyPath: \BackgroundEntity.bTitle, ascending: true)]
        return request
    }
    
    static func fetchLocalBackgrounds() -> NSFetchRequest<BackgroundEntity> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isLocalImage == TRUE")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \BackgroundEntity.bTitle, ascending: true)]
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
}

// MARK: - Flickr API Integration
extension BackgroundEntity {
    static func fetchPics(completion: @escaping PicsBlock, withSearchTags searchTags: String) {
        let flickrAPIKey = APIKeys.flickrAPIKey
        let baseURL = "https://api.flickr.com/services/rest/"
        
        let parameters: [String: Any] = [
            "method": "flickr.photos.search",
            "api_key": flickrAPIKey,
            "tags": searchTags,
            "format": "json",
            "nojsoncallback": "1",
            "per_page": "20",
            "extras": "url_s,url_m"
        ]
        
        AF.request(baseURL, parameters: parameters).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                var backgrounds: [BackgroundEntity] = []
                
                if let photos = json["photos"]["photo"].array {
                    let context = CoreDataStack.shared.viewContext
                    
                    for photo in photos {
                        let background = BackgroundEntity(context: context)
                        background.bTitle = photo["title"].stringValue
                        background.bThumbnailUrl = photo["url_s"].string
                        background.bFullSizeUrl = photo["url_m"].string
                        background.isImage = true
                        background.isLocalImage = false
                        background.isFavorite = false
                        background.isSelected = false
                        
                        backgrounds.append(background)
                    }
                    
                    CoreDataStack.shared.save()
                }
                
                DispatchQueue.main.async {
                    completion(backgrounds)
                }
                
            case .failure(let error):
                print("Flickr API error: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
}