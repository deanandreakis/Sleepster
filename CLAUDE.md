# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sleepster is an iOS sleep app written in Objective-C using UIKit. The app provides nature sounds, background images, timer functionality, and in-app purchases to help users sleep better.

## Development Environment

This is an iOS project using:
- **Xcode workspace**: Use `SleepMate.xcworkspace` (not the .xcodeproj)
- **CocoaPods**: Dependencies managed via Podfile
- **Deployment target**: iOS 11.0+
- **Main dependencies**: AFNetworking 1.3 for networking

## Build Commands

```bash
# Install dependencies
pod install

# Build the project (requires Xcode)
xcodebuild -workspace SleepMate.xcworkspace -scheme SleepMate -configuration Debug

# Run tests
fastlane test

# Create beta build for TestFlight
fastlane beta

# Deploy to App Store
fastlane appstore

# Take screenshots for App Store
fastlane screenshot
```

## Architecture

### Core Structure
- **App Delegate**: `iSleepAppDelegate` - manages app lifecycle and view controller references
- **Main Controller**: `MainViewController` - primary sleep interface with timer and audio controls
- **Tab-based Navigation**: Uses `UITabBarController` with 5 main sections:
  - Main (sleep timer)
  - Sounds (nature sounds selection)
  - Backgrounds (wallpaper selection with Flickr integration)
  - Settings (app preferences)
  - Information (about/help)

### Data Management
- **Core Data**: `DatabaseManager` singleton manages the data stack
- **Models**: `Sound` and `Background` entities for user preferences
- **Data Model**: `SleepsterModel.xcdatamodeld` defines the schema

### Key Features
- **Audio Playback**: `AVAudioPlayer` with custom fade extension (`AVAudioPlayer+PGFade`)
- **Timer System**: Sleep timer with volume fadeout
- **Flickr Integration**: `FlickrAPIClient` fetches background images
- **In-App Purchases**: `SleepsterIAPHelper` extends base `IAPHelper` for premium features
- **Background Images**: Local and remote image support with caching

### View Controllers
Each major feature has its own view controller with corresponding XIB files:
- `SoundsViewController` - nature sound selection
- `BackgroundsViewController` - wallpaper selection with search
- `TimerViewController` - sleep timer configuration
- `SettingsViewController` - app preferences
- `BacklightViewController` - screen brightness control

## Important Notes

- The app uses portrait orientation only
- Supports 3D Touch shortcut for "Sleep NOW!"
- Bundle ID follows pattern: com.deanware.sleepster.*
- Version managed in Info.plist (currently 2.5, build 115)
- Uses legacy AFNetworking 1.3 (consider updating for new features)