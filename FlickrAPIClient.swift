//
//  FlickrAPIClient.swift
//  SleepMate
//
//  Created by Claude on Phase 1 Migration
//  Legacy Flickr client - bridging to modern FlickrService
//

import Foundation

// Legacy FlickrAPIClient for backward compatibility
// Uses modern FlickrService under the hood
class FlickrAPIClient {
    static let shared = FlickrAPIClient()
    
    private let flickrService = FlickrService.shared
    
    private init() {}
    
    // MARK: - Legacy Photo Search (for compatibility)
    
    func searchPhotos(
        tags: String,
        perPage: Int = 20,
        completion: @escaping (Result<[FlickrPhoto], NetworkError>) -> Void
    ) {
        Task {
            let result = await flickrService.searchPhotos(tags: tags, perPage: perPage)
            await MainActor.run {
                switch result {
                case .success(let response):
                    completion(.success(response.photos.photo))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Async/Await Support
    
    func searchPhotos(tags: String, perPage: Int = 20) async throws -> [FlickrPhoto] {
        let result = await flickrService.searchPhotos(tags: tags, perPage: perPage)
        switch result {
        case .success(let response):
            return response.photos.photo
        case .failure(let error):
            throw error
        }
    }
}