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
    static let flickrAPIKey = "ab284ac09b04f83cf5af22e4bc3b6e56"
    static let flickrSecret = "e2e0f5b8158b1f83"
    static let flurryKey = "D34VV6Z525ZTGNRCJXWC"
    static let crashlyticsKey = "2eaad7ad1fecfce6c414905676a8175bb2a1c253"
}

// MARK: - UI Constants
struct UIConstants {
    static let flickrThumbnailSize: CGFloat = 70
}

// MARK: - StoreKit
struct StoreKit {
    static let backgroundsStatus = "enable_multiple_bg_selection"
    static let soundStatus = "enable_sound_mixing"
    
    struct ProductIDs {
        static let backgrounds = "multiplebg"
        static let sounds = "multiplesounds"
    }
}

// MARK: - Database Constants
struct DatabaseConstants {
    static let minNumBgObjects = 50
    static let numPermanentBgObjects = 20
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
    static let defaultBackgroundSearchTags = "ocean,waves,rain,wind,waterfall,stream,forest,fire"
    
    static let defaultSounds = [
        "ThunderStorm.mp3", "campfire.mp3", "crickets.mp3", "forest.mp3",
        "frogs.mp3", "heavy-rain.mp3", "lake-waves.mp3", "rain.mp3",
        "stream.mp3", "waterfall.mp3", "waves.mp3", "wind.mp3"
    ]
    
    static let defaultBackgroundColors = [
        "whiteColor", "blueColor", "redColor", "greenColor",
        "blackColor", "darkGrayColor", "lightGrayColor", "grayColor",
        "cyanColor", "yellowColor", "magentaColor", "orangeColor",
        "purpleColor", "brownColor", "clearColor"
    ]
    
    static let defaultBackgroundImages = [
        ("z_Independence Grove", "igrove_1"),
        ("z_Independence Grove_1", "grove2"),
        ("z_Independence Grove_2", "grove3"),
        ("z_Independence Grove_3", "grove4"),
        ("z_Independence Grove_4", "grove5")
    ]
}