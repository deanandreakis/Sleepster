//
//  Constants.swift
//  SleepMate
//
//  Created by Claude on Phase 1 Migration
//

import Foundation
import UIKit

// MARK: - Color Utilities
extension UIColor {
    static func fromRGB(_ rgbValue: UInt32) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0xFF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}

// MARK: - API Keys
struct APIKeys {
    static let flurryKey = "D34VV6Z525ZTGNRCJXWC"
    static let crashlyticsKey = "2eaad7ad1fecfce6c414905676a8175bb2a1c253"
}

// MARK: - StoreKit
struct StoreKit {
    struct ProductIDs {
        static let tip99 = "sleepster99"
        static let tip199 = "sleepster199" 
        static let tip499 = "sleepster499"
    }
}

// MARK: - Restoration IDs
struct RestorationIDs {
    static let mainVC = "MainViewControllerID"
    static let infoVC = "InformationViewControllerID"
    static let settingsVC = "SettingsViewControllerID"
    static let soundsVC = "SoundsViewControllerID"
    static let backgroundsVC = "BackgroundsViewControllerID"
    static let tabBarC = "UITabBarControllerID"
    static let backlightVC = "BacklightViewControllerID"
    static let timerVC = "TimerViewControllerID"
}

// MARK: - Timer Constants
struct TimerConstants {
    static let musicTimer = 0
}

// MARK: - Default Content
struct DefaultContent {
    static let defaultSounds = [
        "ThunderStorm.mp3", "campfire.mp3", "crickets.mp3", "forest.mp3",
        "frogs.mp3", "heavy-rain.mp3", "lake-waves.mp3", "rain.mp3",
        "stream.mp3", "waterfall.mp3", "waves.mp3", "wind.mp3"
    ]
}