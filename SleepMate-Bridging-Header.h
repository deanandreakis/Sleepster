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
#import "InformationViewController.h"
#import "SettingsViewController.h"
#import "SoundsViewController.h"
#import "BackgroundsViewController.h"
#import "TimerViewController.h"
#import "BacklightViewController.h"

// MARK: - Networking
#import "FlickrAPIClient.h"

// MARK: - Audio
#import "AVAudioPlayer+PGFade.h"

// MARK: - In-App Purchases
#import "IAPHelper.h"
#import "SleepsterIAPHelper.h"

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