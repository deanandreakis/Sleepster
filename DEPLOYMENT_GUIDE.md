# Sleepster iOS App - Deployment Guide

## Overview

This guide outlines the complete deployment process for the modernized Sleepster iOS app, including App Store submission, TestFlight distribution, and production considerations.

## Pre-Deployment Checklist

### Code Quality & Testing

- [ ] All unit tests passing (run `fastlane test`)
- [ ] Integration tests validated
- [ ] Performance benchmarks within acceptable ranges
- [ ] Memory leaks identified and resolved
- [ ] Accessibility compliance verified
- [ ] Device compatibility tested (iPhone/iPad)
- [ ] iOS version compatibility confirmed (iOS 15.0+)

### App Store Requirements

- [ ] App Store Connect project configured
- [ ] Bundle identifier matches App Store Connect (`com.deanware.sleepmate`)
- [ ] Version number updated in Info.plist
- [ ] Build number incremented
- [ ] App icons provided for all required sizes
- [ ] Screenshots prepared for all device sizes
- [ ] App description and metadata finalized
- [ ] Privacy policy URL configured
- [ ] Terms of service URL configured

### StoreKit Configuration

- [ ] In-App Purchase products configured in App Store Connect
  - [ ] `multiplebg` - Multiple Backgrounds
  - [ ] `multiplesounds` - Multiple Sounds
  - [ ] `premium_pack` - Premium Pack
  - [ ] `yearly_subscription` - Yearly Subscription
- [ ] Subscription groups configured
- [ ] Pricing tiers set for all regions
- [ ] Promotional offers configured (if applicable)

### HealthKit & Privacy

- [ ] HealthKit capabilities enabled in App Store Connect
- [ ] Health app integration tested
- [ ] Privacy usage descriptions added to Info.plist:
  - [ ] `NSHealthShareUsageDescription`
  - [ ] `NSHealthUpdateUsageDescription`
  - [ ] `NSMicrophoneUsageDescription` (if applicable)
  - [ ] `NSPhotoLibraryUsageDescription` (for custom backgrounds)

### Siri & Shortcuts

- [ ] Siri capabilities enabled in App Store Connect
- [ ] Intent definitions validated
- [ ] Voice shortcuts tested on device
- [ ] App Shortcuts configured in Info.plist

## Build Configuration

### Debug vs Release

```swift
// Ensure release build optimizations
#if DEBUG
    // Debug-only code
#else
    // Production optimizations enabled
#endif
```

### Build Settings

- **Optimization Level**: `-Os` (Optimize for Size)
- **Swift Compilation Mode**: `Whole Module Optimization`
- **Strip Debug Symbols**: `YES` (Release only)
- **Enable Bitcode**: `YES`
- **Deployment Target**: `iOS 15.0`

### Entitlements

Verify the following entitlements are properly configured:

```xml
<key>com.apple.developer.healthkit</key>
<true/>
<key>com.apple.developer.siri</key>
<true/>
<key>com.apple.security.app-sandbox</key>
<false/>
<key>aps-environment</key>
<string>production</string>
```

## Fastlane Deployment

### Setup

1. Install Fastlane:
```bash
sudo gem install fastlane
```

2. Initialize Fastlane (if not already done):
```bash
cd /path/to/Sleepster
fastlane init
```

### Available Lanes

#### Testing
```bash
# Run all tests
fastlane test

# Run tests with coverage
fastlane test_with_coverage
```

#### Beta Distribution
```bash
# Build and upload to TestFlight
fastlane beta

# Upload to TestFlight with specific notes
fastlane beta notes:"New StoreKit 2 integration and HealthKit sleep tracking"
```

#### Production Release
```bash
# Build and submit to App Store for review
fastlane appstore

# Submit with metadata update
fastlane appstore submit_for_review:true
```

#### Screenshots
```bash
# Generate screenshots for all device sizes
fastlane screenshot

# Generate and upload screenshots
fastlane screenshot_and_upload
```

## Manual Deployment Steps

### 1. Archive Build

```bash
# Clean build folder
xcodebuild clean -workspace SleepMate.xcworkspace -scheme SleepMate

# Create archive
xcodebuild archive \
  -workspace SleepMate.xcworkspace \
  -scheme SleepMate \
  -configuration Release \
  -archivePath "./build/SleepMate.xcarchive"
```

### 2. Export IPA

```bash
# Export for App Store
xcodebuild -exportArchive \
  -archivePath "./build/SleepMate.xcarchive" \
  -exportPath "./build/" \
  -exportOptionsPlist "./fastlane/ExportOptions.plist"
```

### 3. Upload to App Store Connect

```bash
# Using Application Loader alternative
xcrun altool --upload-app \
  --type ios \
  --file "./build/SleepMate.ipa" \
  --username "your-apple-id@email.com" \
  --password "@keychain:ApplicationLoaderPassword"
```

## Version Management

### Version Numbers

- **Marketing Version**: User-facing version (e.g., "3.0")
- **Build Number**: Internal build identifier (auto-incremented)

### Release Notes Template

```
## What's New in Sleepster 3.0

🎉 **Complete App Redesign**
- Brand new SwiftUI interface with modern design
- Improved navigation and user experience

💰 **Enhanced In-App Purchases**
- Streamlined purchase flow with StoreKit 2
- New yearly subscription option with premium features
- Seamless purchase restoration

😴 **Advanced Sleep Tracking**
- HealthKit integration for comprehensive sleep analysis
- Sleep insights and personalized recommendations
- Track sleep efficiency and consistency

🎵 **Powerful Audio Features**
- Mix up to 5 sounds simultaneously
- Advanced 10-band equalizer
- Audio effects including reverb and delay
- Improved audio quality and performance

📱 **Widgets & Shortcuts**
- Home screen widgets in multiple sizes
- Siri voice commands support
- Quick access to favorite sounds and timers

🔧 **Performance & Reliability**
- Significantly improved app performance
- Better memory management
- Enhanced battery optimization
- Bug fixes and stability improvements
```

## Testing Strategy

### TestFlight Beta Testing

1. **Internal Testing**
   - Developer team testing
   - Core functionality validation
   - Performance testing on various devices

2. **External Testing**
   - Limited beta group (50-100 users)
   - Collect feedback on new features
   - Monitor crash reports and performance

3. **Production Candidate**
   - Expanded beta group (500+ users)
   - Final validation before App Store submission
   - A/B testing for subscription flow

### Device Testing Matrix

| Device | iOS Version | Features to Test |
|--------|-------------|------------------|
| iPhone 15 Pro | iOS 18.0 | All features, StoreKit 2 |
| iPhone 14 | iOS 17.0 | Audio mixing, widgets |
| iPhone SE 3rd Gen | iOS 16.0 | Basic functionality |
| iPad Pro 12.9" | iOS 17.0 | iPad layout, multitasking |
| iPad Air | iOS 16.0 | Compatibility |

## App Store Submission

### Submission Checklist

- [ ] Build uploaded to App Store Connect
- [ ] App information completed
- [ ] Pricing and availability configured
- [ ] App Review Information provided
- [ ] Screenshots uploaded for all device sizes
- [ ] App preview videos uploaded (optional)
- [ ] Keywords optimized for App Store Search
- [ ] Age rating configured appropriately
- [ ] Export compliance documentation

### Review Guidelines Compliance

Ensure compliance with Apple's App Store Review Guidelines:

- **2.1 App Completeness**: App is fully functional
- **2.3 Accurate Metadata**: Description matches functionality
- **3.1.1 In-App Purchase**: Proper StoreKit implementation
- **5.1.1 Privacy**: Clear privacy policy and data usage
- **4.5.4 VoIP**: Proper background audio handling

### Common Rejection Reasons & Solutions

1. **HealthKit Data Usage**
   - Ensure clear explanation of health data usage
   - Provide value proposition for health integration

2. **In-App Purchase Issues**
   - Test all purchase flows thoroughly
   - Ensure restore purchases functionality works

3. **Background Audio**
   - Verify background audio capabilities are properly configured
   - Test background playback scenarios

## Monitoring & Analytics

### Post-Launch Monitoring

1. **App Store Connect Analytics**
   - Monitor download metrics
   - Track conversion rates
   - Analyze user retention

2. **Crash Reporting**
   - Monitor crash reports in Xcode Organizer
   - Set up automated alerts for critical issues

3. **Performance Monitoring**
   - Track app performance metrics
   - Monitor memory usage and battery impact

### Key Performance Indicators (KPIs)

- **Downloads**: Track daily/weekly download trends
- **Retention**: 1-day, 7-day, 30-day user retention
- **Revenue**: In-app purchase conversion rates
- **Ratings**: App Store rating and review sentiment
- **Performance**: App launch time, memory usage

## Rollback Strategy

### Emergency Rollback

If critical issues are discovered post-release:

1. **Immediate Actions**
   - Stop app promotion in App Store Connect
   - Prepare hotfix build with critical bug fixes
   - Communicate with users via in-app messaging

2. **Hotfix Deployment**
   - Fast-track hotfix through TestFlight
   - Submit expedited review request to Apple
   - Monitor fix effectiveness

## Support & Maintenance

### User Support

- **In-App Support**: Help section with FAQs
- **Email Support**: Response within 24 hours
- **App Store Reviews**: Monitor and respond to user feedback

### Maintenance Schedule

- **Weekly**: Monitor performance metrics and crash reports
- **Monthly**: Review user feedback and plan improvements
- **Quarterly**: Major feature updates and iOS compatibility

## Security Considerations

### Data Protection

- All user data encrypted at rest and in transit
- HealthKit data properly sandboxed
- No sensitive data logged to external services

### Code Obfuscation

- Enable Swift symbol obfuscation in release builds
- Remove debug information from production builds
- Validate third-party dependencies for security issues

## Conclusion

This deployment guide ensures a smooth and successful release of the modernized Sleepster app. Following these procedures will help maintain high quality standards while providing users with a reliable and feature-rich sleep enhancement experience.

For questions or issues during deployment, refer to the development team or Apple's developer documentation.