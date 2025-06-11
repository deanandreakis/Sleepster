//
//  PurchaseValidator.swift
//  SleepMate
//
//  Created by Claude on Phase 5 Migration
//

import StoreKit
import Foundation
import CryptoKit

/// Handles purchase validation and receipt verification
@MainActor
class PurchaseValidator: ObservableObject {
    static let shared = PurchaseValidator()
    
    @Published var validationInProgress = false
    @Published var lastValidationDate: Date?
    @Published var validationError: String?
    
    private let userDefaults = UserDefaults.standard
    private let validationDateKey = "LastValidationDate"
    
    private init() {
        lastValidationDate = userDefaults.object(forKey: validationDateKey) as? Date
    }
    
    // MARK: - Public Methods
    
    /// Validate all current purchases
    func validateAllPurchases() async -> Bool {
        validationInProgress = true
        validationError = nil
        
        var allValid = true
        
        // Validate current entitlements
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                let isValid = await validateTransaction(transaction)
                if !isValid {
                    allValid = false
                    print("Transaction validation failed for: \(transaction.productID)")
                }
            case .unverified(let transaction, let error):
                allValid = false
                validationError = "Unverified transaction: \(error.localizedDescription)"
                print("Unverified transaction for \(transaction.productID): \(error)")
            }
        }
        
        // Update validation date
        let now = Date()
        userDefaults.set(now, forKey: validationDateKey)
        lastValidationDate = now
        
        validationInProgress = false
        return allValid
    }
    
    /// Validate a specific transaction
    func validateTransaction(_ transaction: Transaction) async -> Bool {
        // Check transaction signature
        guard await verifyTransactionSignature(transaction) else {
            return false
        }
        
        // Check transaction is not revoked
        guard transaction.revocationDate == nil else {
            return false
        }
        
        // Check transaction is for our app
        guard isValidAppTransaction(transaction) else {
            return false
        }
        
        // Additional custom validation logic
        return await performCustomValidation(transaction)
    }
    
    /// Restore and validate completed transactions
    func restoreAndValidateTransactions() async -> RestoreResult {
        do {
            // Trigger App Store sync
            try await AppStore.sync()
            
            var restoredCount = 0
            var failedCount = 0
            var productIds: Set<String> = []
            
            // Validate all current entitlements after sync
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    if await validateTransaction(transaction) {
                        restoredCount += 1
                        productIds.insert(transaction.productID)
                    } else {
                        failedCount += 1
                    }
                case .unverified(_, _):
                    failedCount += 1
                }
            }
            
            // Update StoreKit manager
            await StoreKitManager.shared.loadProducts()
            
            return RestoreResult(
                success: true,
                restoredCount: restoredCount,
                failedCount: failedCount,
                productIds: productIds,
                errorMessage: nil
            )
            
        } catch {
            return RestoreResult(
                success: false,
                restoredCount: 0,
                failedCount: 0,
                productIds: [],
                errorMessage: error.localizedDescription
            )
        }
    }
    
    /// Check if validation is needed (every 24 hours)
    var needsValidation: Bool {
        guard let lastValidation = lastValidationDate else { return true }
        
        let twentyFourHoursAgo = Date().addingTimeInterval(-24 * 60 * 60)
        return lastValidation < twentyFourHoursAgo
    }
    
    // MARK: - Private Methods
    
    private func verifyTransactionSignature(_ transaction: Transaction) async -> Bool {
        // StoreKit 2 automatically verifies transaction signatures
        // This is handled by the Transaction.currentEntitlements
        // and Product.purchase() methods
        return true
    }
    
    private func isValidAppTransaction(_ transaction: Transaction) -> Bool {
        // Verify this transaction is for our app's products
        let validProductIds = StoreKitManager.ProductType.allCases.map { $0.rawValue }
        return validProductIds.contains(transaction.productID)
    }
    
    private func performCustomValidation(_ transaction: Transaction) async -> Bool {
        // Custom validation logic specific to Sleepster
        
        // Check if transaction is recent enough (not older than 1 year for non-subscriptions)
        if transaction.productType != .autoRenewable {
            let oneYearAgo = Date().addingTimeInterval(-365 * 24 * 60 * 60)
            if transaction.purchaseDate < oneYearAgo {
                print("Transaction is too old: \(transaction.productID)")
                return false
            }
        }
        
        // Check transaction environment matches our app configuration
        #if DEBUG
        // In debug builds, allow sandbox transactions
        return true
        #else
        // In production, only allow production transactions
        return transaction.environment == .production
        #endif
    }
}

// MARK: - Restore Result

struct RestoreResult {
    let success: Bool
    let restoredCount: Int
    let failedCount: Int
    let productIds: Set<String>
    let errorMessage: String?
    
    var totalProcessed: Int {
        return restoredCount + failedCount
    }
    
    var hasRestoredItems: Bool {
        return restoredCount > 0
    }
    
    var displayMessage: String {
        if !success {
            return errorMessage ?? "Restore failed"
        }
        
        if hasRestoredItems {
            return "Successfully restored \(restoredCount) purchase\(restoredCount == 1 ? "" : "s")"
        } else {
            return "No purchases found to restore"
        }
    }
}

// MARK: - Purchase Entitlement Manager

@MainActor
class PurchaseEntitlementManager: ObservableObject {
    static let shared = PurchaseEntitlementManager()
    
    @Published var entitlements: Set<String> = []
    @Published var lastUpdateDate: Date?
    
    private init() {
        Task {
            await updateEntitlements()
        }
    }
    
    /// Update current entitlements from StoreKit
    func updateEntitlements() async {
        var currentEntitlements: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                // Only include non-revoked transactions
                if transaction.revocationDate == nil {
                    currentEntitlements.insert(transaction.productID)
                }
            case .unverified(_, _):
                // Don't include unverified transactions
                break
            }
        }
        
        entitlements = currentEntitlements
        lastUpdateDate = Date()
        
        // Notify other parts of the app about entitlement changes
        NotificationCenter.default.post(
            name: NSNotification.Name("EntitlementsUpdated"),
            object: nil,
            userInfo: ["entitlements": entitlements]
        )
    }
    
    /// Check if user has entitlement for a specific product
    func hasEntitlement(for productId: String) -> Bool {
        return entitlements.contains(productId)
    }
    
    /// Check if user has premium entitlements
    var hasPremiumEntitlements: Bool {
        return hasEntitlement(for: StoreKitManager.ProductType.premiumPack.rawValue) ||
               hasEntitlement(for: StoreKitManager.ProductType.yearlySubscription.rawValue)
    }
    
    /// Check if user has background entitlements
    var hasBackgroundEntitlements: Bool {
        return hasEntitlement(for: StoreKitManager.ProductType.multipleBackgrounds.rawValue) ||
               hasPremiumEntitlements
    }
    
    /// Check if user has sound mixing entitlements
    var hasSoundMixingEntitlements: Bool {
        return hasEntitlement(for: StoreKitManager.ProductType.multipleSounds.rawValue) ||
               hasPremiumEntitlements
    }
}

// MARK: - Transaction Monitoring

class TransactionMonitor {
    static let shared = TransactionMonitor()
    
    private var monitoringTask: Task<Void, Error>?
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        monitoringTask = Task.detached {
            for await result in Transaction.updates {
                await self.handleTransactionUpdate(result)
            }
        }
    }
    
    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }
    
    @MainActor
    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            // Handle verified transaction
            await processVerifiedTransaction(transaction)
            
        case .unverified(let transaction, let error):
            // Handle unverified transaction
            print("Unverified transaction update for \(transaction.productID): \(error)")
            
            // Notify error handler
            ErrorHandler.shared.handle(
                error,
                shouldPresent: false,
                context: "Transaction verification failed"
            )
        }
    }
    
    private func processVerifiedTransaction(_ transaction: Transaction) async {
        // Finish the transaction
        await transaction.finish()
        
        // Update entitlements
        await PurchaseEntitlementManager.shared.updateEntitlements()
        
        // Update subscription status if applicable
        if transaction.productType == .autoRenewable {
            await SubscriptionManager.shared.updateSubscriptionStatus()
        }
        
        // Post notification for UI updates
        await MainActor.run {
            NotificationCenter.default.post(
                name: NSNotification.Name("TransactionProcessed"),
                object: nil,
                userInfo: [
                    "productId": transaction.productID,
                    "transactionId": transaction.id
                ]
            )
        }
    }
}