# Task Completion Checklist

## When Completing Coding Tasks

### 1. Code Quality
- [ ] Follow MVVM architecture patterns
- [ ] Use proper Swift naming conventions
- [ ] Add appropriate MARK comments for organization
- [ ] Handle errors gracefully with proper error types
- [ ] Use @MainActor for UI-related code
- [ ] Implement proper async/await patterns

### 2. Building & Testing
- [ ] Ensure project builds without errors
- [ ] Run tests if available: `fastlane test`
- [ ] Test on iOS 15.0+ target
- [ ] Verify Core Data integration works
- [ ] Test audio functionality if modified

### 3. Dependencies
- [ ] Update Podfile if new dependencies added
- [ ] Run `pod install` after dependency changes
- [ ] Use workspace file (.xcworkspace) for builds

### 4. Audio-Specific Tasks
- [ ] Test multi-sound mixing functionality
- [ ] Verify audio session management
- [ ] Check background audio playback
- [ ] Test audio stopping reliability ("nuclear option")

### 5. Never Do Unless Explicitly Asked
- [ ] Do NOT start iOS simulator for testing
- [ ] Do NOT commit changes
- [ ] Do NOT create unnecessary documentation files

### 6. SwiftUI Integration
- [ ] Use environment objects for dependency injection
- [ ] Ensure views are properly observable
- [ ] Test state management and updates