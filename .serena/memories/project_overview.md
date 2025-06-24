# Sleepster Project Overview

## Project Purpose
Sleepster is an iOS sleep app designed to help users sleep better through nature sounds, background images, timer functionality, and in-app purchases. The app features advanced multi-sound mixing capabilities allowing users to play up to 5 nature sounds simultaneously for customized sleep experiences.

## Tech Stack
- **Language**: Swift (SwiftUI) with some legacy Objective-C components
- **iOS Target**: iOS 15.0+ (recently updated from iOS 11.0+)
- **UI Framework**: SwiftUI (migrated from UIKit)
- **Dependencies**: 
  - CocoaPods for dependency management
  - Alamofire for networking (modernized from AFNetworking 1.3)
  - Kingfisher for image loading and caching
  - SwiftyJSON for JSON parsing
- **Data Persistence**: Core Data
- **Audio**: AVFoundation with custom AudioMixingEngine
- **Architecture**: MVVM pattern with dependency injection

## App Version
- Version: 3.0 (Bundle version 300)
- Bundle ID: com.deanware.sleepster.*

## Key Features
- Multi-sound mixing (up to 5 simultaneous nature sounds)
- Sleep timer with fade-out functionality
- Flickr integration for background images
- In-app purchases for premium features
- 3D Touch shortcuts ("Sleep NOW!")
- Siri shortcuts integration
- Background audio playback
- Core Data persistence