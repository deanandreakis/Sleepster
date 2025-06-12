//
//  SleepMate-Bridging-Header.h
//  SleepMate
//
//  Created by Claude on Complete Swift Migration
//  Minimal bridging header for 100% Swift app
//

#ifndef SleepMate_Bridging_Header_h
#define SleepMate_Bridging_Header_h

// MARK: - Legacy Constants (header for compatibility)
#import "Constants.h"

// MARK: - Utility (legacy singleton pattern)
#import "SynthesizeSingleton.h"

// MARK: - System Frameworks
#import <AVFoundation/AVFoundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

// NOTE: All core components have been migrated to Swift:
// - DatabaseManager (Core Data stack)
// - All view controllers and UI components
// - Networking, audio, and IAP functionality
// - App lifecycle and state management

#endif /* SleepMate_Bridging_Header_h */