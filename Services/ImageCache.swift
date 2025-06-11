//
//  ImageCache.swift
//  SleepMate
//
//  Created by Claude on Phase 4 Migration
//

import UIKit
import Foundation

/// High-performance image caching system with disk and memory storage
actor ImageCache {
    static let shared = ImageCache()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCache: DiskCache
    private let maxMemoryCacheSize: Int = 100 * 1024 * 1024 // 100MB
    private let maxDiskCacheSize: Int = 500 * 1024 * 1024   // 500MB
    
    private init() {
        // Configure memory cache
        memoryCache.totalCostLimit = maxMemoryCacheSize
        memoryCache.countLimit = 100
        
        // Initialize disk cache
        diskCache = DiskCache(name: "ImageCache", maxSize: maxDiskCacheSize)
        
        // Setup memory warning observer
        setupMemoryWarningObserver()
    }
    
    // MARK: - Public Interface
    
    func image(for url: URL) async -> UIImage? {
        let key = cacheKey(for: url)
        
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: key) {
            return cachedImage
        }
        
        // Check disk cache
        if let diskData = await diskCache.data(for: key),
           let image = UIImage(data: diskData) {
            // Store in memory cache for faster access
            let cost = diskData.count
            memoryCache.setObject(image, forKey: key, cost: cost)
            return image
        }
        
        return nil
    }
    
    func store(_ image: UIImage, for url: URL) async {
        let key = cacheKey(for: url)
        
        // Store in memory cache
        if let imageData = image.pngData() {
            let cost = imageData.count
            memoryCache.setObject(image, forKey: key, cost: cost)
            
            // Store in disk cache
            await diskCache.store(imageData, for: key)
        }
    }
    
    func removeImage(for url: URL) async {
        let key = cacheKey(for: url)
        memoryCache.removeObject(forKey: key)
        await diskCache.removeData(for: key)
    }
    
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    func clearAllCaches() async {
        clearMemoryCache()
        await diskCache.clearAll()
    }
    
    func cacheSize() async -> (memory: Int, disk: Int) {
        let diskSize = await diskCache.totalSize()
        return (memory: memoryCache.totalCostLimit, disk: diskSize)
    }
    
    // MARK: - Private Methods
    
    private func cacheKey(for url: URL) -> NSString {
        return url.absoluteString as NSString
    }
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleMemoryWarning()
            }
        }
    }
    
    private func handleMemoryWarning() {
        // Clear memory cache on memory warning
        clearMemoryCache()
    }
}

// MARK: - Disk Cache Implementation

private actor DiskCache {
    private let cacheDirectory: URL
    private let maxSize: Int
    private let fileManager = FileManager.default
    
    init(name: String, maxSize: Int) {
        self.maxSize = maxSize
        
        // Create cache directory
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = cacheDir.appendingPathComponent(name)
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Start cleanup task
        Task {
            await performCleanupIfNeeded()
        }
    }
    
    func data(for key: NSString) -> Data? {
        let fileURL = fileURL(for: key)
        return try? Data(contentsOf: fileURL)
    }
    
    func store(_ data: Data, for key: NSString) {
        let fileURL = fileURL(for: key)
        
        do {
            try data.write(to: fileURL)
            
            // Check if cleanup is needed after storing
            Task {
                await performCleanupIfNeeded()
            }
        } catch {
            print("Failed to store data to disk cache: \(error)")
        }
    }
    
    func removeData(for key: NSString) {
        let fileURL = fileURL(for: key)
        try? fileManager.removeItem(at: fileURL)
    }
    
    func clearAll() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for fileURL in contents {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Failed to clear disk cache: \(error)")
        }
    }
    
    func totalSize() -> Int {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey]
            )
            
            return contents.reduce(0) { total, url in
                do {
                    let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                    return total + (resourceValues.fileSize ?? 0)
                } catch {
                    return total
                }
            }
        } catch {
            return 0
        }
    }
    
    private func fileURL(for key: NSString) -> URL {
        let fileName = key.hash.description
        return cacheDirectory.appendingPathComponent(fileName)
    }
    
    private func performCleanupIfNeeded() {
        let currentSize = totalSize()
        
        if currentSize > maxSize {
            // Remove oldest files until we're under the limit
            do {
                let contents = try fileManager.contentsOfDirectory(
                    at: cacheDirectory,
                    includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
                )
                
                // Sort by modification date (oldest first)
                let sortedFiles = contents.sorted { url1, url2 in
                    do {
                        let date1 = try url1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
                        let date2 = try url2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
                        return date1 < date2
                    } catch {
                        return false
                    }
                }
                
                var sizeToRemove = currentSize - maxSize
                
                for fileURL in sortedFiles {
                    guard sizeToRemove > 0 else { break }
                    
                    do {
                        let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                        let fileSize = resourceValues.fileSize ?? 0
                        
                        try fileManager.removeItem(at: fileURL)
                        sizeToRemove -= fileSize
                    } catch {
                        print("Failed to remove cached file: \(error)")
                    }
                }
            } catch {
                print("Failed to cleanup disk cache: \(error)")
            }
        }
    }
}