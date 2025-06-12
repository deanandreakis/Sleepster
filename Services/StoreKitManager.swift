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
        case multipleBackgrounds = "multiplebg"
        case multipleSounds = "multiplesounds"
        case premiumPack = "premium_pack"
        case yearlySubscription = "yearly_subscription"
        
        var displayName: String {
            switch self {
            case .multipleBackgrounds:
                return "Multiple Backgrounds"
            case .multipleSounds:
                return "Sound Mixing"
            case .premiumPack:
                return "Premium Pack"
            case .yearlySubscription:
                return "Premium Yearly"
            }
        }
        
        var description: String {
            switch self {
            case .multipleBackgrounds:
                return "Unlock unlimited background images and Flickr search"
            case .multipleSounds:
                return "Mix multiple nature sounds simultaneously"
            case .premiumPack:
                return "All premium features + advanced audio effects"
            case .yearlySubscription:
                return "All features + sleep tracking + widgets + priority support"
            }
        }
        
        var benefits: [String] {
            switch self {
            case .multipleBackgrounds:
                return [
                    "Unlimited background images",
                    "Flickr photo search",
                    "Custom backgrounds",
                    "High-resolution images"
                ]
            case .multipleSounds:
                return [
                    "Mix up to 5 sounds",
                    "Individual volume controls",
                    "Sound presets",
                    "Custom combinations"
                ]
            case .premiumPack:
                return [
                    "All background features",
                    "All sound mixing features",
                    "10-band equalizer",
                    "Audio effects (reverb, delay)",
                    "Premium sound library"
                ]
            case .yearlySubscription:
                return [
                    "Everything in Premium Pack",
                    "Sleep tracking with HealthKit",
                    "Home screen widgets",
                    "Shortcuts integration",
                    "Priority customer support",
                    "Early access to new features"
                ]
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
                }
                
            case .userCancelled:
                // User cancelled the purchase
                break
                
            case .pending:
                // Purchase is pending (e.g., parental approval required)
                errorMessage = "Purchase is pending approval"
                
            @unknown default:
                errorMessage = "Unknown purchase result"
            }
            
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
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
    
    /// Check if any premium feature is unlocked
    var hasPremiumAccess: Bool {
        return isPurchased(ProductType.premiumPack.rawValue) ||
               isPurchased(ProductType.yearlySubscription.rawValue)
    }
    
    /// Check if background features are unlocked
    var hasBackgroundAccess: Bool {
        return isPurchased(ProductType.multipleBackgrounds.rawValue) || hasPremiumAccess
    }
    
    /// Check if sound mixing is unlocked
    var hasSoundMixingAccess: Bool {
        return isPurchased(ProductType.multipleSounds.rawValue) || hasPremiumAccess
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
    
    private let swiftManager = StoreKitManager.shared
    
    @MainActor
    @objc func hasBackgroundAccess() -> Bool {
        return swiftManager.hasBackgroundAccess
    }
    
    @MainActor
    @objc func hasSoundMixingAccess() -> Bool {
        return swiftManager.hasSoundMixingAccess
    }
    
    @MainActor
    @objc func hasPremiumAccess() -> Bool {
        return swiftManager.hasPremiumAccess
    }
}