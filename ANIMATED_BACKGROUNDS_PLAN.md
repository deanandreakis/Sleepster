# Animated Background System - Comprehensive Plan

## 🎯 Vision
Replace static Flickr images and solid colors with gentle, slow-moving animations designed specifically for sleep environments. These animations will be optimized for dimmed displays and provide a calming visual experience while users fall asleep.

## 🎨 Animation Concepts

### Classic Sleep Themes:
- **Counting Sheep** - Sheep gently jumping over a wooden fence
- **Cow Jumping Moon** - Whimsical nursery rhyme with twinkling stars
- **Gentle Waves** - Ocean waves with soft foam patterns
- **Floating Clouds** - Slow-drifting clouds across starry sky

### Nature Themes:
- **Falling Leaves** - Autumn leaves spiraling down
- **Soft Rain** - Gentle raindrops with subtle ripple effects  
- **Snow Drift** - Snowflakes floating in winter breeze
- **Firefly Meadow** - Blinking lights in dark grass

### Celestial Themes:
- **Solar System** - Planets in slow orbital motion
- **Shooting Stars** - Occasional meteors across night sky
- **Aurora Waves** - Gentle northern lights undulation
- **Moon Phases** - Gradual lunar cycle progression

## 🏗️ Technical Architecture

### Animation Framework:
```swift
protocol AnimatedBackground {
    var id: String { get }
    var title: String { get }
    var category: BackgroundCategory { get }
    var previewDuration: TimeInterval { get }
    
    func createView(intensity: Float, speed: Float, dimmed: Bool) -> AnyView
    func previewView() -> AnyView
}

enum BackgroundCategory: CaseIterable {
    case classic, nature, celestial, abstract
}
```

### Performance Optimization:
- SwiftUI animations with `withAnimation()` for smooth transitions
- Particle systems using lightweight Shape views
- Automatic performance scaling based on battery level
- 60fps normal mode, 30fps dimmed mode
- Pause animations when app backgrounded

### Customization System:
- **Speed Control**: Ultra-slow to normal (0.25x - 1.0x)
- **Intensity**: Number of animated elements (low/medium/high)
- **Color Themes**: Warm/cool/monochrome palettes
- **Dimming Adaptation**: Automatically adjust for sleep mode brightness

## 📱 User Experience Flow

### Background Selection:
1. **Category Tabs** - Browse by theme (Classic, Nature, Celestial)
2. **Live Previews** - Mini-animations in grid layout
3. **Customization Panel** - Speed, intensity, color adjustments
4. **Favorites System** - Quick access to preferred animations

### Sleep Mode Integration:
1. **Seamless Activation** - Animation starts when sleep mode begins
2. **Tap-to-Stop** - Touch anywhere to end sleep session
3. **Brightness Awareness** - Colors adapt to dimmed display
4. **Smooth Transitions** - Fade between different animations

## 🗂️ Data Model Redesign

### Remove:
- All Flickr-related attributes (`bFullSizeUrl`, `bThumbnailUrl`, etc.)
- Solid color system (`bColor` attribute)
- Online/offline image distinction (`isLocalImage`)

### New Structure:
```swift
@Entity class AnimatedBackgroundEntity {
    @Attribute var id: String
    @Attribute var animationType: String // AnimationType enum raw value
    @Attribute var isSelected: Bool
    @Attribute var isFavorite: Bool
    @Attribute var speedMultiplier: Float = 1.0
    @Attribute var intensityLevel: Int = 2 // 1-3 scale
    @Attribute var colorTheme: String = "default"
}
```

## 🚀 Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Remove all Flickr integration files and references
- [ ] Remove solid color background system
- [ ] Create new `AnimatedBackground` protocol and base classes
- [ ] Update Core Data model for new background system
- [ ] Implement basic animation framework

### Phase 2: Core Animations (Week 2)
- [ ] Implement 6 essential animations:
  - Counting Sheep
  - Gentle Waves  
  - Falling Leaves
  - Firefly Meadow
  - Shooting Stars
  - Soft Rain
- [ ] Create preview system for selection UI
- [ ] Integrate animations with sleep mode display
- [ ] Add tap-to-stop functionality

### Phase 3: Selection Interface (Week 3)
- [ ] Build new backgrounds selection UI with categories
- [ ] Implement live preview thumbnails
- [ ] Add customization controls (speed, intensity, color)
- [ ] Create favorites system
- [ ] Add smooth transitions between animations

### Phase 4: Optimization & Polish (Week 4)
- [ ] Performance optimization for battery efficiency
- [ ] Brightness-adaptive color palettes
- [ ] Animation cycling/playlist feature
- [ ] Advanced particle effects for premium users
- [ ] Testing and refinement

## ⚡ Key Benefits

1. **Sleep-Optimized**: Designed specifically for bedtime viewing
2. **Battery Efficient**: Lightweight animations that don't drain power
3. **Customizable**: User control over speed, intensity, and appearance
4. **Engaging**: More interesting than static images
5. **Offline**: No network dependency, works anywhere
6. **Scalable**: Easy to add new animations over time

## 🔧 Files to Modify/Remove

### Remove Completely:
- `FlickrAPIClient.swift`
- `Services/FlickrService.swift` 
- `Services/ImageCache.swift`
- Flickr constants from `Constants.h` and `Constants.swift`

### Major Updates:
- `BackgroundEntity.swift` - Complete data model redesign
- `BackgroundsView.swift` - New selection interface
- `BackgroundsViewModel.swift` - Animation management logic
- `SleepView.swift` - Animation display integration

### New Files:
- `Services/AnimationEngine.swift` - Core animation framework
- `Views/Animations/` folder - Individual animation implementations
- `ViewModels/AnimationPreviewViewModel.swift` - Preview management

## 🎨 Animation Implementation Details

### Performance Guidelines:
- Use `@State` and `withAnimation()` for smooth transitions
- Implement `onAppear`/`onDisappear` for lifecycle management
- Use `Timer.publish()` for regular animation updates
- Optimize for 30fps during dimmed mode
- Implement view recycling for particle systems

### Color Palette Strategy:
- **Default**: Soft blues and purples for night themes
- **Warm**: Amber and orange tones for cozy feeling
- **Cool**: Blue and teal for calming effect
- **Monochrome**: Grayscale for minimal distraction
- **Auto-dimming**: Reduce saturation and brightness in sleep mode

### Animation Timing:
- **Ultra-slow**: 0.25x speed for deep relaxation
- **Slow**: 0.5x speed for gentle movement
- **Normal**: 1.0x speed for standard experience
- **Breathing Rate**: Sync with human respiratory patterns (4-6 cycles/minute)

This plan transforms the backgrounds feature from a static image viewer into an immersive, sleep-friendly animation system that enhances the user's bedtime experience while maintaining optimal performance and battery efficiency.