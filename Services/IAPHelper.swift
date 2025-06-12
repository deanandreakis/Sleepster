//
//  IAPHelper.swift
//  SleepMate
//
//  Ported from Objective-C by Claude Code
//  Modern Swift implementation of In-App Purchase functionality
//

import Foundation
import StoreKit

// MARK: - Notifications

extension Notification.Name {
    static let IAPHelperProductPurchased = Notification.Name("IAPHelperProductPurchasedNotification")
    static let IAPHelperTransactionFailed = Notification.Name("IAPHelperTransactionFailedNotification")
}

// MARK: - Completion Handler

typealias RequestProductsCompletionHandler = (Bool, [SKProduct]?) -> Void

// MARK: - IAPHelper Class

class IAPHelper: NSObject {
    
    // MARK: - Properties
    
    private let productIdentifiers: Set<String>
    private var purchasedProductIdentifiers = Set<String>()
    private var productsRequest: SKProductsRequest?
    private var completionHandler: RequestProductsCompletionHandler?
    
    // MARK: - Initialization
    
    init(productIdentifiers: Set<String>) {
        self.productIdentifiers = productIdentifiers
        
        super.init()
        
        // Check for previously purchased products
        for productIdentifier in productIdentifiers {
            let productPurchased = UserDefaults.standard.bool(forKey: productIdentifier)
            if productPurchased {
                purchasedProductIdentifiers.insert(productIdentifier)
            }
        }
        
        // Add transaction observer
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    // MARK: - Public Methods
    
    func requestProducts(completionHandler: @escaping RequestProductsCompletionHandler) {
        self.completionHandler = completionHandler
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    func buyProduct(_ product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func productPurchased(_ productIdentifier: String) -> Bool {
        return purchasedProductIdentifiers.contains(productIdentifier)
    }
    
    func restoreCompletedTransactions() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // MARK: - Private Methods
    
    private func provideContent(for productIdentifier: String) {
        purchasedProductIdentifiers.insert(productIdentifier)
        UserDefaults.standard.set(true, forKey: productIdentifier)
        UserDefaults.standard.synchronize()
        
        NotificationCenter.default.post(
            name: .IAPHelperProductPurchased,
            object: productIdentifier,
            userInfo: nil
        )
    }
    
    private func transactionFailed(for productIdentifier: String) {
        NotificationCenter.default.post(
            name: .IAPHelperTransactionFailed,
            object: productIdentifier,
            userInfo: nil
        )
    }
}

// MARK: - SKProductsRequestDelegate

extension IAPHelper: SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        productsRequest = nil
        
        let skProducts = response.products
        completionHandler?(true, skProducts)
        completionHandler = nil
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        productsRequest = nil
        
        completionHandler?(false, nil)
        completionHandler = nil
    }
}

// MARK: - SKPaymentTransactionObserver

extension IAPHelper: SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                completeTransaction(transaction)
            case .failed:
                failedTransaction(transaction)
            case .restored:
                restoreTransaction(transaction)
            case .deferred, .purchasing:
                break
            @unknown default:
                break
            }
        }
    }
    
    private func completeTransaction(_ transaction: SKPaymentTransaction) {
        provideContent(for: transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func restoreTransaction(_ transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else {
            return
        }
        
        provideContent(for: productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func failedTransaction(_ transaction: SKPaymentTransaction) {
        if let error = transaction.error as? SKError,
           error.code != .paymentCancelled {
            // Log error if needed (but not payment cancelled)
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
        transactionFailed(for: transaction.payment.productIdentifier)
    }
}