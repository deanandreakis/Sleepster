# Suggested Commands for Development

## Dependencies
```bash
# Install CocoaPods dependencies
pod install
```

## Building
```bash
# Build the project (requires Xcode)
xcodebuild -workspace SleepMate.xcworkspace -scheme SleepMate -configuration Debug

# Build for simulator
xcodebuild -workspace SleepMate.xcworkspace -scheme SleepMate -sdk iphonesimulator -configuration Debug
```

## Testing & Quality
```bash
# Run tests using fastlane
fastlane test

# Run tests directly with xcodebuild
xcodebuild test -workspace SleepMate.xcworkspace -scheme SleepMate -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Deployment
```bash
# Create beta build for TestFlight
fastlane beta

# Deploy to App Store
fastlane appstore

# Take screenshots for App Store
fastlane screenshot
```

## Development Utilities (macOS/Darwin)
```bash
# Standard Unix commands work on Darwin
ls          # List files
cd          # Change directory
grep        # Search text
find        # Find files
git         # Version control

# macOS-specific
open .      # Open current directory in Finder
pbcopy      # Copy to clipboard
pbpaste     # Paste from clipboard
```

## Important Notes
- Always use `SleepMate.xcworkspace` (not .xcodeproj)
- Never start simulator unless specifically asked
- Test on iOS 15.0+ devices/simulators
- CocoaPods manages dependencies, not Swift Package Manager