//
//  FlickrService.swift
//  SleepMate
//
//  Created by Claude on Phase 4 Migration
//

import Foundation
import UIKit
import CoreData

/// Modern async/await based Flickr API service
actor FlickrService {
    static let shared = FlickrService()
    
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let apiKey = "6dbd76ac76dcb9f495b15ed1caddd80a" // From Constants.h FLICKR_API_KEY
    private let baseURL = "https://api.flickr.com/services/rest/"
    private let groupId = "11011571@N00" // Nature Sounds Group ID
    
    private init() {
        // Configure URLSession with appropriate timeouts and caching
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0
        config.timeoutIntervalForResource = 30.0
        config.urlCache = URLCache(
            memoryCapacity: 20 * 1024 * 1024,   // 20MB memory cache
            diskCapacity: 100 * 1024 * 1024,    // 100MB disk cache
            diskPath: "FlickrCache"
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public API
    
    /// Search for photos with specified tags
    func searchPhotos(tags: String, page: Int = 1, perPage: Int = 50) async -> NetworkResult<FlickrSearchResponse> {
        guard await NetworkMonitor.shared.isConnected else {
            return .failure(.networkUnavailable)
        }
        
        let parameters: [String: String] = [
            "method": "flickr.photos.search",
            "api_key": apiKey,
            "tags": tags,
            "privacy_filter": "1",
            "group_id": groupId,
            "format": "json",
            "nojsoncallback": "1",
            "page": String(page),
            "per_page": String(perPage),
            "extras": "url_s,url_m,url_l,url_o" // Include different size URLs
        ]
        
        guard let url = buildURL(with: parameters) else {
            return .failure(.invalidURL)
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let searchResponse = try decoder.decode(FlickrSearchResponse.self, from: data)
                    return .success(searchResponse)
                } catch {
                    return .failure(.decodingError(error))
                }
            case 401:
                return .failure(.unauthorized)
            case 429:
                return .failure(.rateLimited)
            case 500...599:
                return .failure(.serverError("Server temporarily unavailable"))
            default:
                return .failure(.httpError(httpResponse.statusCode))
            }
            
        } catch {
            if error.localizedDescription.contains("timeout") {
                return .failure(.timeout)
            } else {
                return .failure(.unknown(error))
            }
        }
    }
    
    /// Download image from URL with caching
    func downloadImage(from url: URL) async -> UIImage? {
        // Check cache first
        if let cachedImage = await ImageCache.shared.image(for: url) {
            return cachedImage
        }
        
        // Download if not cached
        do {
            let (data, _) = try await session.data(from: url)
            
            if let image = UIImage(data: data) {
                // Store in cache
                await ImageCache.shared.store(image, for: url)
                return image
            }
            
        } catch {
            print("Failed to download image from \(url): \(error)")
        }
        
        return nil
    }
    
    /// Get popular tags for discovery
    func getPopularTags() async -> NetworkResult<[String]> {
        // Return predefined popular tags for nature sounds/backgrounds
        let popularTags = [
            "ocean", "forest", "rain", "thunder", "waterfall",
            "stream", "river", "lake", "mountain", "sunset",
            "sunrise", "clouds", "sky", "trees", "nature",
            "peaceful", "calm", "relaxing", "meditation", "zen"
        ]
        
        return .success(popularTags)
    }
    
    // MARK: - Private Methods
    
    private func buildURL(with parameters: [String: String]) -> URL? {
        guard var components = URLComponents(string: baseURL) else {
            return nil
        }
        
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.url
    }
}

// MARK: - Response Models

struct FlickrSearchResponse: Codable {
    let photos: FlickrPhotosContainer
    let stat: String
    
    struct FlickrPhotosContainer: Codable {
        let page: Int
        let pages: Int
        let perpage: Int
        let total: Int
        let photo: [FlickrPhoto]
    }
}

struct FlickrPhoto: Codable, Identifiable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
    
    // Optional URLs for different sizes
    let url_s: String?  // Small 240x240
    let url_m: String?  // Medium 500x500  
    let url_l: String?  // Large 1024x1024
    let url_o: String?  // Original
    
    // Computed properties for convenience
    var thumbnailURL: URL? {
        guard let urlString = url_s else { return nil }
        return URL(string: urlString)
    }
    
    var mediumURL: URL? {
        guard let urlString = url_m else { return nil }
        return URL(string: urlString)
    }
    
    var largeURL: URL? {
        guard let urlString = url_l else { return nil }
        return URL(string: urlString)
    }
    
    var originalURL: URL? {
        guard let urlString = url_o else { return nil }
        return URL(string: urlString)
    }
    
    /// Get the best available URL for the requested size
    func bestURL(for size: ImageSize) -> URL? {
        switch size {
        case .thumbnail:
            return thumbnailURL ?? mediumURL ?? largeURL
        case .medium:
            return mediumURL ?? largeURL ?? thumbnailURL
        case .large:
            return largeURL ?? originalURL ?? mediumURL ?? thumbnailURL
        case .original:
            return originalURL ?? largeURL ?? mediumURL ?? thumbnailURL
        }
    }
    
    enum ImageSize {
        case thumbnail, medium, large, original
    }
}

// MARK: - Convenience Extensions

extension FlickrPhoto {
    /// Convert to BackgroundEntity for Core Data storage
    func toBackgroundEntity(context: NSManagedObjectContext) -> BackgroundEntity? {
        guard let entity = NSEntityDescription.entity(forEntityName: "Background", in: context) else {
            return nil
        }
        
        let background = BackgroundEntity(entity: entity, insertInto: context)
        background.bTitle = title
        background.bThumbnailUrl = url_s ?? ""
        background.bFullSizeUrl = url_l ?? url_m ?? url_s ?? ""
        background.isLocalImage = false
        background.isFavorite = false
        background.isSelected = false
        
        return background
    }
}