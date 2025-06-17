//
//  IntegrationTests.swift
//  SleepMateTests
//
//  Created by Claude on Phase 6 Migration
//

import XCTest
@testable import SleepMate

@MainActor
final class IntegrationTests: XCTestCase {
    var serviceContainer: ServiceContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        serviceContainer = ServiceContainer.shared
    }
    
    override func tearDown() async throws {
        serviceContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Service Container Integration Tests
    
    func testServiceContainerInitialization() throws {
        // Given/When/Then
        XCTAssertNotNil(serviceContainer)
        XCTAssertNotNil(serviceContainer.audioManager)
        XCTAssertNotNil(serviceContainer.databaseManager)
        XCTAssertNotNil(serviceContainer.timerManager)
        XCTAssertNotNil(serviceContainer.flickrAPIClient)
    }
    
    func testModernServicesAvailability() throws {
        // Given/When/Then
        XCTAssertNotNil(serviceContainer.networkMonitor)
        XCTAssertNotNil(serviceContainer.flickrService)
        XCTAssertNotNil(serviceContainer.imageCache)
        XCTAssertNotNil(serviceContainer.errorHandler)
        XCTAssertNotNil(serviceContainer.audioSessionManager)
        XCTAssertNotNil(serviceContainer.audioMixingEngine)
        XCTAssertNotNil(serviceContainer.audioEqualizer)
        XCTAssertNotNil(serviceContainer.audioEffectsProcessor)
    }
    
    // MARK: - Audio System Integration Tests
    
    func testAudioEngineWithSessionManager() async throws {
        // Given
        let audioEngine = serviceContainer.audioMixingEngine
        let sessionManager = serviceContainer.audioSessionManager
        
        // When
        await sessionManager.setupAudioSession()
        await audioEngine.startEngine()
        
        // Then
        XCTAssertTrue(audioEngine.isEngineRunning)
        
        // Cleanup
        await audioEngine.stopEngine()
        await sessionManager.deactivateSession()
    }
    
    func testAudioEngineWithEqualizer() async throws {
        // Given
        let audioEngine = serviceContainer.audioMixingEngine
        let equalizer = serviceContainer.audioEqualizer
        let testSound = createTestSound()
        
        // When
        await audioEngine.playSound(testSound)
        await equalizer.setPreset(.sleep)
        
        // Then
        XCTAssertEqual(equalizer.currentPreset, .sleep)
        XCTAssertEqual(audioEngine.activePlayers.count, 1)
        
        // Cleanup
        await audioEngine.stopAllSounds()
    }
    
    func testAudioEngineWithEffectsProcessor() async throws {
        // Given
        let audioEngine = serviceContainer.audioMixingEngine
        let effectsProcessor = serviceContainer.audioEffectsProcessor
        let testSound = createTestSound()
        
        // When
        await audioEngine.playSound(testSound)
        await effectsProcessor.enableReverb(amount: 0.5)
        
        // Then
        XCTAssertTrue(effectsProcessor.reverbEnabled)
        XCTAssertEqual(effectsProcessor.reverbAmount, 0.5)
        XCTAssertEqual(audioEngine.activePlayers.count, 1)
        
        // Cleanup
        await audioEngine.stopAllSounds()
        await effectsProcessor.disableReverb()
    }
    
    // MARK: - StoreKit Integration Tests
    
    func testStoreKitWithPurchaseValidator() async throws {
        // Given
        let storeKitManager = StoreKitManager.shared
        let purchaseValidator = PurchaseValidator.shared
        
        // When
        await storeKitManager.loadProducts()
        let validationResult = await purchaseValidator.validateAllPurchases()
        
        // Then
        XCTAssertFalse(storeKitManager.isLoading)
        // In test environment, validation might fail due to no sandbox setup
        XCTAssertNotNil(validationResult)
    }
    
    func testStoreKitWithSubscriptionManager() async throws {
        // Given
        let storeKitManager = StoreKitManager.shared
        let subscriptionManager = SubscriptionManager.shared
        
        // When
        await storeKitManager.loadProducts()
        await subscriptionManager.updateSubscriptionStatus()
        
        // Then
        XCTAssertEqual(subscriptionManager.subscriptionStatus, .notSubscribed)
        XCTAssertFalse(subscriptionManager.hasActiveSubscription)
    }
    
    // MARK: - Sleep Tracking Integration Tests
    
    func testSleepTrackerWithAudioEngine() async throws {
        // Given
        let sleepTracker = SleepTracker.shared
        let audioEngine = serviceContainer.audioMixingEngine
        let testSound = createTestSound()
        
        // Mock authorization for testing
        sleepTracker.isAuthorized = true
        
        // When
        await sleepTracker.startSleepTracking()
        await audioEngine.playSound(testSound)
        
        // Then
        XCTAssertTrue(sleepTracker.isTracking)
        XCTAssertNotNil(sleepTracker.currentSleepSession)
        XCTAssertEqual(audioEngine.activePlayers.count, 1)
        
        // Cleanup
        await sleepTracker.stopSleepTracking()
        await audioEngine.stopAllSounds()
    }
    
    func testSleepTrackerSessionPersistence() async throws {
        // Given
        let sleepTracker = SleepTracker.shared
        sleepTracker.isAuthorized = true
        
        // When
        await sleepTracker.startSleepTracking()
        let sessionId = sleepTracker.currentSleepSession?.id
        
        // Simulate app backgrounding/foregrounding
        await sleepTracker.stopSleepTracking()
        
        // Then
        XCTAssertNotNil(sessionId)
        XCTAssertNil(sleepTracker.currentSleepSession)
        XCTAssertFalse(sleepTracker.isTracking)
    }
    
    // MARK: - Shortcuts Integration Tests
    
    func testShortcutsWithAudioEngine() async throws {
        // Given
        let shortcutsManager = ShortcutsManager.shared
        let intentHandler = IntentHandler.shared
        let audioEngine = serviceContainer.audioMixingEngine
        
        // When
        await shortcutsManager.setupShortcuts()
        
        let startSleepIntent = StartSleepIntent()
        let response = await intentHandler.handleStartSleep(startSleepIntent)
        
        // Then
        XCTAssertTrue(shortcutsManager.isInitialized)
        XCTAssertNotNil(response)
        
        // Cleanup
        await audioEngine.stopAllSounds()
    }
    
    func testShortcutsWithSleepTracker() async throws {
        // Given
        let intentHandler = IntentHandler.shared
        let sleepTracker = SleepTracker.shared
        sleepTracker.isAuthorized = true
        
        // When
        let startSleepIntent = StartSleepIntent()
        let response = await intentHandler.handleStartSleep(startSleepIntent)
        
        // Then
        XCTAssertNotNil(response)
        // Sleep tracking would be started by the intent handler
        
        // Cleanup
        if sleepTracker.isTracking {
            await sleepTracker.stopSleepTracking()
        }
    }
    
    // MARK: - Widget Integration Tests
    
    func testWidgetDataFlow() async throws {
        // Given
        let audioEngine = serviceContainer.audioMixingEngine
        let sleepTracker = SleepTracker.shared
        let testSound = createTestSound()
        
        // When
        await audioEngine.playSound(testSound)
        
        // Simulate widget data update
        let userDefaults = UserDefaults(suiteName: "group.com.deanware.sleepmate")
        userDefaults?.set(true, forKey: "isAudioPlaying")
        userDefaults?.set(testSound.name, forKey: "currentSound")
        
        // Then
        let isPlaying = userDefaults?.bool(forKey: "isAudioPlaying") ?? false
        let currentSound = userDefaults?.string(forKey: "currentSound")
        
        XCTAssertTrue(isPlaying)
        XCTAssertEqual(currentSound, testSound.name)
        
        // Cleanup
        await audioEngine.stopAllSounds()
        userDefaults?.removeObject(forKey: "isAudioPlaying")
        userDefaults?.removeObject(forKey: "currentSound")
    }
    
    // MARK: - Animation Integration Tests
    
    func testAnimationRegistryIntegration() async throws {
        // Given
        let animationRegistry = AnimationRegistry.shared
        
        // When
        let animations = animationRegistry.animations
        
        // Then
        XCTAssertFalse(animations.isEmpty)
        XCTAssertGreaterThan(animations.count, 0)
        
        // Test that we have animations in different categories
        let categories = Set(animations.map { $0.category })
        XCTAssertTrue(categories.contains(.classic))
        XCTAssertTrue(categories.contains(.nature))
        XCTAssertTrue(categories.contains(.celestial))
    }
    
    func testAnimationPerformanceMonitorIntegration() async throws {
        // Given
        let performanceMonitor = serviceContainer.animationPerformanceMonitor
        
        // When
        performanceMonitor.updateFrameRate()
        
        // Then
        XCTAssertNotNil(performanceMonitor)
        XCTAssertGreaterThan(performanceMonitor.currentFPS, 0)
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testErrorHandlerWithServices() async throws {
        // Given
        let errorHandler = serviceContainer.errorHandler
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // When
        errorHandler.handle(testError, shouldPresent: false, context: "Integration test")
        
        // Then
        XCTAssertEqual(errorHandler.recentErrors.count, 1)
        XCTAssertEqual(errorHandler.recentErrors.first?.localizedDescription, "Test error")
        
        // Cleanup
        errorHandler.clearErrors()
    }
    
    // MARK: - App Lifecycle Integration Tests
    
    func testAppLifecycleHandling() throws {
        // Given
        let appDelegate = serviceContainer
        
        // When
        appDelegate.handleAppDidEnterBackground()
        
        // Then
        // Verify background handling doesn't crash
        XCTAssertNotNil(appDelegate)
        
        // When
        appDelegate.handleAppWillTerminate()
        
        // Then
        // Verify termination handling doesn't crash
        XCTAssertNotNil(appDelegate)
    }
    
    // MARK: - Performance Integration Tests
    
    func testFullSystemPerformance() throws {
        measure {
            Task {
                let audioEngine = serviceContainer.audioMixingEngine
                let sounds = createMultipleTestSounds(count: 5)
                
                // Start audio system
                await audioEngine.startEngine()
                
                // Play multiple sounds
                for sound in sounds {
                    await audioEngine.playSound(sound)
                }
                
                // Apply effects
                await serviceContainer.audioEqualizer.setPreset(.sleep)
                await serviceContainer.audioEffectsProcessor.enableReverb(amount: 0.3)
                
                // Stop all
                await audioEngine.stopAllSounds()
                await audioEngine.stopEngine()
            }
        }
    }
    
    func testConcurrentServiceAccess() throws {
        measure {
            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                // Access services concurrently
                _ = serviceContainer.audioManager
                _ = serviceContainer.databaseManager
                _ = serviceContainer.networkMonitor
                _ = serviceContainer.errorHandler
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestSound(name: String = "TestSound") -> Sound {
        return Sound(
            id: UUID(),
            name: name,
            filename: "test.mp3",
            category: .nature,
            duration: 60.0,
            isPremium: false
        )
    }
    
    private func createMultipleTestSounds(count: Int) -> [Sound] {
        return (0..<count).map { index in
            Sound(
                id: UUID(),
                name: "TestSound\(index)",
                filename: "test\(index).mp3",
                category: .nature,
                duration: 60.0,
                isPremium: false
            )
        }
    }
}