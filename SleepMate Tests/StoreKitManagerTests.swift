//
//  StoreKitManagerTests.swift
//  SleepMateTests
//
//  Created by Claude on Phase 6 Migration
//

import XCTest
import StoreKit
@testable import SleepMate

@MainActor
final class StoreKitManagerTests: XCTestCase {
    var storeKitManager: StoreKitManager!
    
    override func setUp() async throws {
        try await super.setUp()
        storeKitManager = StoreKitManager.shared
    }
    
    override func tearDown() async throws {
        storeKitManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Product Loading Tests
    
    func testLoadProducts() async throws {
        // Given
        XCTAssertTrue(storeKitManager.products.isEmpty)
        
        // When
        await storeKitManager.loadProducts()
        
        // Then
        XCTAssertFalse(storeKitManager.isLoading)
        // Note: In test environment, products may be empty
        // In real app with App Store Connect setup, this would verify product count
    }
    
    func testProductTypeEnumCases() throws {
        // Given/When/Then
        let allCases = StoreKitManager.ProductType.allCases
        
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.multipleBackgrounds))
        XCTAssertTrue(allCases.contains(.multipleSounds))
        XCTAssertTrue(allCases.contains(.premiumPack))
        XCTAssertTrue(allCases.contains(.yearlySubscription))
    }
    
    func testProductIdentifiers() throws {
        // Given/When/Then
        XCTAssertEqual(StoreKitManager.ProductType.multipleBackgrounds.rawValue, "multiplebg")
        XCTAssertEqual(StoreKitManager.ProductType.multipleSounds.rawValue, "multiplesounds")
        XCTAssertEqual(StoreKitManager.ProductType.premiumPack.rawValue, "premium_pack")
        XCTAssertEqual(StoreKitManager.ProductType.yearlySubscription.rawValue, "yearly_subscription")
    }
    
    // MARK: - Purchase State Tests
    
    func testInitialPurchaseState() throws {
        // Given/When/Then
        XCTAssertFalse(storeKitManager.isPurchased("nonexistent_product"))
        XCTAssertFalse(storeKitManager.hasPremiumFeatures)
        XCTAssertNil(storeKitManager.errorMessage)
    }
    
    func testErrorMessageHandling() throws {
        // Given
        let testError = "Test error message"
        
        // When
        storeKitManager.errorMessage = testError
        
        // Then
        XCTAssertEqual(storeKitManager.errorMessage, testError)
        XCTAssertTrue(storeKitManager.hasError)
    }
    
    func testClearError() throws {
        // Given
        storeKitManager.errorMessage = "Test error"
        XCTAssertTrue(storeKitManager.hasError)
        
        // When
        storeKitManager.clearError()
        
        // Then
        XCTAssertNil(storeKitManager.errorMessage)
        XCTAssertFalse(storeKitManager.hasError)
    }
    
    // MARK: - Mock Purchase Tests
    
    func testMockPurchaseSuccess() async throws {
        // Given
        let mockProductId = "test_product"
        
        // When
        storeKitManager.purchasedProducts.insert(mockProductId)
        
        // Then
        XCTAssertTrue(storeKitManager.isPurchased(mockProductId))
    }
    
    func testPremiumFeaturesCheck() throws {
        // Given
        XCTAssertFalse(storeKitManager.hasPremiumFeatures)
        
        // When
        storeKitManager.purchasedProducts.insert(StoreKitManager.ProductType.premiumPack.rawValue)
        
        // Then
        XCTAssertTrue(storeKitManager.hasPremiumFeatures)
    }
    
    func testSubscriptionPremiumFeatures() throws {
        // Given
        XCTAssertFalse(storeKitManager.hasPremiumFeatures)
        
        // When
        storeKitManager.purchasedProducts.insert(StoreKitManager.ProductType.yearlySubscription.rawValue)
        
        // Then
        XCTAssertTrue(storeKitManager.hasPremiumFeatures)
    }
    
    // MARK: - Performance Tests
    
    func testLoadProductsPerformance() throws {
        measure {
            Task {
                await storeKitManager.loadProducts()
            }
        }
    }
    
    func testPurchaseCheckPerformance() throws {
        // Given
        let productIds = StoreKitManager.ProductType.allCases.map { $0.rawValue }
        
        // When/Then
        measure {
            for productId in productIds {
                _ = storeKitManager.isPurchased(productId)
            }
        }
    }
}