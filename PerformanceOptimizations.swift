//
//  PerformanceOptimizations.swift
//  SleepMate
//
//  Created by Claude on Phase 6 Migration
//

import Foundation
import UIKit
import SwiftUI
import Combine
import AVFoundation
import CoreData

// MARK: - Performance Monitoring

/// Monitors and optimizes app performance across different subsystems
@MainActor
class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    @Published var memoryUsage: Double = 0.0
    @Published var cpuUsage: Double = 0.0
    @Published var audioLatency: Double = 0.0
    @Published var frameRate: Double = 60.0
    
    private var monitoringTimer: Timer?
    private var isMonitoring = false
    
    private init() {
        startMonitoring()
    }
    
    // MARK: - Monitoring Control
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMetrics()
            }
        }
    }
    
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        isMonitoring = false
    }
    
    private func updateMetrics() {
        memoryUsage = getCurrentMemoryUsage()
        cpuUsage = getCurrentCPUUsage()
        audioLatency = AudioMixingEngine.shared.currentLatency
        frameRate = UIScreen.main.maximumFramesPerSecond > 0 ? Double(UIScreen.main.maximumFramesPerSecond) : 60.0
    }
    
    // MARK: - Memory Monitoring
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        } else {
            return 0.0
        }
    }
    
    private func getCurrentCPUUsage() -> Double {
        var kr: kern_return_t
        var task_info_count: mach_msg_type_number_t
        
        task_info_count = mach_msg_type_number_t(TASK_INFO_MAX)
        var tinfo = [integer_t](repeating: 0, count: Int(task_info_count))
        
        kr = task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), &tinfo, &task_info_count)
        if kr != KERN_SUCCESS {
            return 0.0
        }
        
        var thread_list: thread_act_array_t?
        var thread_count: mach_msg_type_number_t = 0
        defer {
            if let thread_list = thread_list {
                vm_deallocate(mach_task_self_, vm_address_t(UnsafePointer(thread_list).pointee), vm_size_t(thread_count))
            }
        }
        
        kr = task_threads(mach_task_self_, &thread_list, &thread_count)
        if kr != KERN_SUCCESS {
            return 0.0
        }
        
        var tot_cpu: Double = 0
        
        if let thread_list = thread_list {
            for j in 0..<Int(thread_count) {
                var thread_info_count = mach_msg_type_number_t(THREAD_INFO_MAX)
                var thinfo = [integer_t](repeating: 0, count: Int(thread_info_count))
                kr = thread_info(thread_list[j], thread_flavor_t(THREAD_BASIC_INFO), &thinfo, &thread_info_count)
                if kr != KERN_SUCCESS {
                    continue
                }
                
                let thread_basic_info = convertThreadInfo(thinfo)
                if thread_basic_info.flags & TH_FLAGS_IDLE == 0 {
                    tot_cpu += Double(thread_basic_info.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
                }
            }
        }
        
        return tot_cpu
    }
    
    private func convertThreadInfo(_ thinfo: [integer_t]) -> thread_basic_info {
        return thinfo.withUnsafeBytes {
            $0.load(as: thread_basic_info.self)
        }
    }
}

// MARK: - Memory Management

/// Optimizes memory usage across the app
class MemoryOptimizer {
    static let shared = MemoryOptimizer()
    
    private var imageCache: NSCache<NSString, UIImage>
    private var audioBufferCache: NSCache<NSString, NSData>
    
    private init() {
        imageCache = NSCache<NSString, UIImage>()
        imageCache.countLimit = 50 // Limit to 50 images
        imageCache.totalCostLimit = 100 * 1024 * 1024 // 100MB limit
        
        audioBufferCache = NSCache<NSString, NSData>()
        audioBufferCache.countLimit = 20 // Limit to 20 audio buffers
        audioBufferCache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
        
        setupMemoryWarningNotification()
    }
    
    private func setupMemoryWarningNotification() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    func handleMemoryWarning() {
        // Clear caches
        imageCache.removeAllObjects()
        audioBufferCache.removeAllObjects()
        
        // Force garbage collection and animation cleanup
        Task {
            // Clear any animation caches if implemented in Phase 2
            await AnimationRegistry.shared.animations.forEach { _ in
                // Animation cleanup will be implemented in Phase 2
            }
        }
        
        // Notify audio engine to release unused resources
        Task {
            await AudioMixingEngine.shared.releaseUnusedResources()
        }
        
        print("⚠️ Memory warning handled - caches cleared")
    }
    
    func optimizeForBackground() {
        // Reduce cache sizes when app goes to background
        imageCache.countLimit = 20
        imageCache.totalCostLimit = 30 * 1024 * 1024 // 30MB
        
        audioBufferCache.countLimit = 10
        audioBufferCache.totalCostLimit = 20 * 1024 * 1024 // 20MB
    }
    
    func optimizeForForeground() {
        // Restore full cache sizes when app returns to foreground
        imageCache.countLimit = 50
        imageCache.totalCostLimit = 100 * 1024 * 1024 // 100MB
        
        audioBufferCache.countLimit = 20
        audioBufferCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
}

// MARK: - Audio Performance Optimization

extension AudioMixingEngine {
    var currentLatency: Double {
        let audioSession = AVAudioSession.sharedInstance()
        return audioSession.outputLatency + audioSession.inputLatency
    }
    
    func releaseUnusedResources() async {
        // Remove inactive players - check if playerNode is playing
        activePlayers.removeAll { player in
            return !player.playerNode.isPlaying
        }
        
        // Optimize audio engine performance
        if activePlayers.isEmpty {
            await stopAllSounds()
        }
    }
    
    func optimizeBufferSize() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            // Set optimal buffer duration for low latency
            try audioSession.setPreferredIOBufferDuration(0.005) // 5ms for low latency
        } catch {
            print("Failed to set buffer duration: \(error)")
        }
    }
    
    func optimizeForPowerSaving() async {
        // Reduce audio quality for power saving
        await setMasterVolume(masterVolume * 0.8) // Slightly reduce volume
        
        // Use lower sample rate if possible
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setPreferredSampleRate(44100) // Standard rate instead of high-res
        } catch {
            print("Failed to set sample rate: \(error)")
        }
    }
}

// MARK: - UI Performance Optimization

/// Optimizes SwiftUI view performance
struct LazyLoadingModifier: ViewModifier {
    let threshold: CGFloat
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            if isVisible {
                content
            } else {
                Color.clear
                    .onAppear {
                        // Load content when it becomes visible
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isVisible = true
                        }
                    }
            }
        }
    }
}

extension View {
    func lazyLoading(threshold: CGFloat = 50) -> some View {
        modifier(LazyLoadingModifier(threshold: threshold))
    }
}

/// Debounces rapid updates to improve performance
class DebounceManager {
    private var workItems: [String: DispatchWorkItem] = [:]
    
    func debounce(key: String, delay: TimeInterval, action: @escaping () -> Void) {
        // Cancel previous work item
        workItems[key]?.cancel()
        
        // Create new work item
        let workItem = DispatchWorkItem(block: action)
        workItems[key] = workItem
        
        // Schedule execution
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
}

// MARK: - Animation Performance Optimization

extension AnimationRegistry {
    func optimizeAnimationLoading() {
        // Implement progressive animation loading for Phase 2
        // Load simple animations first, then complex ones
    }
    
    func preloadAnimations(for category: BackgroundCategory) async {
        // Preload animations for specific category
        let categoryAnimations = animationsForCategory(category).prefix(3)
        
        for animation in categoryAnimations {
            // Preload animation resources if needed in Phase 2
            _ = animation.previewView()
        }
    }
}

// MARK: - Core Data Performance Optimization

extension DatabaseManager {
    @MainActor
    func optimizeForBatchOperations() {
        // Use batch operations for better performance
        coreDataStack.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Enable automatic merging of changes
        coreDataStack.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                coreDataStack.persistentContainer.performBackgroundTask { context in
                    do {
                        let result = try block(context)
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    func batchDelete(entityName: String, predicate: NSPredicate) async throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
        let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        try await performBackgroundTask { context in
            try context.execute(request)
            try context.save()
        }
    }
}

// MARK: - Battery Optimization

class BatteryOptimizer {
    static let shared = BatteryOptimizer()
    
    private var isLowPowerModeEnabled: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }
    
    private init() {
        setupLowPowerModeNotification()
    }
    
    private func setupLowPowerModeNotification() {
        NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handlePowerStateChange()
        }
    }
    
    private func handlePowerStateChange() {
        if isLowPowerModeEnabled {
            enablePowerSavingMode()
        } else {
            disablePowerSavingMode()
        }
    }
    
    private func enablePowerSavingMode() {
        Task {
            // Reduce audio processing
            await AudioMixingEngine.shared.optimizeForPowerSaving()
            
            // Reduce animation frame rate
            UIView.setAnimationsEnabled(false)
            
            // Reduce background processing
            MemoryOptimizer.shared.optimizeForBackground()
            
            print("🔋 Power saving mode enabled")
        }
    }
    
    private func disablePowerSavingMode() {
        Task {
            // Restore normal audio processing
            await AudioMixingEngine.shared.optimizeBufferSize()
            
            // Restore animations
            UIView.setAnimationsEnabled(true)
            
            // Restore normal processing
            MemoryOptimizer.shared.optimizeForForeground()
            
            print("🔋 Power saving mode disabled")
        }
    }
}

// MARK: - Launch Time Optimization

class LaunchOptimizer {
    static let shared = LaunchOptimizer()
    
    private init() {}
    
    func optimizeAppLaunch() {
        // Defer non-critical initializations
        DispatchQueue.main.async {
            self.initializeNonCriticalServices()
        }
        
        // Preload essential data
        Task {
            await preloadEssentialData()
        }
    }
    
    private func initializeNonCriticalServices() {
        // Initialize services that aren't needed immediately
        _ = ShortcutsManager.shared
        _ = PerformanceMonitor.shared
        _ = BatteryOptimizer.shared
    }
    
    private func preloadEssentialData() async {
        // Preload sounds library (using database manager)
        await ServiceContainer.shared.databaseManager.prePopulate()
        
        // Preload user preferences (settings manager doesn't have async loading)
        await MainActor.run {
            _ = ServiceContainer.shared.settingsManager
        }
        
        // Initialize StoreKit (using StoreKitManager directly)
        await StoreKitManager.shared.loadProducts()
    }
}

// MARK: - Performance Testing Utilities

#if DEBUG
class PerformanceTester {
    static func measureExecutionTime<T>(
        operation: () throws -> T,
        iterations: Int = 1,
        name: String = ""
    ) rethrows -> (result: T, averageTime: TimeInterval) {
        var totalTime: TimeInterval = 0
        var result: T!
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            result = try operation()
            let endTime = CFAbsoluteTimeGetCurrent()
            totalTime += (endTime - startTime)
        }
        
        let averageTime = totalTime / Double(iterations)
        
        if !name.isEmpty {
            print("⏱️ \(name): \(String(format: "%.4f", averageTime))s (avg over \(iterations) iterations)")
        }
        
        return (result, averageTime)
    }
    
    static func measureAsyncExecutionTime<T>(
        operation: () async throws -> T,
        iterations: Int = 1,
        name: String = ""
    ) async rethrows -> (result: T, averageTime: TimeInterval) {
        var totalTime: TimeInterval = 0
        var result: T!
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            result = try await operation()
            let endTime = CFAbsoluteTimeGetCurrent()
            totalTime += (endTime - startTime)
        }
        
        let averageTime = totalTime / Double(iterations)
        
        if !name.isEmpty {
            print("⏱️ \(name): \(String(format: "%.4f", averageTime))s (avg over \(iterations) iterations)")
        }
        
        return (result, averageTime)
    }
}
#endif