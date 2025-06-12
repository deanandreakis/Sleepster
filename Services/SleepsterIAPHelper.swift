//
//  SleepsterIAPHelper.swift
//  SleepMate
//
//  Ported from Objective-C by Claude Code
//  Sleepster-specific In-App Purchase helper
//

import Foundation

class SleepsterIAPHelper: IAPHelper {
    
    // MARK: - Singleton
    
    static let shared: SleepsterIAPHelper = {
        let productIdentifiers: Set<String> = [
            StoreKit.ProductIDs.backgrounds,
            StoreKit.ProductIDs.sounds
        ]
        return SleepsterIAPHelper(productIdentifiers: productIdentifiers)
    }()
    
    // MARK: - Initialization
    
    private override init(productIdentifiers: Set<String>) {
        super.init(productIdentifiers: productIdentifiers)
    }
}