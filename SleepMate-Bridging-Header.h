//
//  SleepMate-Bridging-Header.h
//  SleepMate
//
//  Created by Claude on Phase 1 Migration
//  This bridging header allows Swift and Objective-C code to coexist during migration
//

#ifndef SleepMate_Bridging_Header_h
#define SleepMate_Bridging_Header_h

// MARK: - Database Manager (Legacy)
#import "DatabaseManager.h"

// MARK: - View Controllers
#import "iSleepAppDelegate.h"
#import "MainViewController.h"
// InformationViewController.h - Migrated to Swift InformationView
#import "SettingsViewController.h"
#import "SoundsViewController.h"
#import "BackgroundsViewController.h"
// TimerViewController.h - Migrated to Swift TimerSettingsView
#import "BacklightViewController.h"

// MARK: - Networking
// FlickrAPIClient.h - Migrated to Swift FlickrService

// MARK: - Audio
// AVAudioPlayer+PGFade - Migrated to Swift AudioFading service

// MARK: - In-App Purchases
// IAPHelper & SleepsterIAPHelper - Migrated to Swift StoreKitManager

// MARK: - Constants
#import "Constants.h"

// MARK: - Utility
#import "SynthesizeSingleton.h"

// MARK: - System Frameworks
#import <AVFoundation/AVFoundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#endif /* SleepMate_Bridging_Header_h */