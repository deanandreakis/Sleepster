//
//  SubscriptionManager.swift
//  SleepMate
//
//  Created by Claude on Phase 5 Migration
//

import StoreKit
import Foundation
import Combine

/// Manages subscription lifecycle and status
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // MARK: - Published Properties
    @Published var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published var currentSubscription: VerifiedSubscription?
    @Published var subscriptionGroups: [SubscriptionGroup] = []
    @Published var renewalDate: Date?
    @Published var expirationDate: Date?
    @Published var isInGracePeriod = false
    @Published var isInBillingRetryPeriod = false
    
    // MARK: - Subscription Status
    enum SubscriptionStatus: String, CaseIterable {
        case notSubscribed = "Not Subscribed"
        case subscribed = "Active"
        case expired = "Expired"
        case inGracePeriod = "Grace Period"
        case inBillingRetryPeriod = "Billing Retry"
        case revoked = "Revoked"
        
        var isActive: Bool {
            switch self {
            case .subscribed, .inGracePeriod, .inBillingRetryPeriod:
                return true
            case .notSubscribed, .expired, .revoked:
                return false
            }
        }
        
        var description: String {
            switch self {
            case .notSubscribed:
                return "No active subscription"
            case .subscribed:
                return "Subscription is active"
            case .expired:
                return "Subscription has expired"
            case .inGracePeriod:
                return "Grace period - please update payment method"
            case .inBillingRetryPeriod:
                return "Billing retry in progress"
            case .revoked:
                return "Subscription was refunded"
            }
        }
        
        var color: String {
            switch self {
            case .subscribed:
                return "green"
            case .inGracePeriod, .inBillingRetryPeriod:
                return "orange"
            case .expired, .revoked, .notSubscribed:
                return "red"
            }
        }
    }
    
    // MARK: - Subscription Group
    struct SubscriptionGroup {
        let id: String
        let products: [Product]
        let currentSubscription: VerifiedSubscription?
        
        var displayName: String {
            return "Premium Features"
        }
        
        var lowestPriceProduct: Product? {
            return products.min { product1, product2 in
                guard let price1 = product1.subscription?.subscriptionPeriod.value,
                      let price2 = product2.subscription?.subscriptionPeriod.value else {
                    return false
                }
                
                // Compare based on monthly equivalent price
                let monthly1 = NSDecimalNumber(decimal: product1.price).doubleValue / Double(price1)
                let monthly2 = NSDecimalNumber(decimal: product2.price).doubleValue / Double(price2)
                
                return monthly1 < monthly2
            }
        }
    }
    
    // MARK: - Verified Subscription
    struct VerifiedSubscription {
        let transaction: Transaction
        let renewalInfo: Product.SubscriptionInfo.RenewalInfo
        let status: Product.SubscriptionInfo.Status
        
        var productId: String {
            return transaction.productID
        }
        
        var isActive: Bool {
            // For StoreKit 2, simplify to basic active check
            return status.state == .subscribed
        }
        
        var expirationDate: Date? {
            return transaction.expirationDate
        }
        
        var autoRenewPreference: Bool {
            return renewalInfo.willAutoRenew
        }
    }
    
    private var statusUpdateTask: Task<Void, Never>?
    
    private init() {
        startStatusUpdates()
    }
    
    deinit {
        statusUpdateTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Update subscription status from App Store
    func updateSubscriptionStatus() async {
        await updateCurrentSubscriptions()
        await updateSubscriptionGroups()
    }
    
    /// Check if user has active subscription
    var hasActiveSubscription: Bool {
        return subscriptionStatus.isActive
    }
    
    /// Get subscription benefits based on current status
    var subscriptionBenefits: [String] {
        guard hasActiveSubscription else { return [] }
        
        return [
            "All premium sounds and backgrounds",
            "Advanced audio effects and equalizer",
            "Sleep tracking with HealthKit",
            "Home screen widgets",
            "Shortcuts integration",
            "Priority customer support",
            "Early access to new features",
            "No advertisements"
        ]
    }
    
    /// Get days remaining in subscription
    var daysRemaining: Int? {
        guard let expirationDate = expirationDate else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: expirationDate)
        
        return components.day
    }
    
    /// Check if subscription is about to expire (within 7 days)
    var isAboutToExpire: Bool {
        guard let days = daysRemaining else { return false }
        return days <= 7 && days > 0
    }
    
    /// Present subscription management (App Store)
    func presentSubscriptionManagement() async {
        do {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            try await AppStore.showManageSubscriptions(in: windowScene)
        } catch {
            print("Failed to present subscription management: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func startStatusUpdates() {
        statusUpdateTask = Task {
            while !Task.isCancelled {
                await updateSubscriptionStatus()
                
                // Update every hour
                try? await Task.sleep(nanoseconds: 3600 * 1_000_000_000)
            }
        }
    }
    
    private func updateCurrentSubscriptions() async {
        var activeSubscription: VerifiedSubscription?
        var status: SubscriptionStatus = .notSubscribed
        
        // Check current entitlements
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                // Only process subscription transactions
                guard transaction.productType == .autoRenewable else { continue }
                
                // Get subscription info
                if let product = await getProduct(for: transaction.productID),
                   let subscriptionInfo = try? await product.subscription?.status.first {
                    
                    guard case .verified(let renewalInfo) = subscriptionInfo.renewalInfo else { continue }
                    
                    let verifiedSubscription = VerifiedSubscription(
                        transaction: transaction,
                        renewalInfo: renewalInfo,
                        status: subscriptionInfo
                    )
                    
                    // Update status based on subscription state
                    if subscriptionInfo.state == .subscribed {
                        status = .subscribed
                        activeSubscription = verifiedSubscription
                    } else {
                        status = .notSubscribed
                    }
                    
                    // Update dates from renewal info
                    await MainActor.run {
                        // Extract renewal info from VerificationResult
                        switch subscriptionInfo.renewalInfo {
                        case .verified(let renewalInfo):
                            self.renewalDate = renewalInfo.renewalDate
                            self.expirationDate = transaction.expirationDate
                        case .unverified:
                            // Handle unverified renewal info
                            break
                        }
                        self.isInGracePeriod = false // Simplified for StoreKit 2
                        self.isInBillingRetryPeriod = false // Simplified for StoreKit 2
                    }
                }
                
            case .unverified(_, _):
                // Handle unverified transactions
                break
            }
        }
        
        await MainActor.run {
            self.subscriptionStatus = status
            self.currentSubscription = activeSubscription
        }
    }
    
    private func updateSubscriptionGroups() async {
        // For now, we have one subscription group
        // In a real app, you might have multiple subscription groups
        
        // No subscriptions in tip jar model - empty array
        let subscriptionProductIds: [String] = []
        
        do {
            let products = try await Product.products(for: subscriptionProductIds)
            let group = SubscriptionGroup(
                id: "premium_subscription",
                products: products,
                currentSubscription: currentSubscription
            )
            
            await MainActor.run {
                self.subscriptionGroups = [group]
            }
            
        } catch {
            print("Failed to load subscription products: \(error)")
        }
    }
    
    private func getProduct(for productId: String) async -> Product? {
        do {
            let products = try await Product.products(for: [productId])
            return products.first
        } catch {
            return nil
        }
    }
}

// MARK: - Subscription Extensions

// RenewalState extension removed - using Bool instead

