# Codebase Structure

## Root Directory
- **SleepsterApp.swift**: Main SwiftUI app entry point with dependency injection
- **ServiceContainer.swift**: Dependency injection container
- **AppState.swift**: Global app state management
- **CoreDataStack.swift**: Core Data setup and management

## Key Directories

### ViewModels/
- MainViewModel.swift: Primary sleep interface logic
- SoundsViewModel.swift: Sound selection and mixing
- TimerViewModel.swift: Sleep timer functionality
- BackgroundsViewModel.swift: Background image management
- SettingsViewModel.swift: App preferences
- InformationViewModel.swift: About/help content

### Views/
- SleepsterTabView.swift: Main tab-based navigation
- SleepView.swift: Primary sleep interface
- SoundsListView.swift: Sound selection UI
- BackgroundsView.swift: Background selection UI
- SettingsView.swift: App settings
- Components/CustomComponents.swift: Reusable UI components

### Services/
- AudioMixingEngine.swift: Multi-sound mixing engine
- AudioSessionManager.swift: Audio session management
- DatabaseManager.swift: Core Data operations
- StoreKitManager.swift: In-app purchases
- SleepTracker.swift: Sleep session tracking

### Models/
- SoundEntity.swift: Core Data sound model
- BackgroundEntity.swift: Core Data background model

### Configuration
- Podfile: CocoaPods dependencies
- SleepMate-Info.plist: App configuration
- SleepMate.xcworkspace: Xcode workspace
- fastlane/: Deployment automation

### Data
- SleepsterModel.xcdatamodeld: Core Data model
- Media.xcassets: App assets and images
- *.mp3: Nature sound files