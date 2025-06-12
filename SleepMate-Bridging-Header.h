//
//  SleepMate-Bridging-Header.h
//  SleepMate
//
//  Created by Claude on SwiftUI Migration
//  Minimal bridging header for pure SwiftUI app
//

#ifndef SleepMate_Bridging_Header_h
#define SleepMate_Bridging_Header_h

// MARK: - Legacy Database Manager (still in Objective-C)
#import "DatabaseManager.h"

// MARK: - Constants (legacy header for compatibility)
#import "Constants.h"

// MARK: - Utility
#import "SynthesizeSingleton.h"

// MARK: - System Frameworks
#import <AVFoundation/AVFoundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

// NOTE: All view controllers, networking, audio, and IAP components 
// have been migrated to Swift and no longer need bridging

#endif /* SleepMate_Bridging_Header_h */