//
//  FlickrAPIClient.swift
//  SleepMate
//
//  Created by Claude on Phase 1 Migration
//

import Foundation
import Alamofire
import SwiftyJSON

class FlickrAPIClient {
    static let shared = FlickrAPIClient()
    
    private let baseURL = "https://api.flickr.com/services/rest/"
    private let apiKey = APIKeys.flickrAPIKey
    
    private init() {}
    
    // MARK: - Photo Search
    
    func searchPhotos(
        tags: String,
        perPage: Int = 20,
        completion: @escaping (Result<[FlickrPhoto], FlickrError>) -> Void
    ) {
        let parameters: [String: Any] = [
            "method": "flickr.photos.search",
            "api_key": apiKey,
            "tags": tags,
            "format": "json",
            "nojsoncallback": "1",
            "per_page": perPage,
            "extras": "url_s,url_m,url_l"
        ]
        
        AF.request(baseURL, parameters: parameters)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    
                    if let stat = json["stat"].string, stat == "fail" {
                        let message = json["message"].stringValue
                        completion(.failure(.apiError(message)))
                        return
                    }
                    
                    guard let photosArray = json["photos"]["photo"].array else {
                        completion(.failure(.invalidResponse))
                        return
                    }
                    
                    let photos = photosArray.compactMap { photoJSON in
                        FlickrPhoto(json: photoJSON)
                    }
                    
                    completion(.success(photos))
                    
                case .failure(let error):
                    completion(.failure(.networkError(error)))
                }
            }
    }
    
    // MARK: - Async/Await Version
    
    @available(iOS 15.0, *)
    func searchPhotos(tags: String, perPage: Int = 20) async throws -> [FlickrPhoto] {
        return try await withCheckedThrowingContinuation { continuation in
            searchPhotos(tags: tags, perPage: perPage) { result in
                continuation.resume(with: result)
            }
        }
    }
}

// MARK: - Models

struct FlickrPhoto: Codable, Identifiable {
    let id: String
    let title: String
    let thumbnailURL: String?
    let mediumURL: String?
    let largeURL: String?
    
    init?(json: JSON) {
        guard let id = json["id"].string,
              let title = json["title"].string else {
            return nil
        }
        
        self.id = id
        self.title = title
        self.thumbnailURL = json["url_s"].string
        self.mediumURL = json["url_m"].string
        self.largeURL = json["url_l"].string
    }
}

enum FlickrError: Error, LocalizedError {
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from Flickr API"
        case .apiError(let message):
            return "Flickr API error: \(message)"
        }
    }
}