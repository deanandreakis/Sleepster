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
                let monthly1 = product1.price.doubleValue / Double(price1)
                let monthly2 = product2.price.doubleValue / Double(price2)
                
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
            switch status.state {
            case .subscribed, .inGracePeriod, .inBillingRetryPeriod:
                return true
            case .expired, .revoked:
                return false
            @unknown default:
                return false
            }
        }
        
        var expirationDate: Date? {
            return status.renewalInfo.expirationDate
        }
        
        var autoRenewPreference: Product.SubscriptionInfo.RenewalState {
            return status.renewalInfo.autoRenewPreference
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
            try await AppStore.showManageSubscriptions(in: UIApplication.shared.connectedScenes.first as? UIWindowScene)
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
                    
                    let verifiedSubscription = VerifiedSubscription(
                        transaction: transaction,
                        renewalInfo: subscriptionInfo.renewalInfo,
                        status: subscriptionInfo
                    )
                    
                    // Update status based on subscription state
                    switch subscriptionInfo.state {
                    case .subscribed:
                        status = .subscribed
                        activeSubscription = verifiedSubscription
                    case .expired:
                        status = .expired
                    case .inGracePeriod:
                        status = .inGracePeriod
                        activeSubscription = verifiedSubscription
                    case .inBillingRetryPeriod:
                        status = .inBillingRetryPeriod
                        activeSubscription = verifiedSubscription
                    case .revoked:
                        status = .revoked
                    @unknown default:
                        break
                    }
                    
                    // Update dates
                    await MainActor.run {
                        self.renewalDate = subscriptionInfo.renewalInfo.renewalDate
                        self.expirationDate = subscriptionInfo.renewalInfo.expirationDate
                        self.isInGracePeriod = subscriptionInfo.state == .inGracePeriod
                        self.isInBillingRetryPeriod = subscriptionInfo.state == .inBillingRetryPeriod
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
        
        let subscriptionProductIds = [
            StoreKitManager.ProductType.yearlySubscription.rawValue
        ]
        
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

extension Product.SubscriptionInfo.Status.State {
    var displayName: String {
        switch self {
        case .subscribed:
            return "Active"
        case .expired:
            return "Expired"
        case .inGracePeriod:
            return "Grace Period"
        case .inBillingRetryPeriod:
            return "Billing Retry"
        case .revoked:
            return "Revoked"
        @unknown default:
            return "Unknown"
        }
    }
}

extension Product.SubscriptionInfo.RenewalState {
    var displayName: String {
        switch self {
        case .off:
            return "Auto-Renewal Off"
        case .on:
            return "Auto-Renewal On"
        @unknown default:
            return "Unknown"
        }
    }
}