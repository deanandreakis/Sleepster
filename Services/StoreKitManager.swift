//
//  StoreKitManager.swift
//  SleepMate
//
//  Created by Claude on Phase 5 Migration
//

import StoreKit
import Foundation
import Combine

/// Modern StoreKit 2 implementation for in-app purchases
@MainActor
class StoreKitManager: NSObject, ObservableObject {
    static let shared = StoreKitManager()
    
    // MARK: - Published Properties
    @Published var products: [Product] = []
    @Published var purchasedProducts: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Product Configuration
    enum ProductType: String, CaseIterable {
        case tip99 = "sleepster99"
        case tip199 = "sleepster199"
        case tip499 = "sleepster499"
        
        var displayName: String {
            switch self {
            case .tip99:
                return "Generous"
            case .tip199:
                return "Massive"
            case .tip499:
                return "Amazing"
            }
        }
        
        var description: String {
            switch self {
            case .tip99:
                return "Tip of $0.99"
            case .tip199:
                return "Tip of $1.99"
            case .tip499:
                return "Tip of $4.99"
            }
        }
        
        var emoji: String {
            switch self {
            case .tip99:
                return "☕️"
            case .tip199:
                return "🙌"
            case .tip499:
                return "🤩"
            }
        }
        
        var supportMessage: String {
            switch self {
            case .tip99:
                return "Buy me a coffee!"
            case .tip199:
                return "Show your appreciation!"
            case .tip499:
                return "You're amazing!"
            }
        }
    }
    
    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>?
    private var transactionListener: Task<Void, Error>?
    
    private override init() {
        super.init()
        
        // Start listening for transaction updates
        transactionListener = listenForTransactions()
        
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
        transactionListener?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Load available products from the App Store
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let productIdentifiers = ProductType.allCases.map { $0.rawValue }
            let storeProducts = try await Product.products(for: productIdentifiers)
            
            await MainActor.run {
                self.products = storeProducts.sorted { $0.displayName < $1.displayName }
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load products: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Purchase a product
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Check if the transaction is verified
                switch verification {
                case .verified(let transaction):
                    // Transaction is verified, update UI and finish transaction
                    await updatePurchasedProducts()
                    await transaction.finish()
                    
                    // Post success notification
                    NotificationCenter.default.post(
                        name: NSNotification.Name("PurchaseSuccessful"),
                        object: nil,
                        userInfo: ["productId": product.id]
                    )
                    
                case .unverified(_, let error):
                    // Transaction failed verification
                    errorMessage = "Purchase verification failed: \(error.localizedDescription)"
                    NotificationCenter.default.post(
                        name: NSNotification.Name("PurchaseFailed"),
                        object: nil,
                        userInfo: ["error": error]
                    )
                }
                
            case .userCancelled:
                // User cancelled the purchase
                NotificationCenter.default.post(
                    name: NSNotification.Name("PurchaseFailed"),
                    object: nil,
                    userInfo: ["cancelled": true]
                )
                
            case .pending:
                // Purchase is pending (e.g., parental approval required)
                errorMessage = "Purchase is pending approval"
                
            @unknown default:
                errorMessage = "Unknown purchase result"
            }
            
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            NotificationCenter.default.post(
                name: NSNotification.Name("PurchaseFailed"),
                object: nil,
                userInfo: ["error": error]
            )
        }
    }
    
    /// Restore completed transactions
    func restoreCompletedTransactions() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            
            NotificationCenter.default.post(
                name: NSNotification.Name("RestoreCompleted"),
                object: nil
            )
            
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }
    
    /// Check if a product is purchased
    func isPurchased(_ productId: String) -> Bool {
        return purchasedProducts.contains(productId)
    }
    
    /// Get total tip amount (sum of all tips purchased)
    var totalTipAmount: Double {
        var total: Double = 0.0
        for product in products {
            if isPurchased(product.id) {
                total += Double(truncating: product.price as NSNumber)
            }
        }
        return total
    }
    
    /// Get number of tips given
    var numberOfTips: Int {
        return purchasedProducts.count
    }
    
    // MARK: - Private Methods
    
    private func updatePurchasedProducts() async {
        var purchasedProductIds: Set<String> = []
        
        // Check for non-consumable purchases
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.revocationDate == nil {
                    purchasedProductIds.insert(transaction.productID)
                }
            case .unverified(_, _):
                // Handle unverified transactions
                break
            }
        }
        
        await MainActor.run {
            self.purchasedProducts = purchasedProductIds
        }
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                case .unverified(_, _):
                    // Handle unverified transactions
                    break
                }
            }
        }
    }
}

// MARK: - Product Extensions

extension Product {
    /// Formatted price string for display
    var formattedPrice: String {
        return "\(displayPrice)"
    }
    
    /// Check if this is a subscription product
    var isSubscription: Bool {
        return subscription != nil
    }
    
    /// Get subscription period for display
    var subscriptionPeriod: String? {
        guard let subscription = subscription else { return nil }
        
        let period = subscription.subscriptionPeriod
        switch period.unit {
        case .day:
            return period.value == 1 ? "Daily" : "\(period.value) Days"
        case .week:
            return period.value == 1 ? "Weekly" : "\(period.value) Weeks"
        case .month:
            return period.value == 1 ? "Monthly" : "\(period.value) Months"
        case .year:
            return period.value == 1 ? "Yearly" : "\(period.value) Years"
        @unknown default:
            return nil
        }
    }
}

// MARK: - Legacy Support

/// Bridge for legacy Objective-C code
@objc class StoreKitManagerObjC: NSObject {
    @objc static let shared = StoreKitManagerObjC()
    
    private var swiftManager: StoreKitManager {
        StoreKitManager.shared
    }
    
    @MainActor
    @objc func getTotalTipAmount() -> Double {
        return swiftManager.totalTipAmount
    }
    
    @MainActor
    @objc func getNumberOfTips() -> Int {
        return swiftManager.numberOfTips
    }
}