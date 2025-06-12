# Brightness Control Improvement Plan

## Current Implementation Status

### ✅ Implemented Features

1. **Manual Brightness Slider** (BrightnessControlView.swift:63-93)
   - Large percentage display (0-100%) showing current brightness level
   - Interactive slider with sun min/max icons on either side
   - Real-time adjustment of device screen brightness via `UIScreen.main.brightness`
   - Haptic feedback on slider changes
   - Yellow tint to match the sun theme

2. **Quick Preset Buttons** (BrightnessControlView.swift:95-135)
   - **Dim (10%)** - Moon icon, indigo color for night use
   - **Low (30%)** - Sun min icon  
   - **Medium (60%)** - Sun max icon
   - **Bright (100%)** - Sun max icon, yellow color
   - Each preset shows percentage and appropriate icon
   - Smooth animated transitions (0.5 seconds) when tapping presets
   - Haptic feedback on selection

3. **Auto-Adjust Toggle** (BrightnessControlView.swift:137-156)
   - Toggle switch labeled "Auto-adjust for sleep"
   - When enabled, shows explanatory text about automatic dimming
   - Haptic feedback when toggled

## 🚧 Missing/Incomplete Implementation

### 1. Settings Persistence
**Problem**: The auto-adjust setting and brightness preferences are not saved between app launches.

**Location**: BrightnessControlView.swift:12-13, 139
```swift
@State private var brightness: Double = UIScreen.main.brightness
@State private var autoAdjust = false
```

**Solution Needed**:
- Add brightness settings to `SettingsManager.swift`
- Save/load auto-adjust preference
- Remember last brightness level

### 2. Sleep Mode Integration
**Problem**: The auto-brightness feature doesn't actually integrate with sleep mode.

**Current Implementation**: BrightnessControlView.swift:160-167
```swift
private func enableAutoAdjust() {
    // In a real implementation, this would integrate with the sleep mode
    // to automatically adjust brightness when sleep starts/stops
    withAnimation(.easeInOut(duration: 2.0)) {
        brightness = 0.1
        UIScreen.main.brightness = 0.1
    }
}
```

**Integration Points Needed**:
- MainViewModel.swift:startSleeping() - trigger auto-dim
- MainViewModel.swift:stopSleeping() - restore brightness
- AppState.swift - track sleep mode state changes

### 3. Advanced Features Missing
- No scheduling (e.g., auto-dim after sunset)
- No gradual brightness transitions during sleep
- No different presets for day/night modes
- No brightness restoration when sleep mode ends

## 🎯 Implementation Plan

### Phase 1: Settings Persistence
**Files to modify**: `Managers/SettingsManager.swift`, `Views/BrightnessControlView.swift`

1. **Add to SettingsManager.swift**:
```swift
// Add to Keys enum
static let isAutoBrightnessEnabled = "isAutoBrightnessEnabled"
static let lastBrightnessLevel = "lastBrightnessLevel"
static let sleepModeBrightnessLevel = "sleepModeBrightnessLevel"

// Add to Defaults enum
static let isAutoBrightnessEnabled = false
static let lastBrightnessLevel: Double = 0.5
static let sleepModeBrightnessLevel: Double = 0.1

// Add properties
var isAutoBrightnessEnabled: Bool {
    get { userDefaults.bool(forKey: Keys.isAutoBrightnessEnabled) }
    set { userDefaults.set(newValue, forKey: Keys.isAutoBrightnessEnabled) }
}

var lastBrightnessLevel: Double {
    get { userDefaults.double(forKey: Keys.lastBrightnessLevel) }
    set { userDefaults.set(newValue, forKey: Keys.lastBrightnessLevel) }
}

var sleepModeBrightnessLevel: Double {
    get { userDefaults.double(forKey: Keys.sleepModeBrightnessLevel) }
    set { userDefaults.set(newValue, forKey: Keys.sleepModeBrightnessLevel) }
}
```

2. **Update BrightnessControlView.swift**:
```swift
@EnvironmentObject var settingsManager: SettingsManager
@State private var brightness: Double = 0.5
@State private var autoAdjust = false

var body: some View {
    // ... existing code
    .onAppear {
        brightness = settingsManager.lastBrightnessLevel
        autoAdjust = settingsManager.isAutoBrightnessEnabled
    }
    .onChange(of: brightness) { newValue in
        settingsManager.lastBrightnessLevel = newValue
    }
    .onChange(of: autoAdjust) { newValue in
        settingsManager.isAutoBrightnessEnabled = newValue
    }
}
```

### Phase 2: Sleep Mode Integration
**Files to modify**: `ViewModels/MainViewModel.swift`, `Views/BrightnessControlView.swift`

1. **Add to MainViewModel.swift**:
```swift
// Add property
private let settingsManager: SettingsManager
private var originalBrightness: Double = 0.5

// Update startSleeping()
func startSleeping() {
    // ... existing code
    
    // Auto-adjust brightness if enabled
    if settingsManager.isAutoBrightnessEnabled {
        originalBrightness = UIScreen.main.brightness
        let targetBrightness = settingsManager.sleepModeBrightnessLevel
        
        withAnimation(.easeInOut(duration: 2.0)) {
            UIScreen.main.brightness = targetBrightness
        }
    }
}

// Update stopSleeping()
func stopSleeping() {
    // ... existing code
    
    // Restore brightness if auto-adjust was enabled
    if settingsManager.isAutoBrightnessEnabled {
        withAnimation(.easeInOut(duration: 1.0)) {
            UIScreen.main.brightness = originalBrightness
        }
    }
}
```

2. **Create BrightnessManager service**:
```swift
// New file: Managers/BrightnessManager.swift
@MainActor
class BrightnessManager: ObservableObject {
    private let settingsManager: SettingsManager
    private var originalBrightness: Double = 0.5
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    func dimForSleep() {
        guard settingsManager.isAutoBrightnessEnabled else { return }
        
        originalBrightness = UIScreen.main.brightness
        let targetBrightness = settingsManager.sleepModeBrightnessLevel
        
        withAnimation(.easeInOut(duration: 2.0)) {
            UIScreen.main.brightness = targetBrightness
        }
    }
    
    func restoreFromSleep() {
        guard settingsManager.isAutoBrightnessEnabled else { return }
        
        withAnimation(.easeInOut(duration: 1.0)) {
            UIScreen.main.brightness = originalBrightness
        }
    }
    
    func setBrightness(_ level: Double) {
        UIScreen.main.brightness = level
        settingsManager.lastBrightnessLevel = level
    }
}
```

### Phase 3: Advanced Features (Future)
1. **Scheduled brightness changes** based on time of day
2. **Gradual dimming** during sleep countdown
3. **Adaptive brightness** based on ambient light (if device supports it)
4. **Custom sleep/wake brightness profiles**

## 🔧 Testing Checklist

### Settings Persistence
- [ ] Auto-adjust setting saves and loads correctly
- [ ] Last brightness level is remembered between app launches
- [ ] Settings survive app termination and restart

### Sleep Mode Integration
- [ ] Brightness dims automatically when sleep mode starts (if auto-adjust enabled)
- [ ] Brightness restores when sleep mode stops
- [ ] Manual brightness changes during sleep mode work correctly
- [ ] Auto-adjust can be toggled on/off without affecting manual control

### Edge Cases
- [ ] Works correctly when brightness is at minimum (0.01)
- [ ] Works correctly when brightness is at maximum (1.0)
- [ ] Handles rapid sleep mode start/stop correctly
- [ ] Preserves user's manual brightness changes

## 📁 Files Requiring Changes

1. **Managers/SettingsManager.swift** - Add brightness-related settings
2. **Views/BrightnessControlView.swift** - Integrate with settings persistence
3. **ViewModels/MainViewModel.swift** - Add sleep mode brightness integration
4. **Managers/BrightnessManager.swift** - New service for brightness management (optional)
5. **ServiceContainer.swift** - Register BrightnessManager if created

## 💡 Implementation Notes

- Use `UIScreen.main.brightness` for system brightness control
- All brightness animations should be smooth (1-2 second duration)
- Preserve user's manual brightness preferences
- Auto-adjust should be opt-in (default: false)
- Consider battery impact of frequent brightness changes
- Test on various device brightness levels and conditions

---
*Created: December 2025*
*Status: Ready for implementation*