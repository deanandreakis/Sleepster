# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sleepster is an iOS sleep app written in Objective-C using UIKit. The app provides nature sounds, background images, timer functionality, and in-app purchases to help users sleep better. The app now features advanced multi-sound mixing capabilities for customized sleep experiences.

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
- **Models**: `Sound` and `Background` entities for user preferences, with `isSelectedForMixing` support
- **Data Model**: `SleepsterModel.xcdatamodeld` defines the schema

### Key Features
- **Audio Playback**: `AVAudioPlayer` with custom fade extension (`AVAudioPlayer+PGFade`)
- **Multi-Sound Mixing**: `AudioMixingEngine` enables simultaneous playback of up to 5 nature sounds
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

## Multi-Sound Mixing Feature

### Overview
The app now supports advanced multi-sound mixing, allowing users to select and play up to 5 nature sounds simultaneously for a customized sleep experience.

### Core Components

#### AudioMixingEngine (`Services/AudioMixingEngine.swift`)
- **Purpose**: Manages simultaneous playback of multiple audio streams using AVAudioEngine
- **Key Methods**:
  - `playSound(named:volume:loop:fadeInDuration:)` - Starts individual sound playback
  - `stopAllSounds(fadeOutDuration:)` - Gracefully stops all sounds with optional fade
  - `forceStopAll()` - "Nuclear option" - stops entire engine and restarts for reliability
  - `setVolume(_:for:)` - Controls individual sound volumes
- **Architecture**: Uses AVAudioPlayerNode instances connected to AVAudioMixerNode

#### Data Model Updates
- **SoundEntity**: Added `isSelectedForMixing` boolean attribute
- **Core Data Methods**:
  - `fetchSelectedSoundsForMixing()` - Retrieves all sounds marked for mixing
  - `addToMix()` / `removeFromMix()` - Manages mixing selection state
  - `toggleMixSelection()` - Toggles sound inclusion in mix

#### ViewModels
- **MainViewModel**: 
  - `selectedSoundsForMixing` - Published array of selected sounds
  - `isMixingMode` - Boolean indicating if mixing is active
  - `activeChannelPlayers` - Dictionary tracking active audio channels
  - `startMixedAudio()` / `stopSleeping()` - Core mixing control methods

- **SoundsViewModel**:
  - `toggleSoundInMix(_:)` - Handles sound selection for mixing
  - `enableMixingMode()` / `disableMixingMode()` - Mode management
  - Maximum 5 sounds limit enforcement

#### UI Components
- **SoundsListView**: Toggle between single-sound and mixing modes with visual feedback
- **SleepView**: Displays mixing status in header ("X sounds selected for mixing")
- **Mixing Mode Toggle**: Button to enable/disable multi-sound selection

### Technical Implementation Details

#### Audio Control Strategy
The app uses a "nuclear option" approach for reliable audio stopping:
1. **Immediate UI Response**: Update UI state synchronously
2. **Engine Restart**: Stop entire AVAudioEngine and restart cleanly
3. **Collection Cleanup**: Clear all player references and collections
4. **No Blocking Operations**: Avoid async operations that could freeze UI

#### Error Handling
- Comprehensive error handling around audio node operations
- Graceful fallback to engine restart if individual node stopping fails
- Logging for debugging audio issues

#### Performance Considerations
- Maximum 5 concurrent sounds to prevent performance issues
- Proper cleanup of audio resources to prevent memory leaks
- Background Task usage for audio setup to maintain UI responsiveness

### Usage Patterns
1. **Selection**: Users toggle mixing mode in Sounds tab and select multiple sounds
2. **Playback**: Selected sounds play simultaneously when sleep timer starts
3. **Control**: Standard start/stop controls work reliably with mixed audio
4. **Persistence**: Selected mixing preferences saved across app sessions

### Known Limitations
- Maximum 5 simultaneous sounds
- No individual volume controls per sound (uses master volume)
- No advanced mixing effects (EQ, spatial audio, etc.)

### Future Enhancement Opportunities
- Individual sound volume sliders
- Audio presets and quick-mix templates
- Advanced audio effects and EQ
- Sound preview functionality in mixing mode