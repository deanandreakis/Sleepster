//
//  AnimationEngine.swift
//  SleepMate
//
//  Created by Claude on Animated Backgrounds Phase 1
//

import Foundation
import SwiftUI

// MARK: - Background Categories
enum BackgroundCategory: String, CaseIterable {
    case classic = "classic"
    case nature = "nature"
    case celestial = "celestial"
    case abstract = "abstract"
    
    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .nature: return "Nature"
        case .celestial: return "Celestial"
        case .abstract: return "Abstract"
        }
    }
}

// MARK: - Color Themes
enum ColorTheme: String, CaseIterable {
    case defaultTheme = "default"
    case warm = "warm"
    case cool = "cool"
    case monochrome = "monochrome"
    
    var displayName: String {
        switch self {
        case .defaultTheme: return "Default"
        case .warm: return "Warm"
        case .cool: return "Cool"
        case .monochrome: return "Monochrome"
        }
    }
}

// MARK: - Animation Protocol
protocol AnimatedBackground {
    var id: String { get }
    var title: String { get }
    var category: BackgroundCategory { get }
    
    func createView(intensity: Float, speed: Float, colorTheme: ColorTheme, dimmed: Bool) -> AnyView
}

// MARK: - Color Adaptation Helper
struct AnimationColorHelper {
    static func adaptedColors(
        baseColors: [Color],
        dimmed: Bool,
        colorScheme: ColorScheme = .dark
    ) -> [Color] {
        if dimmed {
            // Ultra-dimmed for sleep mode
            return baseColors.map { $0.opacity(0.2) }
        } else if colorScheme == .light {
            // Brighter, more colorful for light mode
            return baseColors.map { color in
                // Increase saturation and brightness for light mode
                color.opacity(0.8)
            }
        } else {
            // Standard colors for dark mode
            return baseColors.map { $0.opacity(0.6) }
        }
    }
    
    static func backgroundGradient(
        for colorScheme: ColorScheme,
        dimmed: Bool,
        category: BackgroundCategory
    ) -> [Color] {
        let baseColors: [Color]
        
        switch category {
        case .classic:
            baseColors = colorScheme == .light ? 
                [.blue.opacity(0.4), .purple.opacity(0.3), .white] :
                [.black, .indigo.opacity(0.5)]
        case .nature:
            baseColors = colorScheme == .light ?
                [.green.opacity(0.3), .blue.opacity(0.2), .white] :
                [.black, .green.opacity(0.4), .blue.opacity(0.4)]
        case .celestial:
            baseColors = colorScheme == .light ?
                [.purple.opacity(0.2), .blue.opacity(0.3), .white] :
                [.black, .indigo.opacity(0.5), .purple.opacity(0.3)]
        case .abstract:
            baseColors = colorScheme == .light ?
                [.pink.opacity(0.2), .purple.opacity(0.3), .white] :
                [.black, .purple.opacity(0.5), .pink.opacity(0.3)]
        }
        
        return adaptedColors(baseColors: baseColors, dimmed: dimmed, colorScheme: colorScheme)
    }
}

// MARK: - Animation Protocol Extensions
extension AnimatedBackground {
    func previewView() -> AnyView {
        return createView(intensity: 0.5, speed: 1.0, colorTheme: .defaultTheme, dimmed: false)
    }
    
    var previewDuration: TimeInterval {
        return 10.0
    }
}

// MARK: - Base Animation Class
class BaseAnimatedBackground: AnimatedBackground {
    let id: String
    let title: String
    let category: BackgroundCategory
    let previewDuration: TimeInterval
    
    init(id: String, title: String, category: BackgroundCategory, previewDuration: TimeInterval = 10.0) {
        self.id = id
        self.title = title
        self.category = category
        self.previewDuration = previewDuration
    }
    
    func createView(intensity: Float, speed: Float, colorTheme: ColorTheme, dimmed: Bool) -> AnyView {
        return AnyView(EmptyView()) // Override in subclasses
    }
    
    func previewView() -> AnyView {
        return createView(intensity: 0.5, speed: 1.0, colorTheme: .defaultTheme, dimmed: false)
    }
}

// MARK: - Animation Registry
class AnimationRegistry: ObservableObject {
    static let shared = AnimationRegistry()
    
    @Published private(set) var animations: [AnimatedBackground] = []
    
    private init() {
        loadAnimations()
    }
    
    private func loadAnimations() {
        animations = [
            // Enhanced artistic animations with sophisticated effects
            CountingSheepAnimation(),      // "Dreamy Meadow" - Rolling hills with jumping sheep, stars, and atmospheric depth
            GentleWavesAnimation(),        // "Mystic Ocean" - Multi-layered waves with caustics, bubbles, and underwater effects
            FireflyMeadowAnimation(),      // "Enchanted Garden" - Magical fireflies, falling petals, mist, and dew drops
            ShootingStarsAnimation(),      // "Cosmic Dreams" - Celestial scene with nebulae, galaxy spirals, and aurora
            GeometricPatternsAnimation(),  // "Sacred Geometry" - Mystical patterns with mandala breathing and energy flow
            SoftRainAnimation()            // "Tranquil Storm" - Atmospheric rain with lightning, clouds, and water effects
        ]
    }
    
    func animation(for id: String) -> AnimatedBackground? {
        return animations.first { $0.id == id }
    }
    
    func animationsForCategory(_ category: BackgroundCategory) -> [AnimatedBackground] {
        let filtered = animations.filter { $0.category == category }
        
        #if DEBUG
        print("🔍 AnimationRegistry.animationsForCategory(\(category)):")
        for (index, animation) in filtered.enumerated() {
            print("   [\(index)] \(animation.id) → '\(animation.title)'")
        }
        #endif
        
        return filtered
    }
}

// MARK: - Placeholder Animation (for Phase 1)
class PlaceholderAnimation: BaseAnimatedBackground {
    override func createView(intensity: Float, speed: Float, colorTheme: ColorTheme, dimmed: Bool) -> AnyView {
        return AnyView(
            ZStack {
                // Background gradient based on category
                let colors = backgroundColors(for: category, theme: colorTheme, dimmed: dimmed)
                LinearGradient(
                    gradient: Gradient(colors: colors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Simple animated element as placeholder
                Circle()
                    .fill(Color.white.opacity(dimmed ? 0.1 : 0.3))
                    .frame(width: 20, height: 20)
                    .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * Double(speed)) * 0.2)
                    .animation(.easeInOut(duration: 2.0 / Double(speed)).repeatForever(autoreverses: true), value: speed)
                
                // Category label for identification
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(title)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .padding()
                    }
                }
            }
        )
    }
    
    private func backgroundColors(for category: BackgroundCategory, theme: ColorTheme, dimmed: Bool) -> [Color] {
        let alpha = dimmed ? 0.3 : 0.8
        
        switch (category, theme) {
        case (.classic, .defaultTheme):
            return [Color.blue.opacity(alpha), Color.purple.opacity(alpha)]
        case (.nature, .defaultTheme):
            return [Color.green.opacity(alpha), Color.blue.opacity(alpha)]
        case (.celestial, .defaultTheme):
            return [Color.indigo.opacity(alpha), Color.black.opacity(alpha)]
        case (.abstract, .defaultTheme):
            return [Color.purple.opacity(alpha), Color.pink.opacity(alpha)]
        case (_, .warm):
            return [Color.orange.opacity(alpha), Color.yellow.opacity(alpha)]
        case (_, .cool):
            return [Color.cyan.opacity(alpha), Color.blue.opacity(alpha)]
        case (_, .monochrome):
            return [Color.gray.opacity(alpha), Color.white.opacity(alpha)]
        }
    }
}

// MARK: - Animation Settings
struct AnimationSettings: Equatable {
    var intensity: Float = 0.5 // 0.0 to 1.0
    var speed: Float = 1.0 // 0.25 to 2.0
    var colorTheme: ColorTheme = .defaultTheme
    var dimmedMode: Bool = false
    
    static let `default` = AnimationSettings()
}

// MARK: - Performance Monitor
class AnimationPerformanceMonitor: ObservableObject {
    @Published var currentFPS: Double = 60.0
    @Published var batteryOptimizationEnabled: Bool = false
    
    private var lastFrameTime: CFTimeInterval = 0
    
    func updateFrameRate() {
        let currentTime = CACurrentMediaTime()
        if lastFrameTime > 0 {
            let deltaTime = currentTime - lastFrameTime
            currentFPS = 1.0 / deltaTime
        }
        lastFrameTime = currentTime
        
        // Enable battery optimization if FPS drops below threshold
        batteryOptimizationEnabled = currentFPS < 30.0
    }
    
    var targetFPS: Double {
        return batteryOptimizationEnabled ? 30.0 : 60.0
    }
}

// MARK: - Real Animation Implementations (Phase 2)

// MARK: - Counting Sheep Animation

class CountingSheepAnimation: AnimatedBackground {
    let id = "counting_sheep"
    let title = "Dreamy Meadow"
    let category = BackgroundCategory.classic
    
    func createView(intensity: Float, speed: Float, colorTheme: ColorTheme, dimmed: Bool) -> AnyView {
        AnyView(EnhancedCountingSheepView(intensity: intensity, speed: speed, colorTheme: colorTheme, dimmed: dimmed))
    }
}

struct EnhancedCountingSheepView: View {
    let intensity: Float
    let speed: Float
    let colorTheme: ColorTheme
    let dimmed: Bool
    
    @State private var sheepPositions: [SheepData] = []
    @State private var animationTimer: Timer?
    @State private var floatingTimer: Timer?
    @State private var cloudPositions: [CloudData] = []
    @State private var windOffset: CGFloat = 0
    @State private var twinklePhase: Double = 0
    @State private var grassSway: Double = 0
    
    private struct SheepData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var jumpHeight: CGFloat = 0
        var isJumping: Bool = false
        var jumpPhase: Double = 0
        var scale: CGFloat = 1.0
        var shadowOpacity: Double = 0.3
        var floatPhase: Double = Double.random(in: 0...2 * .pi)
        var floatAmplitude: CGFloat = CGFloat.random(in: 15...40)
        var driftSpeed: CGFloat = CGFloat.random(in: 0.3...1.2)
        var isFloating: Bool = false
        let baseScale: CGFloat = CGFloat.random(in: 1.2...2.0)  // Larger base scale
        
        // Enhanced floating properties for more natural movement
        var verticalPhase: Double = Double.random(in: 0...2 * .pi)
        var horizontalPhase: Double = Double.random(in: 0...2 * .pi)
        var rotationPhase: Double = Double.random(in: 0...2 * .pi)
        var verticalFrequency: Double = Double.random(in: 0.8...1.4)
        var horizontalFrequency: Double = Double.random(in: 0.5...1.0)
        var rotationFrequency: Double = Double.random(in: 0.3...0.7)
        var floatRadius: CGFloat = CGFloat.random(in: 20...80)
        var baseX: CGFloat = 0  // Base position for orbital movement
        var baseY: CGFloat = 0  // Base position for orbital movement
        var currentRotation: Double = 0
    }
    
    private struct CloudData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        let scale: CGFloat
        let opacity: Double
        let speed: CGFloat
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Multi-layered sky background with depth
                ZStack {
                    // Deep sky
                    RadialGradient(
                        colors: [
                            dimmed ? .black.opacity(0.95) : .black.opacity(0.85),
                            dimmed ? .indigo.opacity(0.4) : .indigo.opacity(0.6),
                            dimmed ? .purple.opacity(0.2) : .purple.opacity(0.4)
                        ],
                        center: .top,
                        startRadius: 0,
                        endRadius: geometry.size.height
                    )
                    
                    // Horizon glow
                    LinearGradient(
                        colors: [
                            .clear,
                            dimmed ? .orange.opacity(0.05) : .orange.opacity(0.15),
                            dimmed ? .yellow.opacity(0.02) : .yellow.opacity(0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                
                // Animated clouds with parallax
                ForEach(cloudPositions) { cloud in
                    EnhancedCloudShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(cloud.opacity * (dimmed ? 0.2 : 0.4)),
                                    Color.gray.opacity(cloud.opacity * (dimmed ? 0.1 : 0.2))
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(cloud.scale)
                        .position(x: cloud.x + windOffset * cloud.speed, y: cloud.y)
                        .blur(radius: (1.0 - cloud.scale) * 2)
                }
                
                // Twinkling stars with varying sizes and intensity
                ForEach(0..<Int(intensity * 50) + 20, id: \.self) { index in
                    let starScale = CGFloat.random(in: 0.5...2.0)
                    let twinkleSpeed = Double.random(in: 0.5...2.0)
                    let starOpacity = sin(twinklePhase * twinkleSpeed + Double(index)) * 0.5 + 0.5
                    
                    StarShape()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(starOpacity * (dimmed ? 0.3 : 0.8)),
                                    Color.blue.opacity(starOpacity * (dimmed ? 0.1 : 0.3)),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 3
                            )
                        )
                        .frame(width: starScale * 3, height: starScale * 3)
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...(geometry.size.height * 0.6))
                        )
                        .scaleEffect(0.8 + starOpacity * 0.4)
                }
                
                // Rolling hills with atmospheric perspective
                ForEach(0..<3, id: \.self) { layer in
                    let layerDepth = CGFloat(layer + 1)
                    EnhancedHillShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.green.opacity((dimmed ? 0.2 : 0.4) / Double(layerDepth)),
                                    Color.black.opacity((dimmed ? 0.6 : 0.4) * Double(layerDepth) / 3.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .offset(y: (geometry.size.height * 0.6) + CGFloat(layer * 20))
                        .blur(radius: layerDepth - 1)
                }
                
                // Enhanced grass with wind animation
                ForEach(0..<Int(geometry.size.width / 15), id: \.self) { index in
                    let grassHeight = CGFloat.random(in: 30...60)
                    let swayOffset = sin(grassSway + Double(index) * 0.5) * 5
                    
                    EnhancedGrassShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.green.opacity(dimmed ? 0.4 : 0.7),
                                    Color.black.opacity(dimmed ? 0.7 : 0.5)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(
                            width: CGFloat.random(in: 2...4),
                            height: grassHeight
                        )
                        .position(
                            x: CGFloat(index * 15) + CGFloat.random(in: -3...3) + CGFloat(swayOffset),
                            y: geometry.size.height - grassHeight/2 + CGFloat.random(in: -5...5)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 1, y: 1)
                }
                
                // Enhanced sheep with depth and shadows
                ForEach(sheepPositions) { sheep in
                    ZStack {
                        // Shadow
                        Ellipse()
                            .fill(Color.black.opacity(sheep.shadowOpacity * (dimmed ? 0.2 : 0.4)))
                            .frame(width: 55 * sheep.scale, height: 12 * sheep.scale)
                            .position(x: sheep.x + 2, y: sheep.y + 20)
                            .blur(radius: 2)
                        
                        // Cartoon sheep using the enhanced shape approach
                        EnhancedSheepShape()
                            .fill(getSheepColor(colorTheme: colorTheme, dimmed: dimmed, primary: true))
                            .frame(width: 50 * sheep.scale, height: 35 * sheep.scale)
                            .rotationEffect(.radians(sheep.currentRotation))
                            .position(x: sheep.x, y: sheep.y - sheep.jumpHeight)
                            .animation(.easeInOut(duration: 0.3), value: sheep.jumpHeight)
                            .shadow(color: .white.opacity(0.3), radius: 3)
                    }
                }
            }
        }
        .onAppear {
            setupScene()
            startAnimations()
        }
        .onDisappear {
            stopAnimations()
        }
    }
    
    private func setupScene() {
        setupSheep()
        setupClouds()
    }
    
    private func setupSheep() {
        sheepPositions = []
        let sheepCount = Int(intensity * 20) + 12  // Significantly more sheep
        for i in 0..<sheepCount {
            // Create sheep at various positions and heights for floating effect
            let yPosition: CGFloat
            if i < sheepCount / 2 {
                // Some sheep on the ground level
                yPosition = UIScreen.main.bounds.height * 0.72
            } else {
                // Many floating sheep in the sky
                yPosition = CGFloat.random(in: UIScreen.main.bounds.height * 0.2...UIScreen.main.bounds.height * 0.6)
            }
            
             let xPosition: CGFloat
            if i < sheepCount / 3 {
                // Traditional line of sheep
                xPosition = -80 - CGFloat(i * 120)
            } else {
                // Random floating positions
                xPosition = CGFloat.random(in: -200...UIScreen.main.bounds.width + 200)
            }
            
            let isFloating = i >= sheepCount / 2
            var sheepData = SheepData(
                x: xPosition,
                y: yPosition,
                scale: isFloating ? CGFloat.random(in: 1.2...2.0) : CGFloat.random(in: 0.8...1.6),
                shadowOpacity: Double.random(in: 0.1...0.4),
                isFloating: isFloating
            )
            
            // Set base positions for floating sheep orbital movement
            if isFloating {
                sheepData.baseX = xPosition
                sheepData.baseY = yPosition
            }
            
            sheepPositions.append(sheepData)
        }
    }
    
    private func setupClouds() {
        cloudPositions = []
        let cloudCount = Int(intensity * 8) + 3
        for _ in 0..<cloudCount {
            cloudPositions.append(CloudData(
                x: CGFloat.random(in: -100...UIScreen.main.bounds.width + 100),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height * 0.4),
                scale: CGFloat.random(in: 0.3...1.0),
                opacity: Double.random(in: 0.1...0.4),
                speed: CGFloat.random(in: 0.3...0.8)
            ))
        }
    }
    
    private func startAnimations() {
        // Sheep jumping animation
        animationTimer = Timer.scheduledTimer(withTimeInterval: 3.0 / Double(speed), repeats: true) { _ in
            animateSheep()
        }
        
        // Floating sheep animation - smoother updates
        floatingTimer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { _ in
            animateFloatingSheep()
        }
        
        // Continuous environmental animations
        withAnimation(.linear(duration: 20.0 / Double(speed)).repeatForever(autoreverses: false)) {
            windOffset = 100
        }
        
        withAnimation(.linear(duration: 4.0 / Double(speed)).repeatForever(autoreverses: false)) {
            twinklePhase = 2 * .pi
        }
        
        withAnimation(.easeInOut(duration: 6.0 / Double(speed)).repeatForever(autoreverses: true)) {
            grassSway = Double.pi
        }
    }
    
    private func stopAnimations() {
        animationTimer?.invalidate()
        animationTimer = nil
        floatingTimer?.invalidate()
        floatingTimer = nil
    }
    
    private func animateSheep() {
        for i in 0..<sheepPositions.count {
            if !sheepPositions[i].isJumping {
                sheepPositions[i].isJumping = true
                
                // Enhanced jump animation with scaling
                withAnimation(.easeOut(duration: 0.6 / Double(speed))) {
                    sheepPositions[i].jumpHeight = 50
                    sheepPositions[i].scale *= 1.1
                }
                
                withAnimation(.easeIn(duration: 0.6 / Double(speed)).delay(0.6 / Double(speed))) {
                    sheepPositions[i].jumpHeight = 0
                    sheepPositions[i].scale = sheepPositions[i].scale / 1.1
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2 / Double(speed)) {
                    if i < sheepPositions.count {
                        sheepPositions[i].x += 100
                        sheepPositions[i].isJumping = false
                        
                        // Reset sheep position if off screen
                        if sheepPositions[i].x > UIScreen.main.bounds.width + 100 {
                            sheepPositions[i].x = -80
                            sheepPositions[i].scale = sheepPositions[i].baseScale
                        }
                    }
                }
                break
            }
        }
    }
    
    private func animateFloatingSheep() {
        let bounds = UIScreen.main.bounds
        let _ = CACurrentMediaTime()
        
        for i in 0..<sheepPositions.count {
            if sheepPositions[i].isFloating {
                let sheep = sheepPositions[i]
                
                // Update phase values for natural variation
                sheepPositions[i].verticalPhase += 0.015 * sheep.verticalFrequency * Double(speed)
                sheepPositions[i].horizontalPhase += 0.01 * sheep.horizontalFrequency * Double(speed)
                sheepPositions[i].rotationPhase += 0.008 * sheep.rotationFrequency * Double(speed)
                
                // Organic floating motion using multiple sine waves
                let verticalFloat = sin(sheepPositions[i].verticalPhase) * sheep.floatAmplitude * 0.4
                let horizontalFloat = cos(sheepPositions[i].horizontalPhase) * (sheep.floatAmplitude * 0.6)
                
                // Add subtle orbital/circular motion for some sheep
                let orbitalX = cos(sheepPositions[i].horizontalPhase * 0.7) * sheep.floatRadius * 0.3
                let orbitalY = sin(sheepPositions[i].verticalPhase * 0.5) * sheep.floatRadius * 0.2
                
                // Gentle main drift movement
                sheepPositions[i].baseX += sheep.driftSpeed * CGFloat(speed) * 0.03
                
                // Combine all movements for natural, dreamlike floating
                sheepPositions[i].x = sheep.baseX + horizontalFloat + orbitalX
                sheepPositions[i].jumpHeight = verticalFloat + orbitalY
                
                // Add subtle rotation for visual interest
                sheepPositions[i].currentRotation = sin(sheepPositions[i].rotationPhase) * 0.1
                
                // Scale variation for breathing effect
                let breathingScale = 1.0 + sin(sheepPositions[i].verticalPhase * 1.3) * 0.05
                sheepPositions[i].scale = sheep.baseScale * breathingScale
                
                // Vary shadow opacity based on height for depth
                let heightFactor = abs(sheepPositions[i].jumpHeight) / sheep.floatAmplitude
                sheepPositions[i].shadowOpacity = Double(0.1 + heightFactor * 0.3) * (dimmed ? 0.5 : 1.0)
                
                // Boundary handling with smooth wrapping
                if sheepPositions[i].x > bounds.width + 200 {
                    sheepPositions[i].baseX = -200
                    sheepPositions[i].baseY = CGFloat.random(in: bounds.height * 0.2...bounds.height * 0.6)
                    // Randomize properties for variety
                    sheepPositions[i].verticalFrequency = Double.random(in: 0.8...1.4)
                    sheepPositions[i].horizontalFrequency = Double.random(in: 0.5...1.0)
                    sheepPositions[i].floatAmplitude = CGFloat.random(in: 15...40)
                } else if sheepPositions[i].x < -200 {
                    sheepPositions[i].baseX = bounds.width + 200
                    sheepPositions[i].baseY = CGFloat.random(in: bounds.height * 0.2...bounds.height * 0.6)
                    // Randomize properties for variety
                    sheepPositions[i].verticalFrequency = Double.random(in: 0.8...1.4)
                    sheepPositions[i].horizontalFrequency = Double.random(in: 0.5...1.0)
                    sheepPositions[i].floatAmplitude = CGFloat.random(in: 15...40)
                }
            }
        }
    }
}

// MARK: - Helper Functions

private func getSheepColor(colorTheme: ColorTheme, dimmed: Bool, primary: Bool) -> Color {
    let baseOpacity = primary ? (dimmed ? 0.7 : 0.95) : (dimmed ? 0.3 : 0.5)
    
    switch colorTheme {
    case .defaultTheme:
        return primary ? Color.white.opacity(baseOpacity) : Color.gray.opacity(baseOpacity)
    case .warm:
        return primary ? Color.init(red: 1.0, green: 0.95, blue: 0.9).opacity(baseOpacity) : 
                        Color.init(red: 0.8, green: 0.6, blue: 0.4).opacity(baseOpacity)
    case .cool:
        return primary ? Color.init(red: 0.9, green: 0.95, blue: 1.0).opacity(baseOpacity) : 
                        Color.init(red: 0.6, green: 0.7, blue: 0.8).opacity(baseOpacity)
    case .monochrome:
        return primary ? Color.white.opacity(baseOpacity * 0.8) : Color.gray.opacity(baseOpacity)
    }
}

// MARK: - Enhanced Shape Definitions

struct EnhancedSheepShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Scale factor based on rect size for consistent proportions
        let scale = min(rect.width, rect.height) / 60
        let centerX = rect.midX
        let centerY = rect.midY
        
        // Create cartoon sheep matching reference image exactly
        createFluffyBody(path: &path, centerX: centerX, centerY: centerY, scale: scale)
        createSheepFace(path: &path, centerX: centerX, centerY: centerY, scale: scale)
        createDroppyEars(path: &path, centerX: centerX, centerY: centerY, scale: scale)
        createSheepEyes(path: &path, centerX: centerX, centerY: centerY, scale: scale)
        createSheepNose(path: &path, centerX: centerX, centerY: centerY, scale: scale)
        createSheepLegs(path: &path, centerX: centerX, centerY: centerY, scale: scale)
        
        return path
    }
    
    private func createFluffyBody(path: inout Path, centerX: CGFloat, centerY: CGFloat, scale: CGFloat) {
        // Main fluffy cloud body with perfect scalloped edges like reference
        let bodyCenter = CGPoint(x: centerX - 2*scale, y: centerY + 2*scale)
        let bodyWidth = 30*scale
        let bodyHeight = 16*scale
        
        // Main body oval
        path.addEllipse(in: CGRect(
            x: bodyCenter.x - bodyWidth/2,
            y: bodyCenter.y - bodyHeight/2,
            width: bodyWidth,
            height: bodyHeight
        ))
        
        // Perfect scalloped edges like the reference image
        let scallops = [
            // Top row of scallops
            CGRect(x: bodyCenter.x - 12*scale, y: bodyCenter.y - bodyHeight/2 - 2*scale, width: 5*scale, height: 5*scale),
            CGRect(x: bodyCenter.x - 5*scale, y: bodyCenter.y - bodyHeight/2 - 2.5*scale, width: 4.5*scale, height: 4.5*scale),
            CGRect(x: bodyCenter.x + 2*scale, y: bodyCenter.y - bodyHeight/2 - 2*scale, width: 4*scale, height: 4*scale),
            CGRect(x: bodyCenter.x + 8*scale, y: bodyCenter.y - bodyHeight/2 - 1.5*scale, width: 3.5*scale, height: 3.5*scale),
            
            // Left side scallops
            CGRect(x: bodyCenter.x - bodyWidth/2 - 2*scale, y: bodyCenter.y - 5*scale, width: 4*scale, height: 4*scale),
            CGRect(x: bodyCenter.x - bodyWidth/2 - 1.5*scale, y: bodyCenter.y, width: 3.5*scale, height: 4*scale),
            CGRect(x: bodyCenter.x - bodyWidth/2 - 2*scale, y: bodyCenter.y + 4*scale, width: 4*scale, height: 3.5*scale),
            
            // Right side scallops
            CGRect(x: bodyCenter.x + bodyWidth/2 - 2*scale, y: bodyCenter.y - 3*scale, width: 3.5*scale, height: 4*scale),
            CGRect(x: bodyCenter.x + bodyWidth/2 - 1.5*scale, y: bodyCenter.y + 2*scale, width: 4*scale, height: 3.5*scale),
            
            // Bottom scallops
            CGRect(x: bodyCenter.x - 6*scale, y: bodyCenter.y + bodyHeight/2 - 1.5*scale, width: 4*scale, height: 3*scale),
            CGRect(x: bodyCenter.x + 1*scale, y: bodyCenter.y + bodyHeight/2 - 2*scale, width: 3.5*scale, height: 3.5*scale),
            CGRect(x: bodyCenter.x + 7*scale, y: bodyCenter.y + bodyHeight/2 - 1*scale, width: 3*scale, height: 3*scale)
        ]
        
        for scallop in scallops {
            path.addEllipse(in: scallop)
        }
    }
    
    private func createSheepFace(path: inout Path, centerX: CGFloat, centerY: CGFloat, scale: CGFloat) {
        // White oval face positioned exactly like reference image
        let faceCenter = CGPoint(x: centerX + 12*scale, y: centerY - 2*scale)
        let faceWidth = 10*scale
        let faceHeight = 12*scale
        
        path.addEllipse(in: CGRect(
            x: faceCenter.x - faceWidth/2,
            y: faceCenter.y - faceHeight/2,
            width: faceWidth,
            height: faceHeight
        ))
    }
    
    private func createDroppyEars(path: inout Path, centerX: CGFloat, centerY: CGFloat, scale: CGFloat) {
        // Black droopy ears exactly like reference
        let faceCenter = CGPoint(x: centerX + 12*scale, y: centerY - 2*scale)
        let earWidth = 2.5*scale
        let earHeight = 5*scale
        
        // Left ear
        let leftEarCenter = CGPoint(x: faceCenter.x - 3*scale, y: faceCenter.y - 4*scale)
        createDroppyEarShape(path: &path, center: leftEarCenter, width: earWidth, height: earHeight)
        
        // Right ear  
        let rightEarCenter = CGPoint(x: faceCenter.x + 3*scale, y: faceCenter.y - 4*scale)
        createDroppyEarShape(path: &path, center: rightEarCenter, width: earWidth, height: earHeight)
    }
    
    private func createDroppyEarShape(path: inout Path, center: CGPoint, width: CGFloat, height: CGFloat) {
        // Create perfect droopy ear shape wider at bottom like reference
        path.move(to: CGPoint(x: center.x, y: center.y - height/2))
        
        // Smooth curves for droopy shape
        path.addQuadCurve(
            to: CGPoint(x: center.x + width/2, y: center.y - height/4),
            control: CGPoint(x: center.x + width/2, y: center.y - height/2)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: center.x + width/3, y: center.y + height/2),
            control: CGPoint(x: center.x + width/2, y: center.y + height/4)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: center.x - width/3, y: center.y + height/2),
            control: CGPoint(x: center.x, y: center.y + height/2)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: center.x - width/2, y: center.y - height/4),
            control: CGPoint(x: center.x - width/2, y: center.y + height/4)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: center.x, y: center.y - height/2),
            control: CGPoint(x: center.x - width/2, y: center.y - height/2)
        )
    }
    
    private func createSheepEyes(path: inout Path, centerX: CGFloat, centerY: CGFloat, scale: CGFloat) {
        // Simple black oval eyes like reference
        let faceCenter = CGPoint(x: centerX + 12*scale, y: centerY - 2*scale)
        let eyeWidth = 1.5*scale
        let eyeHeight = 1.2*scale
        
        // Left eye
        path.addEllipse(in: CGRect(
            x: faceCenter.x - 2.5*scale - eyeWidth/2,
            y: faceCenter.y - 1*scale - eyeHeight/2,
            width: eyeWidth,
            height: eyeHeight
        ))
        
        // Right eye
        path.addEllipse(in: CGRect(
            x: faceCenter.x + 1.5*scale - eyeWidth/2,
            y: faceCenter.y - 1*scale - eyeHeight/2,
            width: eyeWidth,
            height: eyeHeight
        ))
    }
    
    private func createSheepNose(path: inout Path, centerX: CGFloat, centerY: CGFloat, scale: CGFloat) {
        // Small black nose
        let faceCenter = CGPoint(x: centerX + 12*scale, y: centerY - 2*scale)
        let noseSize = 0.8*scale
        
        path.addEllipse(in: CGRect(
            x: faceCenter.x - noseSize/2,
            y: faceCenter.y + 1.5*scale - noseSize/2,
            width: noseSize,
            height: noseSize * 0.7
        ))
    }
    
    private func createSheepLegs(path: inout Path, centerX: CGFloat, centerY: CGFloat, scale: CGFloat) {
        // Four black legs with hooves exactly like reference
        let bodyCenter = CGPoint(x: centerX - 2*scale, y: centerY + 2*scale)
        let legWidth = 2*scale
        let legHeight = 8*scale
        let hoofWidth = 2.5*scale
        let hoofHeight = 1.5*scale
        
        // Leg positions evenly spaced under body
        let legPositions: [CGFloat] = [-8*scale, -3*scale, 3*scale, 8*scale]
        
        for legX in legPositions {
            let legBottom = bodyCenter.y + 8*scale + legHeight
            
            // Leg (rectangle)
            path.addRect(CGRect(
                x: bodyCenter.x + legX - legWidth/2,
                y: bodyCenter.y + 8*scale,
                width: legWidth,
                height: legHeight
            ))
            
            // Hoof (oval at bottom)
            path.addEllipse(in: CGRect(
                x: bodyCenter.x + legX - hoofWidth/2,
                y: legBottom - hoofHeight/2,
                width: hoofWidth,
                height: hoofHeight
            ))
        }
    }
}

// MARK: - Shared Coordinate System for Sheep
struct SheepCoordinates {
    let rect: CGRect
    let centerX: CGFloat
    let centerY: CGFloat
    let bodyWidth: CGFloat
    let bodyHeight: CGFloat
    let bodyCenter: CGPoint
    let faceWidth: CGFloat
    let faceHeight: CGFloat
    let faceCenter: CGPoint
    
    init(in rect: CGRect) {
        self.rect = rect
        self.centerX = rect.midX
        self.centerY = rect.midY
        self.bodyWidth = rect.width * 0.7
        self.bodyHeight = rect.height * 0.5
        self.bodyCenter = CGPoint(x: centerX, y: centerY + rect.height * 0.1)
        self.faceWidth = bodyWidth * 0.4
        self.faceHeight = bodyHeight * 0.8
        self.faceCenter = CGPoint(x: centerX + bodyWidth * 0.25, y: centerY - rect.height * 0.05)
    }
}

// MARK: - Layered Sheep Shapes (Multi-colored)
struct SheepBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let coords = SheepCoordinates(in: rect)
        var path = Path()
        
        // Create main body oval
        let mainRect = CGRect(
            x: coords.bodyCenter.x - coords.bodyWidth/2,
            y: coords.bodyCenter.y - coords.bodyHeight/2,
            width: coords.bodyWidth,
            height: coords.bodyHeight
        )
        path.addEllipse(in: mainRect)
        
        // Add scalloped bumps around the edge for fluffy cloud texture
        let bumpSize = coords.bodyHeight * 0.25
        let bumps = [
            // Top scallops
            CGRect(x: coords.bodyCenter.x - coords.bodyWidth * 0.3, y: coords.bodyCenter.y - coords.bodyHeight/2 - bumpSize * 0.3, width: bumpSize, height: bumpSize),
            CGRect(x: coords.bodyCenter.x - coords.bodyWidth * 0.1, y: coords.bodyCenter.y - coords.bodyHeight/2 - bumpSize * 0.4, width: bumpSize * 0.8, height: bumpSize * 0.8),
            CGRect(x: coords.bodyCenter.x + coords.bodyWidth * 0.1, y: coords.bodyCenter.y - coords.bodyHeight/2 - bumpSize * 0.3, width: bumpSize * 0.9, height: bumpSize * 0.9),
            CGRect(x: coords.bodyCenter.x + coords.bodyWidth * 0.25, y: coords.bodyCenter.y - coords.bodyHeight/2 - bumpSize * 0.2, width: bumpSize * 0.7, height: bumpSize * 0.7),
            
            // Left side scallops
            CGRect(x: coords.bodyCenter.x - coords.bodyWidth/2 - bumpSize * 0.3, y: coords.bodyCenter.y - coords.bodyHeight * 0.2, width: bumpSize * 0.8, height: bumpSize * 0.8),
            CGRect(x: coords.bodyCenter.x - coords.bodyWidth/2 - bumpSize * 0.2, y: coords.bodyCenter.y, width: bumpSize * 0.6, height: bumpSize * 0.9),
            CGRect(x: coords.bodyCenter.x - coords.bodyWidth/2 - bumpSize * 0.3, y: coords.bodyCenter.y + coords.bodyHeight * 0.2, width: bumpSize * 0.7, height: bumpSize * 0.7),
            
            // Right side scallops
            CGRect(x: coords.bodyCenter.x + coords.bodyWidth/2 - bumpSize * 0.3, y: coords.bodyCenter.y - coords.bodyHeight * 0.15, width: bumpSize * 0.7, height: bumpSize * 0.8),
            CGRect(x: coords.bodyCenter.x + coords.bodyWidth/2 - bumpSize * 0.2, y: coords.bodyCenter.y + coords.bodyHeight * 0.1, width: bumpSize * 0.8, height: bumpSize * 0.6),
            
            // Bottom scallops
            CGRect(x: coords.bodyCenter.x - coords.bodyWidth * 0.2, y: coords.bodyCenter.y + coords.bodyHeight/2 - bumpSize * 0.2, width: bumpSize * 0.8, height: bumpSize * 0.6),
            CGRect(x: coords.bodyCenter.x, y: coords.bodyCenter.y + coords.bodyHeight/2 - bumpSize * 0.3, width: bumpSize * 0.7, height: bumpSize * 0.7),
            CGRect(x: coords.bodyCenter.x + coords.bodyWidth * 0.15, y: coords.bodyCenter.y + coords.bodyHeight/2 - bumpSize * 0.2, width: bumpSize * 0.6, height: bumpSize * 0.5)
        ]
        
        for bump in bumps {
            path.addEllipse(in: bump)
        }
        
        return path
    }
}

struct SheepFaceShape: Shape {
    func path(in rect: CGRect) -> Path {
        let coords = SheepCoordinates(in: rect)
        var path = Path()
        
        // Create white face (oval shape positioned on the right side)
        let faceRect = CGRect(
            x: coords.faceCenter.x - coords.faceWidth/2,
            y: coords.faceCenter.y - coords.faceHeight/2,
            width: coords.faceWidth,
            height: coords.faceHeight
        )
        path.addEllipse(in: faceRect)
        
        return path
    }
}

struct SheepEarsShape: Shape {
    func path(in rect: CGRect) -> Path {
        let coords = SheepCoordinates(in: rect)
        var path = Path()
        
        let earWidth = coords.faceWidth * 0.25
        let earHeight = coords.faceHeight * 0.4
        
        // Left ear
        let leftEarCenter = CGPoint(x: coords.faceCenter.x - coords.faceWidth * 0.2, y: coords.faceCenter.y - coords.faceHeight * 0.3)
        path.addPath(createDroppyEar(center: leftEarCenter, width: earWidth, height: earHeight))
        
        // Right ear
        let rightEarCenter = CGPoint(x: coords.faceCenter.x + coords.faceWidth * 0.2, y: coords.faceCenter.y - coords.faceHeight * 0.3)
        path.addPath(createDroppyEar(center: rightEarCenter, width: earWidth, height: earHeight))
        
        return path
    }
    
    private func createDroppyEar(center: CGPoint, width: CGFloat, height: CGFloat) -> Path {
        var path = Path()
        
        // Create a droopy ear shape (wider at bottom, like in reference image)
        path.move(to: CGPoint(x: center.x, y: center.y - height/2))
        
        // Top curve
        path.addCurve(
            to: CGPoint(x: center.x + width/2, y: center.y - height/4),
            control1: CGPoint(x: center.x + width/3, y: center.y - height/2),
            control2: CGPoint(x: center.x + width/2, y: center.y - height/3)
        )
        
        // Right side curve (droopy)
        path.addCurve(
            to: CGPoint(x: center.x + width/3, y: center.y + height/2),
            control1: CGPoint(x: center.x + width/2, y: center.y),
            control2: CGPoint(x: center.x + width/2, y: center.y + height/3)
        )
        
        // Bottom curve
        path.addCurve(
            to: CGPoint(x: center.x - width/3, y: center.y + height/2),
            control1: CGPoint(x: center.x, y: center.y + height/2),
            control2: CGPoint(x: center.x - width/6, y: center.y + height/2)
        )
        
        // Left side curve (droopy)
        path.addCurve(
            to: CGPoint(x: center.x - width/2, y: center.y - height/4),
            control1: CGPoint(x: center.x - width/2, y: center.y + height/3),
            control2: CGPoint(x: center.x - width/2, y: center.y)
        )
        
        // Close back to top
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y - height/2),
            control1: CGPoint(x: center.x - width/2, y: center.y - height/3),
            control2: CGPoint(x: center.x - width/3, y: center.y - height/2)
        )
        
        return path
    }
}

struct SheepEyesShape: Shape {
    func path(in rect: CGRect) -> Path {
        let coords = SheepCoordinates(in: rect)
        var path = Path()
        
        let eyeWidth = coords.faceWidth * 0.15
        let eyeHeight = eyeWidth * 0.8
        
        // Left eye
        let leftEyeRect = CGRect(
            x: coords.faceCenter.x - coords.faceWidth * 0.15 - eyeWidth/2,
            y: coords.faceCenter.y - coords.faceHeight * 0.1 - eyeHeight/2,
            width: eyeWidth,
            height: eyeHeight
        )
        path.addEllipse(in: leftEyeRect)
        
        // Right eye
        let rightEyeRect = CGRect(
            x: coords.faceCenter.x + coords.faceWidth * 0.15 - eyeWidth/2,
            y: coords.faceCenter.y - coords.faceHeight * 0.1 - eyeHeight/2,
            width: eyeWidth,
            height: eyeHeight
        )
        path.addEllipse(in: rightEyeRect)
        
        return path
    }
}

struct SheepNoseShape: Shape {
    func path(in rect: CGRect) -> Path {
        let coords = SheepCoordinates(in: rect)
        var path = Path()
        
        let noseWidth = coords.faceWidth * 0.08
        let noseHeight = noseWidth * 0.6
        let noseRect = CGRect(
            x: coords.faceCenter.x - noseWidth/2,
            y: coords.faceCenter.y + coords.faceHeight * 0.1 - noseHeight/2,
            width: noseWidth,
            height: noseHeight
        )
        path.addEllipse(in: noseRect)
        
        return path
    }
}

struct SheepLegsShape: Shape {
    func path(in rect: CGRect) -> Path {
        let coords = SheepCoordinates(in: rect)
        var path = Path()
        
        let legWidth = coords.bodyWidth * 0.08
        let legHeight = coords.rect.height * 0.25
        let hoofWidth = legWidth * 1.2
        let hoofHeight = legHeight * 0.2
        
        // Leg positions (evenly spaced under body)
        let legSpacing = coords.bodyWidth * 0.2
        let legY = coords.bodyCenter.y + coords.bodyHeight/2 + legHeight/2
        
        for i in 0..<4 {
            let legX = coords.centerX - coords.bodyWidth * 0.25 + CGFloat(i) * legSpacing
            
            // Leg (rectangle)
            let legRect = CGRect(
                x: legX - legWidth/2,
                y: legY - legHeight/2,
                width: legWidth,
                height: legHeight
            )
            path.addRect(legRect)
            
            // Hoof (oval at bottom of leg)
            let hoofRect = CGRect(
                x: legX - hoofWidth/2,
                y: legY + legHeight/2 - hoofHeight/2,
                width: hoofWidth,
                height: hoofHeight
            )
            path.addEllipse(in: hoofRect)
        }
        
        return path
    }
}

// MARK: - Complete Layered Sheep View
struct LayeredCartoonSheep: View {
    var body: some View {
        ZStack {
            whiteComponents
            blackComponents
        }
    }
    
    private var whiteComponents: some View {
        ZStack {
            SheepBodyShape().fill(.white)
            SheepFaceShape().fill(.white)
        }
    }
    
    private var blackComponents: some View {
        ZStack {
            SheepEarsShape().fill(.black)
            SheepEyesShape().fill(.black)
            SheepNoseShape().fill(.black)
            SheepLegsShape().fill(.black)
        }
    }
}

struct EnhancedCloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Create a fluffy cloud with multiple overlapping circles
        let circles = [
            CGRect(x: rect.minX, y: rect.midY, width: rect.width * 0.3, height: rect.height * 0.6),
            CGRect(x: rect.minX + rect.width * 0.2, y: rect.minY, width: rect.width * 0.4, height: rect.height * 0.8),
            CGRect(x: rect.minX + rect.width * 0.5, y: rect.minY + rect.height * 0.1, width: rect.width * 0.35, height: rect.height * 0.7),
            CGRect(x: rect.minX + rect.width * 0.7, y: rect.midY, width: rect.width * 0.3, height: rect.height * 0.5)
        ]
        
        for circle in circles {
            path.addEllipse(in: circle)
        }
        
        return path
    }
}

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.4
        
        for i in 0..<10 {
            let angle = Double(i) * .pi / 5
            let currentRadius = i % 2 == 0 ? radius : innerRadius
            let point = CGPoint(
                x: center.x + cos(angle) * currentRadius,
                y: center.y + sin(angle) * currentRadius
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.closeSubpath()
        return path
    }
}

struct EnhancedHillShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        
        // Create rolling hills with smooth curves
        let controlPoints = [
            CGPoint(x: rect.width * 0.2, y: rect.minY + rect.height * 0.3),
            CGPoint(x: rect.width * 0.5, y: rect.minY),
            CGPoint(x: rect.width * 0.8, y: rect.minY + rect.height * 0.4)
        ]
        
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.33, y: rect.minY + rect.height * 0.2),
            control: controlPoints[0]
        )
        
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.66, y: rect.minY + rect.height * 0.3),
            control: controlPoints[1]
        )
        
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: controlPoints[2]
        )
        
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        
        return path
    }
}

struct EnhancedGrassShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Create a more natural grass blade with curves
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        
        // Left side curve
        path.addQuadCurve(
            to: CGPoint(x: rect.midX - rect.width * 0.2, y: rect.minY + rect.height * 0.3),
            control: CGPoint(x: rect.midX - rect.width * 0.1, y: rect.midY)
        )
        
        // Tip curve
        path.addQuadCurve(
            to: CGPoint(x: rect.midX + rect.width * 0.1, y: rect.minY),
            control: CGPoint(x: rect.midX - rect.width * 0.05, y: rect.minY)
        )
        
        // Right side curve
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control: CGPoint(x: rect.midX + rect.width * 0.05, y: rect.midY)
        )
        
        return path
    }
}

// Legacy sheep shape for backward compatibility
struct SheepShape: Shape {
    func path(in rect: CGRect) -> Path {
        return EnhancedSheepShape().path(in: rect)
    }
}

// MARK: - Gentle Waves Animation

class GentleWavesAnimation: AnimatedBackground {
    let id = "gentle_waves"
    let title = "Mystic Ocean"
    let category = BackgroundCategory.nature
    
    func createView(intensity: Float, speed: Float, colorTheme: ColorTheme, dimmed: Bool) -> AnyView {
        AnyView(EnhancedGentleWavesView(intensity: intensity, speed: speed, colorTheme: colorTheme, dimmed: dimmed))
    }
}

struct EnhancedGentleWavesView: View {
    let intensity: Float
    let speed: Float
    let colorTheme: ColorTheme
    let dimmed: Bool
    
    @State private var waveOffset: CGFloat = 0
    @State private var deepWaveOffset: CGFloat = 0
    @State private var bubblePositions: [BubbleData] = []
    @State private var shimmerOffset: CGFloat = 0
    @State private var surfaceGlitter: [GlitterData] = []
    @State private var seaweed: [SeaweedData] = []
    @State private var fish: [FishData] = []
    @State private var jellyfish: [JellyfishData] = []
    @State private var plankton: [PlanktonData] = []
    
    private struct BubbleData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        let size: CGFloat
        let riseSpeed: CGFloat
        var opacity: Double
        let wobblePhase: Double
    }
    
    private struct GlitterData: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let intensity: Double
        let sparklePhase: Double
    }
    
    private struct SeaweedData: Identifiable {
        let id = UUID()
        let x: CGFloat
        let baseY: CGFloat
        var swayPhase: Double
        let height: CGFloat
        let swayAmplitude: CGFloat
        let segments: Int
    }
    
    private struct FishData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var velocity: CGVector
        let size: CGFloat
        let color: Color
        var swimmingPhase: Double
        let schoolId: Int
    }
    
    private struct JellyfishData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var pulsePhase: Double
        let size: CGFloat
        var driftVelocity: CGVector
        let opacity: Double
        let tentacleCount: Int
    }
    
    private struct PlanktonData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        let size: CGFloat
        var glowPhase: Double
        let color: Color
        var driftVelocity: CGVector
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Deep ocean background with atmospheric depth
                ZStack {
                    // Deep water gradient
                    RadialGradient(
                        colors: [
                            dimmed ? .black.opacity(0.9) : .indigo.opacity(0.8),
                            dimmed ? .blue.opacity(0.3) : .blue.opacity(0.6),
                            dimmed ? .teal.opacity(0.2) : .teal.opacity(0.5),
                            dimmed ? .cyan.opacity(0.1) : .cyan.opacity(0.3)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: geometry.size.height
                    )
                    
                    // Underwater caustics effect
                    ForEach(0..<Int(intensity * 8) + 3, id: \.self) { index in
                        CausticsShape(phase: shimmerOffset + CGFloat(index * 30))
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.cyan.opacity((dimmed ? 0.02 : 0.08) * Double(intensity)),
                                        Color.white.opacity((dimmed ? 0.01 : 0.04) * Double(intensity))
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(
                                width: CGFloat.random(in: 100...200),
                                height: CGFloat.random(in: 50...100)
                            )
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: (geometry.size.height * 0.3)...geometry.size.height)
                            )
                            .blur(radius: 3)
                            .blendMode(.screen)
                    }
                }
                
                // Rising bubbles with physics
                ForEach(bubblePositions) { bubble in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(bubble.opacity * (dimmed ? 0.2 : 0.4)),
                                    Color.cyan.opacity(bubble.opacity * (dimmed ? 0.1 : 0.2)),
                                    .clear
                                ],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: bubble.size
                            )
                        )
                        .frame(width: bubble.size, height: bubble.size)
                        .position(
                            x: bubble.x + sin(bubble.wobblePhase) * 10,
                            y: bubble.y
                        )
                        .shadow(color: .white.opacity(0.3), radius: 2)
                }
                
                // Swaying seaweed at the bottom
                ForEach(seaweed) { seaweedStrand in
                    SeaweedShape(
                        segments: seaweedStrand.segments,
                        height: seaweedStrand.height,
                        swayPhase: seaweedStrand.swayPhase,
                        swayAmplitude: seaweedStrand.swayAmplitude
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.green.opacity(dimmed ? 0.3 : 0.6),
                                Color.green.opacity(dimmed ? 0.1 : 0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .position(x: seaweedStrand.x, y: seaweedStrand.baseY)
                    .shadow(color: .black.opacity(0.3), radius: 2)
                }
                
                // Swimming fish in schools
                ForEach(fish) { fishItem in
                    FishShape(swimmingPhase: fishItem.swimmingPhase)
                        .fill(fishItem.color.opacity(dimmed ? 0.4 : 0.7))
                        .frame(width: fishItem.size, height: fishItem.size * 0.6)
                        .position(x: fishItem.x, y: fishItem.y)
                        .shadow(color: fishItem.color.opacity(0.3), radius: 1)
                }
                
                // Graceful jellyfish
                ForEach(jellyfish) { jellyfishItem in
                    JellyfishShape(
                        pulsePhase: jellyfishItem.pulsePhase,
                        tentacleCount: jellyfishItem.tentacleCount
                    )
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(jellyfishItem.opacity * (dimmed ? 0.3 : 0.5)),
                                Color.pink.opacity(jellyfishItem.opacity * (dimmed ? 0.2 : 0.3)),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: jellyfishItem.size
                        )
                    )
                    .frame(width: jellyfishItem.size, height: jellyfishItem.size * 1.2)
                    .position(x: jellyfishItem.x, y: jellyfishItem.y)
                    .blur(radius: 1)
                    .blendMode(.screen)
                }
                
                // Glowing plankton
                ForEach(plankton) { planktonItem in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    planktonItem.color.opacity(dimmed ? 0.4 : 0.8),
                                    planktonItem.color.opacity(dimmed ? 0.1 : 0.3),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: planktonItem.size
                            )
                        )
                        .frame(width: planktonItem.size, height: planktonItem.size)
                        .position(x: planktonItem.x, y: planktonItem.y)
                        .scaleEffect(0.5 + sin(planktonItem.glowPhase) * 0.3)
                        .blur(radius: 0.5)
                        .blendMode(.screen)
                }
                
                // Multi-layered waves with depth
                ForEach(0..<Int(intensity * 5) + 2, id: \.self) { layer in
                    let layerDepth = CGFloat(layer + 1)
                    let waveHeight = CGFloat(intensity * 30) + CGFloat(layer * 8)
                    let frequency = 1.2 + Double(layer) * 0.3
                    
                    EnhancedWaveShape(
                        waveHeight: waveHeight,
                        frequency: frequency,
                        offset: waveOffset + deepWaveOffset * 0.3 + CGFloat(layer * 40),
                        complexity: Int(intensity * 3) + 1
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity((dimmed ? 0.03 : 0.08) / layerDepth),
                                Color.cyan.opacity((dimmed ? 0.02 : 0.05) / layerDepth),
                                Color.blue.opacity((dimmed ? 0.01 : 0.03) / layerDepth)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blendMode(layer < 2 ? .screen : .overlay)
                    .blur(radius: layerDepth * 0.5)
                }
                
                // Surface sparkles and glitter
                ForEach(surfaceGlitter) { glitter in
                    let sparkle = sin(glitter.sparklePhase) * 0.5 + 0.5
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(glitter.intensity * sparkle * (dimmed ? 0.2 : 0.6)),
                                    Color.cyan.opacity(glitter.intensity * sparkle * (dimmed ? 0.1 : 0.3)),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 3
                            )
                        )
                        .frame(width: 2, height: 2)
                        .position(x: glitter.x, y: glitter.y)
                        .scaleEffect(0.5 + sparkle * 1.5)
                        .blur(radius: 0.5)
                }
                
                // Foam and spray effects
                ForEach(0..<Int(intensity * 15) + 5, id: \.self) { index in
                    let foamSize = CGFloat.random(in: 2...12)
                    let randomY = CGFloat.random(in: 0.7...1.0)
                    let yPosition = geometry.size.height * randomY
                    let opacity = Double.random(in: 0.1...0.4)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(opacity * (dimmed ? 0.3 : 0.7)),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: foamSize
                            )
                        )
                        .frame(width: foamSize, height: foamSize)
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: yPosition + sin(waveOffset + CGFloat(index)) * 15
                        )
                        .animation(
                            .easeInOut(duration: Double.random(in: 1...3) / Double(speed))
                            .repeatForever(autoreverses: true),
                            value: waveOffset
                        )
                        .blur(radius: 1)
                }
            }
        }
        .onAppear {
            setupBubbles()
            setupSurfaceGlitter()
            setupSeaweed()
            setupFish()
            setupJellyfish()
            setupPlankton()
            startAnimations()
        }
    }
    
    private func setupBubbles() {
        bubblePositions = []
        let bubbleCount = Int(intensity * 20) + 5
        
        for _ in 0..<bubbleCount {
            bubblePositions.append(BubbleData(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: UIScreen.main.bounds.height...UIScreen.main.bounds.height + 200),
                size: CGFloat.random(in: 3...15),
                riseSpeed: CGFloat.random(in: 20...60),
                opacity: Double.random(in: 0.2...0.8),
                wobblePhase: Double.random(in: 0...2 * .pi)
            ))
        }
    }
    
    private func setupSurfaceGlitter() {
        surfaceGlitter = []
        let glitterCount = Int(intensity * 30) + 10
        
        for i in 0..<glitterCount {
            surfaceGlitter.append(GlitterData(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: UIScreen.main.bounds.height * 0.6...UIScreen.main.bounds.height * 0.8),
                intensity: Double.random(in: 0.3...1.0),
                sparklePhase: Double(i) * 0.3
            ))
        }
    }
    
    private func setupSeaweed() {
        seaweed = []
        let seaweedCount = Int(intensity * 15) + 8
        let bounds = UIScreen.main.bounds
        
        for _ in 0..<seaweedCount {
            seaweed.append(SeaweedData(
                x: CGFloat.random(in: 0...bounds.width),
                baseY: bounds.height - CGFloat.random(in: 20...80),
                swayPhase: Double.random(in: 0...2 * .pi),
                height: CGFloat.random(in: 60...120),
                swayAmplitude: CGFloat.random(in: 10...25),
                segments: Int.random(in: 5...12)
            ))
        }
    }
    
    private func setupFish() {
        fish = []
        let fishCount = Int(intensity * 25) + 15
        let bounds = UIScreen.main.bounds
        let fishColors: [Color] = [.orange, .yellow, .cyan, .blue, .gray]
        
        for i in 0..<fishCount {
            let schoolId = i / 5  // Groups of 5 fish per school
            fish.append(FishData(
                x: CGFloat.random(in: -50...bounds.width + 50),
                y: CGFloat.random(in: bounds.height * 0.3...bounds.height * 0.8),
                velocity: CGVector(
                    dx: Double.random(in: -30...30),
                    dy: Double.random(in: -10...10)
                ),
                size: CGFloat.random(in: 8...20),
                color: fishColors.randomElement() ?? .orange,
                swimmingPhase: Double.random(in: 0...2 * .pi),
                schoolId: schoolId
            ))
        }
    }
    
    private func setupJellyfish() {
        jellyfish = []
        let jellyfishCount = Int(intensity * 8) + 4
        let bounds = UIScreen.main.bounds
        
        for _ in 0..<jellyfishCount {
            jellyfish.append(JellyfishData(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: bounds.height * 0.2...bounds.height * 0.7),
                pulsePhase: Double.random(in: 0...2 * .pi),
                size: CGFloat.random(in: 25...60),
                driftVelocity: CGVector(
                    dx: Double.random(in: -8...8),
                    dy: Double.random(in: -5...5)
                ),
                opacity: Double.random(in: 0.3...0.8),
                tentacleCount: Int.random(in: 6...12)
            ))
        }
    }
    
    private func setupPlankton() {
        plankton = []
        let planktonCount = Int(intensity * 40) + 20
        let bounds = UIScreen.main.bounds
        let planktonColors: [Color] = [.green, .cyan, .blue, .white, .yellow]
        
        for _ in 0..<planktonCount {
            plankton.append(PlanktonData(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: 0...bounds.height),
                size: CGFloat.random(in: 1...4),
                glowPhase: Double.random(in: 0...2 * .pi),
                color: planktonColors.randomElement() ?? .cyan,
                driftVelocity: CGVector(
                    dx: Double.random(in: -2...2),
                    dy: Double.random(in: -2...2)
                )
            ))
        }
    }
    
    private func startAnimations() {
        // Primary wave animation
        withAnimation(
            .linear(duration: 6.0 / Double(speed))
            .repeatForever(autoreverses: false)
        ) {
            waveOffset = 400
        }
        
        // Deep wave animation (slower)
        withAnimation(
            .linear(duration: 12.0 / Double(speed))
            .repeatForever(autoreverses: false)
        ) {
            deepWaveOffset = 200
        }
        
        // Caustics shimmer
        withAnimation(
            .linear(duration: 8.0 / Double(speed))
            .repeatForever(autoreverses: false)
        ) {
            shimmerOffset = 300
        }
        
        // Marine life animations
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateBubbles()
            updateSeaweed()
            updateFish()
            updateJellyfish()
            updatePlankton()
        }
    }
    
    private func updateBubbles() {
        for i in 0..<bubblePositions.count {
            bubblePositions[i].y -= bubblePositions[i].riseSpeed * 0.1
            bubblePositions[i].opacity = max(0, bubblePositions[i].opacity - 0.005)
            
            // Reset bubble if it reaches the top
            if bubblePositions[i].y < -50 {
                let newBubble = BubbleData(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: UIScreen.main.bounds.height + 50,
                    size: CGFloat.random(in: 3...15),
                    riseSpeed: CGFloat.random(in: 20...60),
                    opacity: Double.random(in: 0.2...0.8),
                    wobblePhase: Double.random(in: 0...2 * .pi)
                )
                bubblePositions[i] = newBubble
            }
        }
    }
    
    private func updateSeaweed() {
        for i in 0..<seaweed.count {
            seaweed[i].swayPhase += 0.03 * Double(speed)
        }
    }
    
    private func updateFish() {
        let bounds = UIScreen.main.bounds
        
        for i in 0..<fish.count {
            // Update swimming animation
            fish[i].swimmingPhase += 0.15 * Double(speed)
            
            // School behavior - fish in same school try to stay together
            var schoolCenterX: CGFloat = 0
            var schoolCenterY: CGFloat = 0
            var schoolMates = 0
            
            for j in 0..<fish.count {
                if fish[j].schoolId == fish[i].schoolId && i != j {
                    schoolCenterX += fish[j].x
                    schoolCenterY += fish[j].y
                    schoolMates += 1
                }
            }
            
            if schoolMates > 0 {
                schoolCenterX /= CGFloat(schoolMates)
                schoolCenterY /= CGFloat(schoolMates)
                
                // Gently steer towards school center
                let attraction = 0.5
                fish[i].velocity.dx += (Double(schoolCenterX - fish[i].x) * attraction * 0.01)
                fish[i].velocity.dy += (Double(schoolCenterY - fish[i].y) * attraction * 0.01)
            }
            
            // Apply movement
            fish[i].x += CGFloat(fish[i].velocity.dx * 0.1)
            fish[i].y += CGFloat(fish[i].velocity.dy * 0.1)
            
            // Boundary wrapping
            if fish[i].x > bounds.width + 50 {
                fish[i].x = -50
            } else if fish[i].x < -50 {
                fish[i].x = bounds.width + 50
            }
            
            if fish[i].y > bounds.height + 50 {
                fish[i].y = bounds.height * 0.3
            } else if fish[i].y < bounds.height * 0.2 {
                fish[i].y = bounds.height * 0.8
            }
            
            // Random direction changes
            if Double.random(in: 0...1) < 0.02 {
                fish[i].velocity.dx += Double.random(in: -5...5)
                fish[i].velocity.dy += Double.random(in: -3...3)
                
                // Limit velocity
                let maxSpeed = 40.0
                let currentSpeed = sqrt(fish[i].velocity.dx * fish[i].velocity.dx + fish[i].velocity.dy * fish[i].velocity.dy)
                if currentSpeed > maxSpeed {
                    fish[i].velocity.dx = (fish[i].velocity.dx / currentSpeed) * maxSpeed
                    fish[i].velocity.dy = (fish[i].velocity.dy / currentSpeed) * maxSpeed
                }
            }
        }
    }
    
    private func updateJellyfish() {
        let bounds = UIScreen.main.bounds
        
        for i in 0..<jellyfish.count {
            // Update pulsing animation
            jellyfish[i].pulsePhase += 0.08 * Double(speed)
            
            // Gentle floating movement
            jellyfish[i].x += CGFloat(jellyfish[i].driftVelocity.dx * 0.05)
            jellyfish[i].y += CGFloat(jellyfish[i].driftVelocity.dy * 0.05)
            
            // Add some sine wave motion
            let time = Date().timeIntervalSince1970
            let floatOffset = sin(time * 0.5 + Double(i) * 0.3) * 8
            jellyfish[i].y += CGFloat(floatOffset * 0.1)
            
            // Boundary wrapping
            if jellyfish[i].x > bounds.width + 100 {
                jellyfish[i].x = -100
            } else if jellyfish[i].x < -100 {
                jellyfish[i].x = bounds.width + 100
            }
            
            if jellyfish[i].y > bounds.height {
                jellyfish[i].y = bounds.height * 0.2
            } else if jellyfish[i].y < 0 {
                jellyfish[i].y = bounds.height * 0.7
            }
            
            // Occasional direction changes
            if Double.random(in: 0...1) < 0.015 {
                jellyfish[i].driftVelocity = CGVector(
                    dx: Double.random(in: -8...8),
                    dy: Double.random(in: -5...5)
                )
            }
        }
    }
    
    private func updatePlankton() {
        let bounds = UIScreen.main.bounds
        
        for i in 0..<plankton.count {
            // Update glow animation
            plankton[i].glowPhase += 0.1 * Double(speed)
            
            // Gentle drifting movement
            plankton[i].x += CGFloat(plankton[i].driftVelocity.dx * 0.1)
            plankton[i].y += CGFloat(plankton[i].driftVelocity.dy * 0.1)
            
            // Add some organic movement
            let time = Date().timeIntervalSince1970
            let organicX = sin(time * 0.3 + Double(i) * 0.1) * 2
            let organicY = cos(time * 0.4 + Double(i) * 0.15) * 2
            plankton[i].x += CGFloat(organicX * 0.1)
            plankton[i].y += CGFloat(organicY * 0.1)
            
            // Boundary wrapping
            if plankton[i].x > bounds.width + 20 {
                plankton[i].x = -20
            } else if plankton[i].x < -20 {
                plankton[i].x = bounds.width + 20
            }
            
            if plankton[i].y > bounds.height + 20 {
                plankton[i].y = -20
            } else if plankton[i].y < -20 {
                plankton[i].y = bounds.height + 20
            }
        }
    }
}

// MARK: - Enhanced Wave Shapes

struct EnhancedWaveShape: Shape {
    let waveHeight: CGFloat
    let frequency: Double
    let offset: CGFloat
    let complexity: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let midHeight = height * 0.7
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        // Create more complex wave with multiple harmonics
        for x in stride(from: 0, through: width, by: 0.5) {
            let normalizedX = Double(x) / Double(width)
            let baseAngle = normalizedX * frequency * 2 * .pi + Double(offset) * .pi / 180
            
            // Primary wave
            var y = sin(baseAngle) * Double(waveHeight)
            
            // Add harmonics for complexity
            for harmonic in 1...complexity {
                let harmonicFactor = 1.0 / Double(harmonic + 1)
                let harmonicFreq = frequency * Double(harmonic + 1)
                let harmonicAngle = normalizedX * harmonicFreq * 2 * .pi + Double(offset) * .pi / 180
                y += sin(harmonicAngle) * Double(waveHeight) * harmonicFactor * 0.3
            }
            
            let finalY = midHeight + CGFloat(y)
            path.addLine(to: CGPoint(x: x, y: finalY))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

struct CausticsShape: Shape {
    let phase: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Create organic, caustic-like patterns
        path.move(to: CGPoint(x: 0, y: height * 0.5))
        
        for x in stride(from: 0, through: width, by: 2) {
            let normalizedX = Double(x) / Double(width)
            let angle1 = normalizedX * 4 * .pi + Double(phase) * .pi / 180
            let angle2 = normalizedX * 6 * .pi + Double(phase) * .pi / 180 * 1.3
            
            let y1 = sin(angle1) * 0.3 + sin(angle2) * 0.2
            let finalY = height * (0.5 + CGFloat(y1) * 0.4)
            
            path.addLine(to: CGPoint(x: x, y: finalY))
        }
        
        // Close the shape with smooth curves
        for x in stride(from: width, through: 0, by: -2) {
            let normalizedX = Double(x) / Double(width)
            let angle1 = normalizedX * 3 * .pi + Double(phase) * .pi / 180 * 0.7
            let angle2 = normalizedX * 5 * .pi + Double(phase) * .pi / 180 * 1.1
            
            let y1 = cos(angle1) * 0.25 + cos(angle2) * 0.15
            let finalY = height * (0.5 + CGFloat(y1) * 0.3)
            
            path.addLine(to: CGPoint(x: x, y: finalY))
        }
        
        path.closeSubpath()
        return path
    }
}

// Legacy wave shape for backward compatibility
struct WaveShape: Shape {
    let waveHeight: CGFloat
    let frequency: Double
    let offset: CGFloat
    
    func path(in rect: CGRect) -> Path {
        return EnhancedWaveShape(
            waveHeight: waveHeight,
            frequency: frequency,
            offset: offset,
            complexity: 2
        ).path(in: rect)
    }
}

// MARK: - Marine Life Shapes

struct SeaweedShape: Shape {
    let segments: Int
    let height: CGFloat
    let swayPhase: Double
    let swayAmplitude: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let segmentHeight = height / CGFloat(segments)
        let startX = rect.midX
        let startY = rect.maxY
        
        path.move(to: CGPoint(x: startX, y: startY))
        
        for segment in 0..<segments {
            let y = startY - CGFloat(segment + 1) * segmentHeight
            let swayOffset = sin(swayPhase + Double(segment) * 0.5) * Double(swayAmplitude)
            let x = startX + CGFloat(swayOffset)
            
            let controlX = startX + CGFloat(swayOffset * 0.5)
            let controlY = y + segmentHeight * 0.5
            
            path.addQuadCurve(
                to: CGPoint(x: x, y: y),
                control: CGPoint(x: controlX, y: controlY)
            )
        }
        
        return path
    }
}

struct FishShape: Shape {
    let swimmingPhase: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let bodyWidth = rect.width * 0.7
        let bodyHeight = rect.height * 0.6
        let tailWidth = rect.width * 0.4
        let tailHeight = rect.height * 0.8
        
        // Fish body (ellipse)
        let bodyRect = CGRect(
            x: rect.minX,
            y: rect.midY - bodyHeight/2,
            width: bodyWidth,
            height: bodyHeight
        )
        path.addEllipse(in: bodyRect)
        
        // Tail (triangle with swimming motion)
        let tailOffset = sin(swimmingPhase) * 3
        let tailTip = CGPoint(x: rect.maxX, y: rect.midY + CGFloat(tailOffset))
        let tailTop = CGPoint(x: rect.maxX - tailWidth, y: rect.midY - tailHeight/2)
        let tailBottom = CGPoint(x: rect.maxX - tailWidth, y: rect.midY + tailHeight/2)
        
        path.move(to: tailTop)
        path.addLine(to: tailTip)
        path.addLine(to: tailBottom)
        path.closeSubpath()
        
        return path
    }
}

struct JellyfishShape: Shape {
    let pulsePhase: Double
    let tentacleCount: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Bell (dome)
        let pulseFactor = 1.0 + sin(pulsePhase) * 0.2
        let bellWidth = rect.width * CGFloat(pulseFactor)
        let bellHeight = rect.height * 0.3 * CGFloat(pulseFactor)
        
        let bellRect = CGRect(
            x: rect.midX - bellWidth/2,
            y: rect.minY,
            width: bellWidth,
            height: bellHeight
        )
        path.addEllipse(in: bellRect)
        
        // Tentacles
        let tentacleSpacing = bellWidth / CGFloat(tentacleCount + 1)
        for i in 0..<tentacleCount {
            let startX = bellRect.minX + CGFloat(i + 1) * tentacleSpacing
            let startY = bellRect.maxY
            
            let tentacleLength = rect.height * 0.7 * CGFloat(0.8 + Double.random(in: 0...0.4))
            let waveOffset = sin(pulsePhase + Double(i) * 0.3) * 5
            
            path.move(to: CGPoint(x: startX, y: startY))
            
            let segments = 8
            for segment in 1...segments {
                let y = startY + tentacleLength * CGFloat(segment) / CGFloat(segments)
                let x = startX + CGFloat(waveOffset * sin(Double(segment) * 0.5))
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
}

// MARK: - Firefly Meadow Animation

class FireflyMeadowAnimation: AnimatedBackground {
    let id = "firefly_meadow"
    let title = "Enchanted Garden"
    let category = BackgroundCategory.nature
    
    func createView(intensity: Float, speed: Float, colorTheme: ColorTheme, dimmed: Bool) -> AnyView {
        AnyView(EnhancedFireflyMeadowView(intensity: intensity, speed: speed, colorTheme: colorTheme, dimmed: dimmed))
    }
}

struct EnhancedFireflyMeadowView: View {
    let intensity: Float
    let speed: Float
    let colorTheme: ColorTheme
    let dimmed: Bool
    
    @State private var fireflies: [FireflyData] = []
    @State private var petals: [PetalData] = []
    @State private var mistParticles: [MistData] = []
    @State private var dewDrops: [DewData] = []
    @State private var moonGlow: Double = 0
    @State private var windPhase: Double = 0
    
    private struct FireflyData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var opacity: Double
        var size: CGFloat
        var velocity: CGVector
        var glowPhase: Double
        var trailPoints: [CGPoint]
        let color: Color
        var pulseIntensity: Double
    }
    
    private struct PetalData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var rotation: Double
        var rotationSpeed: Double
        let size: CGFloat
        let color: Color
        var fallSpeed: CGFloat
        var swayAmplitude: CGFloat
    }
    
    private struct MistData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var opacity: Double
        let size: CGFloat
        var driftSpeed: CGFloat
        var phase: Double
    }
    
    private struct DewData: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        var sparkle: Double
        let size: CGFloat
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layered night sky with depth
                nightSkyBackground(geometry: geometry)
                
                // Moonlight glow
                moonlightGlow(geometry: geometry)
                
                // Atmospheric mist
                atmosphericMist()
                
                // Multi-layered grass with atmospheric perspective
                grassLayers(geometry: geometry)
                
                // Falling flower petals
                ForEach(petals) { petal in
                    PetalShape()
                        .fill(petal.color.opacity(dimmed ? 0.3 : 0.6))
                        .frame(width: petal.size, height: petal.size * 1.5)
                        .rotationEffect(.degrees(petal.rotation))
                        .position(
                            x: petal.x + sin(petal.rotation * .pi / 180) * petal.swayAmplitude,
                            y: petal.y
                        )
                        .blur(radius: 0.5)
                        .shadow(color: petal.color.opacity(0.3), radius: 2)
                }
                
                // Enhanced fireflies with trails and varied colors
                ForEach(fireflies) { firefly in
                    ZStack {
                        // Firefly trail
                        if firefly.trailPoints.count > 1 {
                            Path { path in
                                for (index, point) in firefly.trailPoints.enumerated() {
                                    if index == 0 {
                                        path.move(to: point)
                                    } else {
                                        path.addLine(to: point)
                                    }
                                }
                            }
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        firefly.color.opacity(firefly.opacity * 0.1),
                                        firefly.color.opacity(firefly.opacity * 0.3),
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 2
                            )
                            .blur(radius: 1)
                        }
                        
                        // Main firefly glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        firefly.color.opacity(firefly.opacity * firefly.pulseIntensity),
                                        firefly.color.opacity(firefly.opacity * firefly.pulseIntensity * 0.5),
                                        firefly.color.opacity(firefly.opacity * firefly.pulseIntensity * 0.2),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: firefly.size * 2
                                )
                            )
                            .frame(width: firefly.size * 2, height: firefly.size * 2)
                            .position(x: firefly.x, y: firefly.y)
                            .blur(radius: 2)
                            .blendMode(.screen)
                        
                        // Core firefly body
                        Circle()
                            .fill(firefly.color.opacity(firefly.opacity * firefly.pulseIntensity))
                            .frame(width: firefly.size * 0.3, height: firefly.size * 0.3)
                            .position(x: firefly.x, y: firefly.y)
                            .shadow(color: firefly.color, radius: 3)
                    }
                }
                
                // Dew drops on grass
                ForEach(dewDrops) { dew in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(dew.sparkle * (dimmed ? 0.2 : 0.6)),
                                    Color.cyan.opacity(dew.sparkle * (dimmed ? 0.1 : 0.3)),
                                    .clear
                                ],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dew.size
                            )
                        )
                        .frame(width: dew.size, height: dew.size)
                        .position(x: dew.x, y: dew.y)
                        .scaleEffect(0.5 + dew.sparkle * 0.5)
                        .blur(radius: 0.5)
                }
            }
        }
        .onAppear {
            setupScene()
            startAnimations()
        }
    }
    
    private func setupScene() {
        setupFireflies()
        setupPetals()
        setupMist()
        setupDewDrops()
    }
    
    private func setupFireflies() {
        fireflies = []
        let count = Int(intensity * 25) + 8
        let fireflyColors: [Color] = [.yellow, .green, .orange, .cyan, .white]
        
        for _ in 0..<count {
            fireflies.append(FireflyData(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: UIScreen.main.bounds.height * 0.3...UIScreen.main.bounds.height * 0.8),
                opacity: Double.random(in: 0.3...0.9),
                size: CGFloat.random(in: 8...20),
                velocity: CGVector(
                    dx: Double.random(in: -15...15) * Double(speed),
                    dy: Double.random(in: -8...8) * Double(speed)
                ),
                glowPhase: Double.random(in: 0...2 * .pi),
                trailPoints: [],
                color: fireflyColors.randomElement() ?? .yellow,
                pulseIntensity: Double.random(in: 0.6...1.0)
            ))
        }
    }
    
    private func setupPetals() {
        petals = []
        let count = Int(intensity * 8) + 3
        let petalColors: [Color] = [.pink, .white, .purple, .yellow]
        
        for _ in 0..<count {
            petals.append(PetalData(
                x: CGFloat.random(in: -50...UIScreen.main.bounds.width + 50),
                y: CGFloat.random(in: -100...0),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: 0.5...2.0),
                size: CGFloat.random(in: 6...12),
                color: petalColors.randomElement() ?? .pink,
                fallSpeed: CGFloat.random(in: 10...30),
                swayAmplitude: CGFloat.random(in: 20...50)
            ))
        }
    }
    
    private func setupMist() {
        mistParticles = []
        let count = Int(intensity * 12) + 5
        
        for _ in 0..<count {
            mistParticles.append(MistData(
                x: CGFloat.random(in: -100...UIScreen.main.bounds.width + 100),
                y: CGFloat.random(in: UIScreen.main.bounds.height * 0.5...UIScreen.main.bounds.height),
                opacity: Double.random(in: 0.1...0.3),
                size: CGFloat.random(in: 80...150),
                driftSpeed: CGFloat.random(in: 5...15),
                phase: Double.random(in: 0...2 * .pi)
            ))
        }
    }
    
    private func setupDewDrops() {
        dewDrops = []
        let count = Int(intensity * 20) + 10
        
        for _ in 0..<count {
            dewDrops.append(DewData(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: UIScreen.main.bounds.height * 0.7...UIScreen.main.bounds.height),
                sparkle: 0.5,
                size: CGFloat.random(in: 2...6)
            ))
        }
    }
    
    private func startAnimations() {
        // Moon glow animation
        withAnimation(.easeInOut(duration: 8.0 / Double(speed)).repeatForever(autoreverses: true)) {
            moonGlow = 1.0
        }
        
        // Wind animation
        withAnimation(.easeInOut(duration: 6.0 / Double(speed)).repeatForever(autoreverses: true)) {
            windPhase = 2 * .pi
        }
        
        // Continuous updates
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            updateFireflies()
            updatePetals()
            updateMist()
            updateDewDrops()
        }
    }
    
    private func updateFireflies() {
        let bounds = UIScreen.main.bounds
        
        for i in 0..<fireflies.count {
            // Update trail
            fireflies[i].trailPoints.append(CGPoint(x: fireflies[i].x, y: fireflies[i].y))
            if fireflies[i].trailPoints.count > 15 {
                fireflies[i].trailPoints.removeFirst()
            }
            
            // Update position with organic movement
            let time = Date().timeIntervalSince1970
            let noiseX = sin(time * 0.5 + Double(i) * 0.3) * 2
            let noiseY = cos(time * 0.7 + Double(i) * 0.5) * 2
            
            fireflies[i].x += fireflies[i].velocity.dx * 0.05 + CGFloat(noiseX)
            fireflies[i].y += fireflies[i].velocity.dy * 0.05 + CGFloat(noiseY)
            
            // Update glow
            fireflies[i].glowPhase += 0.1 * Double(speed)
            fireflies[i].opacity = 0.4 + 0.6 * (sin(fireflies[i].glowPhase) + 1) / 2
            fireflies[i].pulseIntensity = 0.6 + 0.4 * (cos(fireflies[i].glowPhase * 1.3) + 1) / 2
            
            // Boundary wrapping
            if fireflies[i].x < -30 { fireflies[i].x = bounds.width + 30 }
            if fireflies[i].x > bounds.width + 30 { fireflies[i].x = -30 }
            if fireflies[i].y < -30 { fireflies[i].y = bounds.height + 30 }
            if fireflies[i].y > bounds.height + 30 { fireflies[i].y = -30 }
            
            // Occasional direction changes
            if Double.random(in: 0...1) < 0.015 {
                fireflies[i].velocity = CGVector(
                    dx: Double.random(in: -15...15) * Double(speed),
                    dy: Double.random(in: -8...8) * Double(speed)
                )
            }
        }
    }
    
    private func updatePetals() {
        let bounds = UIScreen.main.bounds
        
        for i in 0..<petals.count {
            petals[i].y += petals[i].fallSpeed * 0.05
            petals[i].rotation += petals[i].rotationSpeed
            
            if petals[i].y > bounds.height + 50 {
                petals[i].y = -50
                petals[i].x = CGFloat.random(in: -50...bounds.width + 50)
            }
        }
    }
    
    private func updateMist() {
        let bounds = UIScreen.main.bounds
        
        for i in 0..<mistParticles.count {
            mistParticles[i].x += mistParticles[i].driftSpeed * 0.05
            mistParticles[i].phase += 0.02
            
            if mistParticles[i].x > bounds.width + 100 {
                mistParticles[i].x = -100
            }
        }
    }
    
    private func updateDewDrops() {
        for i in 0..<dewDrops.count {
            let time = Date().timeIntervalSince1970
            dewDrops[i].sparkle = 0.3 + 0.7 * (sin(time * 2 + Double(i) * 0.5) + 1) / 2
        }
    }
    
    // MARK: - Helper Views
    
    private func nightSkyBackground(geometry: GeometryProxy) -> some View {
        ZStack {
            // Deep night sky
            RadialGradient(
                colors: [
                    Color.black.opacity(dimmed ? 0.95 : 0.85),
                    Color.indigo.opacity(dimmed ? 0.3 : 0.5),
                    Color.purple.opacity(dimmed ? 0.2 : 0.4)
                ],
                center: .init(x: 0.3, y: 0.2),
                startRadius: 0,
                endRadius: geometry.size.height
            )
        }
    }
    
    private func moonlightGlow(geometry: GeometryProxy) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(moonGlow * (dimmed ? 0.05 : 0.15)),
                        Color.blue.opacity(moonGlow * (dimmed ? 0.02 : 0.08)),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 150
                )
            )
            .frame(width: 300, height: 300)
            .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.15)
            .blur(radius: 10)
    }
    
    private func atmosphericMist() -> some View {
        ForEach(mistParticles) { mist in
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(mist.opacity * (dimmed ? 0.03 : 0.08)),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: mist.size
                    )
                )
                .frame(width: mist.size, height: mist.size)
                .position(
                    x: mist.x + sin(mist.phase) * 20,
                    y: mist.y
                )
                .blur(radius: 8)
                .blendMode(.screen)
        }
    }
    
    private func grassLayers(geometry: GeometryProxy) -> some View {
        ForEach(0..<3, id: \.self) { layer in
            let grassDensity = 30 - (layer * 8)
            let layerDepth = CGFloat(layer + 1)
            
            ForEach(0..<Int(geometry.size.width / CGFloat(grassDensity)), id: \.self) { index in
                let grassHeight = CGFloat.random(in: 40...80) / layerDepth
                let swayAmount = sin(windPhase + Double(index) * 0.3) * 8 / Double(layerDepth)
                
                EnhancedGrassShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.green.opacity((dimmed ? 0.4 : 0.7) / Double(layerDepth)),
                                Color.black.opacity((dimmed ? 0.8 : 0.6) * Double(layerDepth) / 3.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(
                        width: CGFloat.random(in: 2...5) / layerDepth,
                        height: grassHeight
                    )
                    .position(
                        x: CGFloat(index * grassDensity) + CGFloat.random(in: -5...5) + CGFloat(swayAmount),
                        y: geometry.size.height - grassHeight/2 + CGFloat(layer * 15)
                    )
                    .blur(radius: layerDepth - 1)
                    .shadow(color: .black.opacity(0.3), radius: 1)
            }
        }
    }
}

struct PetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Create a petal shape with curves
        path.move(to: CGPoint(x: width * 0.5, y: height))
        
        path.addQuadCurve(
            to: CGPoint(x: width * 0.8, y: height * 0.3),
            control: CGPoint(x: width * 0.9, y: height * 0.7)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: width * 0.5, y: 0),
            control: CGPoint(x: width * 0.7, y: height * 0.1)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: width * 0.2, y: height * 0.3),
            control: CGPoint(x: width * 0.3, y: height * 0.1)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control: CGPoint(x: width * 0.1, y: height * 0.7)
        )
        
        return path
    }
}

// Legacy grass shape for backward compatibility
struct GrassShape: Shape {
    func path(in rect: CGRect) -> Path {
        return EnhancedGrassShape().path(in: rect)
    }
}

// MARK: - Shooting Stars Animation

class ShootingStarsAnimation: AnimatedBackground {
    let id = "shooting_stars"
    let title = "Cosmic Dreams"
    let category = BackgroundCategory.celestial
    
    func createView(intensity: Float, speed: Float, colorTheme: ColorTheme, dimmed: Bool) -> AnyView {
        AnyView(EnhancedShootingStarsView(intensity: intensity, speed: speed, colorTheme: colorTheme, dimmed: dimmed))
    }
}

struct EnhancedShootingStarsView: View {
    let intensity: Float
    let speed: Float
    let colorTheme: ColorTheme
    let dimmed: Bool
    
    @State private var stars: [StarData] = []
    @State private var shootingStars: [ShootingStarData] = []
    @State private var nebulaClouds: [NebulaData] = []
    @State private var cosmicDust: [DustData] = []
    @State private var galaxySpiral: Double = 0
    @State private var auroraWaves: [AuroraData] = []
    
    private struct StarData: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        var twinklePhase: Double
        var brightness: Double
        let color: Color
        let constellation: Int
        var pulseRate: Double
    }
    
    private struct ShootingStarData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        let endX: CGFloat
        let endY: CGFloat
        var progress: Double
        let trailLength: CGFloat
        let color: Color
        let intensity: Double
        var sparkles: [SparkleData]
    }
    
    private struct SparkleData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var life: Double
        let maxLife: Double
        let size: CGFloat
    }
    
    private struct NebulaData: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        var opacity: Double
        let color: Color
        var phase: Double
        let driftSpeed: CGFloat
    }
    
    private struct DustData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var opacity: Double
        let size: CGFloat
        var velocity: CGVector
    }
    
    private struct AuroraData: Identifiable {
        let id = UUID()
        let baseY: CGFloat
        var wavePhase: Double
        let color: Color
        let intensity: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Deep space background with galaxy
                ZStack {
                    // Deep space gradient
                    RadialGradient(
                        colors: [
                            dimmed ? .black.opacity(0.98) : .black.opacity(0.9),
                            dimmed ? .indigo.opacity(0.2) : .indigo.opacity(0.4),
                            dimmed ? .purple.opacity(0.1) : .purple.opacity(0.3),
                            dimmed ? .blue.opacity(0.05) : .blue.opacity(0.2)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: geometry.size.height * 1.5
                    )
                    
                    // Distant galaxy
                    GalaxyShape(rotation: galaxySpiral)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(dimmed ? 0.02 : 0.08),
                                    Color.purple.opacity(dimmed ? 0.01 : 0.04),
                                    Color.blue.opacity(dimmed ? 0.005 : 0.02),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .position(x: geometry.size.width * 0.7, y: geometry.size.height * 0.3)
                        .blur(radius: 15)
                        .blendMode(.screen)
                }
                
                // Nebula clouds
                ForEach(nebulaClouds) { nebula in
                    NebulaShape(phase: nebula.phase)
                        .fill(
                            RadialGradient(
                                colors: [
                                    nebula.color.opacity(nebula.opacity * (dimmed ? 0.1 : 0.3)),
                                    nebula.color.opacity(nebula.opacity * (dimmed ? 0.05 : 0.15)),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: nebula.size
                            )
                        )
                        .frame(width: nebula.size, height: nebula.size)
                        .position(x: nebula.x, y: nebula.y)
                        .blur(radius: 20)
                        .blendMode(.screen)
                }
                
                // Aurora effects
                ForEach(auroraWaves) { aurora in
                    AuroraShape(baseY: aurora.baseY, wavePhase: aurora.wavePhase)
                        .fill(
                            LinearGradient(
                                colors: [
                                    aurora.color.opacity(aurora.intensity * (dimmed ? 0.1 : 0.3)),
                                    aurora.color.opacity(aurora.intensity * (dimmed ? 0.05 : 0.15)),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: geometry.size.width, height: 150)
                        .blur(radius: 10)
                        .blendMode(.screen)
                }
                
                // Cosmic dust
                ForEach(cosmicDust) { dust in
                    Circle()
                        .fill(
                            Color.white.opacity(dust.opacity * (dimmed ? 0.1 : 0.3))
                        )
                        .frame(width: dust.size, height: dust.size)
                        .position(x: dust.x, y: dust.y)
                        .blur(radius: 1)
                }
                
                // Constellation patterns
                ForEach(0..<3, id: \.self) { constellation in
                    ConstellationShape(constellation: constellation)
                        .stroke(
                            Color.white.opacity(dimmed ? 0.05 : 0.15),
                            lineWidth: 0.5
                        )
                        .opacity(0.6)
                }
                
                // Enhanced static stars with constellations
                ForEach(stars) { star in
                    ZStack {
                        // Main star
                        StarShape()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        star.color.opacity(star.brightness * (dimmed ? 0.4 : 0.9)),
                                        star.color.opacity(star.brightness * (dimmed ? 0.2 : 0.5)),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: star.size * 2
                                )
                            )
                            .frame(width: star.size * 2, height: star.size * 2)
                            .position(x: star.x, y: star.y)
                            .scaleEffect(0.8 + star.brightness * 0.4)
                            .blur(radius: star.size > 2 ? 1 : 0)
                        
                        // Star core
                        Circle()
                            .fill(star.color.opacity(star.brightness))
                            .frame(width: star.size * 0.3, height: star.size * 0.3)
                            .position(x: star.x, y: star.y)
                    }
                }
                
                // Enhanced shooting stars with particle effects
                ForEach(shootingStars) { shootingStar in
                    ZStack {
                        // Shooting star trail with sparkles
                        ForEach(shootingStar.sparkles) { sparkle in
                            Circle()
                                .fill(
                                    shootingStar.color.opacity(
                                        sparkle.life / sparkle.maxLife * (dimmed ? 0.3 : 0.7)
                                    )
                                )
                                .frame(width: sparkle.size, height: sparkle.size)
                                .position(x: sparkle.x, y: sparkle.y)
                                .blur(radius: 1)
                        }
                        
                        // Main shooting star trail
                        EnhancedShootingStarShape(
                            startX: shootingStar.x,
                            startY: shootingStar.y,
                            endX: shootingStar.endX,
                            endY: shootingStar.endY,
                            progress: shootingStar.progress,
                            trailLength: shootingStar.trailLength
                        )
                        .stroke(
                            LinearGradient(
                                colors: [
                                    shootingStar.color.opacity(shootingStar.intensity * (dimmed ? 0.4 : 0.9)),
                                    shootingStar.color.opacity(shootingStar.intensity * (dimmed ? 0.2 : 0.6)),
                                    shootingStar.color.opacity(shootingStar.intensity * (dimmed ? 0.1 : 0.3)),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 3
                        )
                        .blur(radius: 2)
                        .blendMode(.screen)
                    }
                }
            }
        }
        .onAppear {
            setupCelestialObjects()
            startCelestialAnimations()
        }
    }
    
    private func setupCelestialObjects() {
        setupStars()
        setupNebulae()
        setupCosmicDust()
        setupAurora()
    }
    
    private func setupStars() {
        stars = []
        let starCount = Int(intensity * 80) + 30
        let starColors: [Color] = [.white, .blue, .yellow, .orange, .red, .cyan]
        
        for i in 0..<starCount {
            stars.append(StarData(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height * 0.8),
                size: CGFloat.random(in: 1...4),
                twinklePhase: Double.random(in: 0...2 * .pi),
                brightness: Double.random(in: 0.4...1.0),
                color: starColors.randomElement() ?? .white,
                constellation: i % 3,
                pulseRate: Double.random(in: 0.5...2.0)
            ))
        }
    }
    
    private func setupNebulae() {
        nebulaClouds = []
        let nebulaCount = Int(intensity * 5) + 2
        let nebulaColors: [Color] = [.purple, .pink, .cyan, .orange, .red]
        
        for _ in 0..<nebulaCount {
            nebulaClouds.append(NebulaData(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                size: CGFloat.random(in: 150...300),
                opacity: Double.random(in: 0.2...0.6),
                color: nebulaColors.randomElement() ?? .purple,
                phase: Double.random(in: 0...2 * .pi),
                driftSpeed: CGFloat.random(in: 5...15)
            ))
        }
    }
    
    private func setupCosmicDust() {
        cosmicDust = []
        let dustCount = Int(intensity * 100) + 50
        
        for _ in 0..<dustCount {
            cosmicDust.append(DustData(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                opacity: Double.random(in: 0.1...0.4),
                size: CGFloat.random(in: 0.5...2),
                velocity: CGVector(
                    dx: Double.random(in: -5...5),
                    dy: Double.random(in: -2...2)
                )
            ))
        }
    }
    
    private func setupAurora() {
        auroraWaves = []
        let auroraColors: [Color] = [.green, .cyan, .purple, .pink]
        
        for i in 0..<Int(intensity * 3) + 1 {
            auroraWaves.append(AuroraData(
                baseY: CGFloat(i * 50),
                wavePhase: Double(i) * 0.5,
                color: auroraColors.randomElement() ?? .green,
                intensity: Double.random(in: 0.3...0.8)
            ))
        }
    }
    
    private func startCelestialAnimations() {
        // Galaxy rotation
        withAnimation(.linear(duration: 60.0 / Double(speed)).repeatForever(autoreverses: false)) {
            galaxySpiral = 360
        }
        
        // Continuous updates
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            updateStars()
            updateShootingStars()
            updateNebulae()
            updateCosmicDust()
            updateAurora()
        }
        
        // Create shooting stars
        Timer.scheduledTimer(withTimeInterval: 2.0 / Double(speed), repeats: true) { _ in
            createShootingStar()
        }
    }
    
    private func updateStars() {
        for i in 0..<stars.count {
            stars[i].twinklePhase += 0.05 * stars[i].pulseRate * Double(speed)
            stars[i].brightness = 0.4 + 0.6 * (sin(stars[i].twinklePhase) + 1) / 2
        }
    }
    
    private func createShootingStar() {
        let bounds = UIScreen.main.bounds
        let startX = CGFloat.random(in: -150...bounds.width + 150)
        let startY = CGFloat.random(in: -100...bounds.height * 0.6)
        let colors: [Color] = [.white, .cyan, .yellow, .orange, .pink]
        
        var newStar = ShootingStarData(
            x: startX,
            y: startY,
            endX: startX + CGFloat.random(in: 150...400),
            endY: startY + CGFloat.random(in: 100...300),
            progress: 0,
            trailLength: CGFloat.random(in: 50...120),
            color: colors.randomElement() ?? .white,
            intensity: Double.random(in: 0.6...1.0),
            sparkles: []
        )
        
        // Create initial sparkles
        for _ in 0..<10 {
            newStar.sparkles.append(SparkleData(
                x: startX,
                y: startY,
                life: Double.random(in: 0.5...1.0),
                maxLife: 1.0,
                size: CGFloat.random(in: 1...3)
            ))
        }
        
        shootingStars.append(newStar)
    }
    
    private func updateShootingStars() {
        for i in shootingStars.indices.reversed() {
            shootingStars[i].progress += 0.03 * Double(speed)
            
            // Update sparkles
            for j in shootingStars[i].sparkles.indices.reversed() {
                shootingStars[i].sparkles[j].life -= 0.05
                
                let currentX = shootingStars[i].x + (shootingStars[i].endX - shootingStars[i].x) * CGFloat(shootingStars[i].progress)
                let currentY = shootingStars[i].y + (shootingStars[i].endY - shootingStars[i].y) * CGFloat(shootingStars[i].progress)
                
                shootingStars[i].sparkles[j].x = currentX + CGFloat.random(in: -20...20)
                shootingStars[i].sparkles[j].y = currentY + CGFloat.random(in: -20...20)
                
                if shootingStars[i].sparkles[j].life <= 0 {
                    shootingStars[i].sparkles.remove(at: j)
                }
            }
            
            if shootingStars[i].progress >= 1.0 {
                shootingStars.remove(at: i)
            }
        }
    }
    
    private func updateNebulae() {
        for i in 0..<nebulaClouds.count {
            nebulaClouds[i].phase += 0.01
            nebulaClouds[i].opacity = 0.3 + 0.3 * sin(nebulaClouds[i].phase)
        }
    }
    
    private func updateCosmicDust() {
        let bounds = UIScreen.main.bounds
        
        for i in 0..<cosmicDust.count {
            cosmicDust[i].x += cosmicDust[i].velocity.dx * 0.1
            cosmicDust[i].y += cosmicDust[i].velocity.dy * 0.1
            
            // Wrap around screen
            if cosmicDust[i].x < -10 { cosmicDust[i].x = bounds.width + 10 }
            if cosmicDust[i].x > bounds.width + 10 { cosmicDust[i].x = -10 }
            if cosmicDust[i].y < -10 { cosmicDust[i].y = bounds.height + 10 }
            if cosmicDust[i].y > bounds.height + 10 { cosmicDust[i].y = -10 }
        }
    }
    
    private func updateAurora() {
        for i in 0..<auroraWaves.count {
            auroraWaves[i].wavePhase += 0.02 * Double(speed)
        }
    }
}

// MARK: - Enhanced Celestial Shapes

struct EnhancedShootingStarShape: Shape {
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let progress: Double
    let trailLength: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let currentX = startX + (endX - startX) * CGFloat(progress)
        let currentY = startY + (endY - startY) * CGFloat(progress)
        
        let trailStartProgress = max(0, progress - 0.4)
        let trailStartX = startX + (endX - startX) * CGFloat(trailStartProgress)
        let trailStartY = startY + (endY - startY) * CGFloat(trailStartProgress)
        
        // Create curved trail for more organic movement
        path.move(to: CGPoint(x: trailStartX, y: trailStartY))
        
        let midProgress = (progress + trailStartProgress) / 2
        let midX = startX + (endX - startX) * CGFloat(midProgress)
        let midY = startY + (endY - startY) * CGFloat(midProgress)
        
        // Add slight curve to the trail
        let curveOffset = sin(progress * .pi) * 10
        let controlX = midX + CGFloat(curveOffset)
        let controlY = midY + CGFloat(curveOffset * 0.5)
        
        path.addQuadCurve(
            to: CGPoint(x: currentX, y: currentY),
            control: CGPoint(x: controlX, y: controlY)
        )
        
        return path
    }
}

struct GalaxyShape: Shape {
    let rotation: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        // Create spiral arms
        for arm in 0..<3 {
            let armOffset = Double(arm) * 2 * .pi / 3
            
            for i in stride(from: 0, through: 3 * .pi, by: 0.1) {
                let angle = i + armOffset + rotation * .pi / 180
                let spiralRadius = (i / (3 * .pi)) * Double(radius)
                
                let x = center.x + cos(angle) * spiralRadius
                let y = center.y + sin(angle) * spiralRadius
                
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        
        return path
    }
}

struct NebulaShape: Shape {
    let phase: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        // Create organic, cloud-like shape
        for angle in stride(from: 0, through: 2 * Double.pi, by: Double.pi / 20) {
            let noise1 = sin(angle * 3 + phase) * 0.3
            let noise2 = cos(angle * 5 + phase * 0.7) * 0.2
            let radius = min(rect.width, rect.height) / 2 * (0.7 + noise1 + noise2)
            
            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius
            
            if angle == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

struct ConstellationShape: Shape {
    let constellation: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Different constellation patterns
        let patterns: [[(CGFloat, CGFloat)]] = [
            // Big Dipper
            [(0.2, 0.3), (0.3, 0.25), (0.4, 0.2), (0.5, 0.22), (0.6, 0.3), (0.65, 0.4), (0.7, 0.5)],
            // Orion's Belt
            [(0.3, 0.4), (0.5, 0.38), (0.7, 0.36), (0.4, 0.2), (0.6, 0.25), (0.45, 0.6), (0.55, 0.65)],
            // Cassiopeia
            [(0.2, 0.4), (0.35, 0.3), (0.5, 0.45), (0.65, 0.25), (0.8, 0.4)]
        ]
        
        guard constellation < patterns.count else { return path }
        
        let pattern = patterns[constellation]
        for (index, point) in pattern.enumerated() {
            let x = rect.width * point.0
            let y = rect.height * point.1
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
}

struct AuroraShape: Shape {
    let baseY: CGFloat
    let wavePhase: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: 0, y: baseY))
        
        for x in stride(from: 0, through: rect.width, by: 2) {
            let normalizedX = Double(x) / Double(rect.width)
            let wave1 = sin(normalizedX * 4 * .pi + wavePhase) * 30
            let wave2 = cos(normalizedX * 6 * .pi + wavePhase * 1.3) * 20
            let y = baseY + CGFloat(wave1 + wave2)
            
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Close the shape
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

// Legacy shooting star shape for backward compatibility
struct ShootingStarShape: Shape {
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let progress: Double
    let trailLength: CGFloat
    
    func path(in rect: CGRect) -> Path {
        return EnhancedShootingStarShape(
            startX: startX,
            startY: startY,
            endX: endX,
            endY: endY,
            progress: progress,
            trailLength: trailLength
        ).path(in: rect)
    }
}

// MARK: - Geometric Patterns Animation

class GeometricPatternsAnimation: AnimatedBackground {
    let id = "geometric_patterns"
    let title = "Sacred Geometry"
    let category = BackgroundCategory.abstract
    
    func createView(intensity: Float, speed: Float, colorTheme: ColorTheme, dimmed: Bool) -> AnyView {
        AnyView(EnhancedGeometricPatternsView(intensity: intensity, speed: speed, colorTheme: colorTheme, dimmed: dimmed))
    }
}

struct EnhancedGeometricPatternsView: View {
    let intensity: Float
    let speed: Float
    let colorTheme: ColorTheme
    let dimmed: Bool
    
    @State private var rotationAngle: Double = 0
    @State private var scaleEffect: CGFloat = 1.0
    @State private var mandalaRotation: Double = 0
    @State private var particleOffset: CGFloat = 0
    @State private var colorShift: Double = 0
    @State private var energyPulse: Double = 0
    @State private var orbitingSymbols: [OrbitingSymbolData] = []
    @State private var lightBeams: [LightBeamData] = []
    @State private var crystalline: [CrystallineData] = []
    @State private var spiralEnergy: [SpiralEnergyData] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic gradient background with color shifting
                gradientBackground(geometry: geometry)
                
                // Color shifting overlay
                colorShiftingOverlay(geometry: geometry)
                
                // Sacred geometry mandala layers
                ForEach(0..<Int(intensity * 6) + 3, id: \.self) { layer in
                    let layerScale = 1.0 + CGFloat(layer) * 0.15
                    let layerRotation = mandalaRotation + Double(layer * 15)
                    let layerOpacity = (dimmed ? 0.03 : 0.08) / Double(layer + 1)
                    
                    ZStack {
                        // Flower of Life pattern
                        FlowerOfLifeShape()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        getThemeColor().opacity(layerOpacity),
                                        getThemeColor().opacity(layerOpacity * 0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5 + CGFloat(layer) * 0.2
                            )
                            .frame(
                                width: CGFloat(layer * 40 + 80),
                                height: CGFloat(layer * 40 + 80)
                            )
                            .rotationEffect(.degrees(layerRotation))
                            .scaleEffect(layerScale * scaleEffect)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            .blur(radius: CGFloat(layer) * 0.3)
                        
                        // Metatron's Cube elements
                        MetatronsCubeShape()
                            .stroke(
                                getThemeColor().opacity(layerOpacity * 0.7),
                                lineWidth: 0.3
                            )
                            .frame(
                                width: CGFloat(layer * 35 + 60),
                                height: CGFloat(layer * 35 + 60)
                            )
                            .rotationEffect(.degrees(-layerRotation * 0.7))
                            .scaleEffect(layerScale * scaleEffect * 0.8)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    }
                }
                
                // Floating sacred symbols
                floatingSacredSymbols(geometry: geometry)
                
                // Energy particles flowing in geometric patterns
                energyParticles(geometry: geometry)
                
                // Orbiting sacred symbols around the center
                ForEach(orbitingSymbols) { symbol in
                    orbitingSymbolView(symbol: symbol, geometry: geometry)
                }
                
                // Radiating light beams
                ForEach(lightBeams) { beam in
                    lightBeamView(beam: beam, geometry: geometry)
                }
                
                // Crystalline structures
                ForEach(crystalline) { crystal in
                    crystallineView(crystal: crystal)
                }
                
                // Spiral energy flows
                ForEach(spiralEnergy) { spiral in
                    spiralEnergyView(spiral: spiral, geometry: geometry)
                }
                
                // Central mandala with breathing effect
                ZStack {
                    SacredMandalaShape()
                        .stroke(
                            RadialGradient(
                                colors: [
                                    getThemeColor().opacity((dimmed ? 0.1 : 0.3) * Double(intensity)),
                                    getThemeColor().opacity((dimmed ? 0.05 : 0.15) * Double(intensity)),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(mandalaRotation * 0.3))
                        .scaleEffect(scaleEffect + sin(energyPulse) * 0.1)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .shadow(color: getThemeColor().opacity(0.3), radius: 5)
                }
            }
        }
        .onAppear {
            setupEnhancedGeometry()
            startGeometricAnimations()
        }
    }
    
    private func getThemeColor() -> Color {
        switch colorTheme {
        case .warm: return .orange
        case .cool: return .cyan
        case .monochrome: return .white
        default: return .purple
        }
    }
    
    // MARK: - Data Structures for Enhanced Sacred Geometry
    
    private struct OrbitingSymbolData: Identifiable {
        let id = UUID()
        var angle: Double
        let radius: CGFloat
        let speed: Double
        let symbolType: Int
        let size: CGFloat
        var rotation: Double
    }
    
    private struct LightBeamData: Identifiable {
        let id = UUID()
        let startAngle: Double
        let length: CGFloat
        var intensity: Double
        let width: CGFloat
        let color: Color
    }
    
    private struct CrystallineData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        let size: CGFloat
        var rotation: Double
        var pulsePhase: Double
        let facets: Int
        let clarity: Double
    }
    
    private struct SpiralEnergyData: Identifiable {
        let id = UUID()
        var phase: Double
        let radius: CGFloat
        let speed: Double
        let color: Color
        let spiralType: Int
    }
    
    private func startGeometricAnimations() {
        // Main rotation
        withAnimation(
            .linear(duration: 30.0 / Double(speed))
            .repeatForever(autoreverses: false)
        ) {
            rotationAngle = 360
        }
        
        // Mandala rotation (slower)
        withAnimation(
            .linear(duration: 45.0 / Double(speed))
            .repeatForever(autoreverses: false)
        ) {
            mandalaRotation = 360
        }
        
        // Breathing scale effect
        withAnimation(
            .easeInOut(duration: 6.0 / Double(speed))
            .repeatForever(autoreverses: true)
        ) {
            scaleEffect = 1.15
        }
        
        // Particle flow
        withAnimation(
            .linear(duration: 8.0 / Double(speed))
            .repeatForever(autoreverses: false)
        ) {
            particleOffset = 2 * .pi
        }
        
        // Color shifting
        withAnimation(
            .linear(duration: 20.0 / Double(speed))
            .repeatForever(autoreverses: false)
        ) {
            colorShift = 360
        }
        
        // Energy pulse
        withAnimation(
            .easeInOut(duration: 3.0 / Double(speed))
            .repeatForever(autoreverses: true)
        ) {
            energyPulse = 2 * .pi
        }
        
        // Update animations for enhanced elements
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            updateEnhancedGeometry()
        }
    }
    
    private func setupEnhancedGeometry() {
        setupOrbitingSymbols()
        setupLightBeams()
        setupCrystallineStructures()
        setupSpiralEnergy()
    }
    
    private func setupOrbitingSymbols() {
        orbitingSymbols = []
        let symbolCount = Int(intensity * 12) + 8
        
        for i in 0..<symbolCount {
            orbitingSymbols.append(OrbitingSymbolData(
                angle: Double(i) * (360.0 / Double(symbolCount)),
                radius: CGFloat.random(in: 80...200),
                speed: Double.random(in: 0.5...2.0),
                symbolType: i % 6,
                size: CGFloat.random(in: 15...35),
                rotation: 0
            ))
        }
    }
    
    private func setupLightBeams() {
        lightBeams = []
        let beamCount = Int(intensity * 8) + 6
        let colors: [Color] = [getThemeColor(), .white, .cyan, .purple, .orange]
        
        for i in 0..<beamCount {
            lightBeams.append(LightBeamData(
                startAngle: Double(i) * (360.0 / Double(beamCount)),
                length: CGFloat.random(in: 100...250),
                intensity: Double.random(in: 0.3...0.8),
                width: CGFloat.random(in: 1...4),
                color: colors.randomElement() ?? getThemeColor()
            ))
        }
    }
    
    private func setupCrystallineStructures() {
        crystalline = []
        let crystalCount = Int(intensity * 15) + 10
        let bounds = UIScreen.main.bounds
        
        for _ in 0..<crystalCount {
            crystalline.append(CrystallineData(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: 0...bounds.height),
                size: CGFloat.random(in: 8...25),
                rotation: 0,
                pulsePhase: Double.random(in: 0...2 * .pi),
                facets: Int.random(in: 6...12),
                clarity: Double.random(in: 0.3...0.9)
            ))
        }
    }
    
    private func setupSpiralEnergy() {
        spiralEnergy = []
        let spiralCount = Int(intensity * 6) + 4
        let energyColors: [Color] = [getThemeColor(), .white, .cyan, .purple]
        
        for i in 0..<spiralCount {
            spiralEnergy.append(SpiralEnergyData(
                phase: Double(i) * .pi / 2,
                radius: CGFloat.random(in: 50...150),
                speed: Double.random(in: 0.8...2.5),
                color: energyColors.randomElement() ?? getThemeColor(),
                spiralType: i % 3
            ))
        }
    }
    
    private func updateEnhancedGeometry() {
        // Update orbiting symbols
        for i in 0..<orbitingSymbols.count {
            orbitingSymbols[i].angle += orbitingSymbols[i].speed * Double(speed) * 0.5
            orbitingSymbols[i].rotation += orbitingSymbols[i].speed * Double(speed) * 2
        }
        
        // Update light beam intensity
        for i in 0..<lightBeams.count {
            let time = Date().timeIntervalSince1970
            lightBeams[i].intensity = 0.3 + 0.5 * (sin(time * 2 + Double(i) * 0.5) + 1) / 2
        }
        
        // Update crystalline structures
        for i in 0..<crystalline.count {
            crystalline[i].rotation += Double.random(in: 0.5...1.5) * Double(speed)
            crystalline[i].pulsePhase += 0.05 * Double(speed)
        }
        
        // Update spiral energy
        for i in 0..<spiralEnergy.count {
            spiralEnergy[i].phase += spiralEnergy[i].speed * 0.03 * Double(speed)
        }
    }
    
    // MARK: - Enhanced View Functions
    
    private func orbitingSymbolView(symbol: OrbitingSymbolData, geometry: GeometryProxy) -> some View {
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        
        let x = centerX + symbol.radius * cos(symbol.angle * .pi / 180)
        let y = centerY + symbol.radius * sin(symbol.angle * .pi / 180)
        
        let strokeColor = getThemeColor().opacity(dimmed ? 0.3 : 0.6)
        
        switch symbol.symbolType {
        case 0: 
            return AnyView(
                FlowerOfLifeShape()
                    .stroke(strokeColor, lineWidth: 1)
                    .frame(width: symbol.size, height: symbol.size)
                    .rotationEffect(.degrees(symbol.rotation))
                    .position(x: x, y: y)
                    .blur(radius: 0.5)
            )
        case 1: 
            return AnyView(
                TriquetraShape()
                    .stroke(strokeColor, lineWidth: 1)
                    .frame(width: symbol.size, height: symbol.size)
                    .rotationEffect(.degrees(symbol.rotation))
                    .position(x: x, y: y)
                    .blur(radius: 0.5)
            )
        case 2: 
            return AnyView(
                VesicaPiscisShape()
                    .stroke(strokeColor, lineWidth: 1)
                    .frame(width: symbol.size, height: symbol.size)
                    .rotationEffect(.degrees(symbol.rotation))
                    .position(x: x, y: y)
                    .blur(radius: 0.5)
            )
        case 3: 
            return AnyView(
                EnneagramShape()
                    .stroke(strokeColor, lineWidth: 1)
                    .frame(width: symbol.size, height: symbol.size)
                    .rotationEffect(.degrees(symbol.rotation))
                    .position(x: x, y: y)
                    .blur(radius: 0.5)
            )
        case 4: 
            return AnyView(
                SriYantraShape()
                    .stroke(strokeColor, lineWidth: 1)
                    .frame(width: symbol.size, height: symbol.size)
                    .rotationEffect(.degrees(symbol.rotation))
                    .position(x: x, y: y)
                    .blur(radius: 0.5)
            )
        default: 
            return AnyView(
                MetatronsCubeShape()
                    .stroke(strokeColor, lineWidth: 1)
                    .frame(width: symbol.size, height: symbol.size)
                    .rotationEffect(.degrees(symbol.rotation))
                    .position(x: x, y: y)
                    .blur(radius: 0.5)
            )
        }
    }
    
    private func lightBeamView(beam: LightBeamData, geometry: GeometryProxy) -> some View {
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        
        return Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        beam.color.opacity(beam.intensity * (dimmed ? 0.2 : 0.5)),
                        beam.color.opacity(beam.intensity * (dimmed ? 0.1 : 0.3)),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: beam.length, height: beam.width)
            .position(x: centerX, y: centerY)
            .rotationEffect(.degrees(beam.startAngle))
            .blur(radius: 1)
            .blendMode(.screen)
    }
    
    private func crystallineView(crystal: CrystallineData) -> some View {
        let opacity = crystal.clarity * (sin(crystal.pulsePhase) * 0.3 + 0.7)
        
        return RegularPolygonShape(sides: crystal.facets)
            .stroke(
                RadialGradient(
                    colors: [
                        getThemeColor().opacity(opacity * (dimmed ? 0.3 : 0.7)),
                        getThemeColor().opacity(opacity * (dimmed ? 0.1 : 0.4)),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: crystal.size / 2
                ),
                lineWidth: 1
            )
            .frame(width: crystal.size, height: crystal.size)
            .rotationEffect(.degrees(crystal.rotation))
            .position(x: crystal.x, y: crystal.y)
            .scaleEffect(0.8 + sin(crystal.pulsePhase) * 0.2)
            .shadow(color: getThemeColor().opacity(0.3), radius: 2)
    }
    
    private func spiralEnergyView(spiral: SpiralEnergyData, geometry: GeometryProxy) -> some View {
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        
        return SpiralShape(
            phase: spiral.phase,
            radius: spiral.radius,
            spiralType: spiral.spiralType
        )
        .stroke(
            spiral.color.opacity(dimmed ? 0.2 : 0.5),
            lineWidth: 1.5
        )
        .position(x: centerX, y: centerY)
        .blur(radius: 1)
        .blendMode(.screen)
    }
    
    // MARK: - Helper Views
    
    private func gradientBackground(geometry: GeometryProxy) -> some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color.black.opacity(dimmed ? 0.95 : 0.8),
                    Color.purple.opacity(dimmed ? 0.2 : 0.4),
                    Color.blue.opacity(dimmed ? 0.1 : 0.3)
                ],
                center: .center,
                startRadius: 0,
                endRadius: geometry.size.height
            )
        }
    }
    
    private func colorShiftingOverlay(geometry: GeometryProxy) -> some View {
        RadialGradient(
            colors: [
                .clear,
                getThemeColor().opacity((dimmed ? 0.05 : 0.15) * Double(intensity))
            ],
            center: .center,
            startRadius: 100,
            endRadius: 400
        )
        .hueRotation(.degrees(colorShift))
    }
    
    private func floatingSacredSymbols(geometry: GeometryProxy) -> some View {
        let symbolCount = Int(intensity * 12) + 5
        let themeOpacity = (dimmed ? 0.02 : 0.06) * Double(intensity)
        
        return ForEach(0..<symbolCount, id: \.self) { index in
            sacredSymbolView(index: index, geometry: geometry, themeOpacity: themeOpacity)
        }
    }
    
    private func sacredSymbolView(index: Int, geometry: GeometryProxy, themeOpacity: Double) -> some View {
        let symbolType = index % 4
        let symbolSize: CGFloat = 25 // Fixed size to avoid random in ForEach
        let rotationSpeed: Double = 1.0 // Fixed speed to avoid random in ForEach
        
        let strokeColor = getThemeColor().opacity(themeOpacity)
        
        let shapeView: AnyView
        switch symbolType {
        case 0:
            shapeView = AnyView(TriquetraShape().stroke(strokeColor, lineWidth: 1))
        case 1:
            shapeView = AnyView(SriYantraShape().stroke(strokeColor, lineWidth: 1))
        case 2:
            shapeView = AnyView(VesicaPiscisShape().stroke(strokeColor, lineWidth: 1))
        default:
            shapeView = AnyView(EnneagramShape().stroke(strokeColor, lineWidth: 1))
        }
        
        return shapeView
        .frame(width: symbolSize, height: symbolSize)
        .position(
            x: geometry.size.width * CGFloat(Double(index % 5) * 0.2),
            y: geometry.size.height * CGFloat(Double(index % 3) * 0.33)
        )
        .rotationEffect(Angle.degrees(rotationAngle * rotationSpeed + Double(index * 30)))
        .scaleEffect(0.8 + sin(energyPulse + Double(index) * 0.5) * 0.3)
    }
    
    private func energyParticles(geometry: GeometryProxy) -> some View {
        ForEach(0..<Int(intensity * 20) + 8, id: \.self) { index in
            let particleAngle = Double(index) * 2 * .pi / Double(Int(intensity * 20) + 8)
            let radius = 100 + sin(particleOffset + particleAngle * 3) * 50
            let x = geometry.size.width / 2 + cos(particleAngle + particleOffset * 0.5) * radius
            let y = geometry.size.height / 2 + sin(particleAngle + particleOffset * 0.5) * radius
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            getThemeColor().opacity((dimmed ? 0.2 : 0.5) * Double(intensity)),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 3
                    )
                )
                .frame(width: 4, height: 4)
                .position(x: x, y: y)
                .blur(radius: 1)
                .scaleEffect(0.5 + sin(energyPulse * 2 + Double(index) * 0.3) * 0.5)
        }
    }
}

// MARK: - Sacred Geometry Shapes

struct FlowerOfLifeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 6
        
        // Create the traditional Flower of Life pattern
        let positions = [
            CGPoint(x: 0, y: 0), // Center
            CGPoint(x: radius, y: 0),
            CGPoint(x: radius/2, y: radius * sqrt(3)/2),
            CGPoint(x: -radius/2, y: radius * sqrt(3)/2),
            CGPoint(x: -radius, y: 0),
            CGPoint(x: -radius/2, y: -radius * sqrt(3)/2),
            CGPoint(x: radius/2, y: -radius * sqrt(3)/2)
        ]
        
        for position in positions {
            let circleCenter = CGPoint(
                x: center.x + position.x,
                y: center.y + position.y
            )
            path.addEllipse(in: CGRect(
                x: circleCenter.x - radius,
                y: circleCenter.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
        }
        
        return path
    }
}

struct MetatronsCubeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 3
        
        // Create Metatron's Cube pattern
        let vertices: [CGPoint] = (0..<6).map { i in
            let angle = Double(i) * .pi / 3
            return CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
        }
        
        // Connect all vertices to create the cube
        for i in 0..<vertices.count {
            for j in (i+1)..<vertices.count {
                path.move(to: vertices[i])
                path.addLine(to: vertices[j])
            }
        }
        
        // Add center connections
        for vertex in vertices {
            path.move(to: center)
            path.addLine(to: vertex)
        }
        
        return path
    }
}

struct TriquetraShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 3
        
        // Create three interlocking circles
        for i in 0..<3 {
            let angle = Double(i) * 2 * .pi / 3
            let circleCenter = CGPoint(
                x: center.x + cos(angle) * radius * 0.5,
                y: center.y + sin(angle) * radius * 0.5
            )
            
            path.addEllipse(in: CGRect(
                x: circleCenter.x - radius,
                y: circleCenter.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
        }
        
        return path
    }
}

struct SriYantraShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let size = min(rect.width, rect.height) / 2
        
        // Create simplified Sri Yantra triangles
        for i in 0..<4 {
            let scale = 1.0 - Double(i) * 0.2
            let rotation = Double(i) * 15
            
            // Upward triangle
            let triangle1 = createTriangle(center: center, size: size * scale, rotation: rotation)
            path.addPath(triangle1)
            
            // Downward triangle
            let triangle2 = createTriangle(center: center, size: size * scale, rotation: rotation + 180)
            path.addPath(triangle2)
        }
        
        return path
    }
    
    private func createTriangle(center: CGPoint, size: CGFloat, rotation: Double) -> Path {
        var path = Path()
        let radius = size / 2
        
        for i in 0..<3 {
            let angle = Double(i) * 2 * .pi / 3 + rotation * .pi / 180
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.closeSubpath()
        return path
    }
}

struct VesicaPiscisShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 3
        
        // Two overlapping circles
        let offset = radius * 0.6
        
        path.addEllipse(in: CGRect(
            x: center.x - offset - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        
        path.addEllipse(in: CGRect(
            x: center.x + offset - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        
        return path
    }
}

struct EnneagramShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        // Create 9-pointed star
        let points = (0..<9).map { i in
            let angle = Double(i) * 2 * .pi / 9 - .pi / 2
            return CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
        }
        
        // Connect every 4th point
        for i in 0..<9 {
            let start = points[i]
            let end = points[(i + 4) % 9]
            path.move(to: start)
            path.addLine(to: end)
        }
        
        return path
    }
}

struct SacredMandalaShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2
        
        // Create concentric patterns
        for ring in 1...5 {
            let radius = maxRadius * CGFloat(ring) / 5
            let points = ring * 8 // More points for outer rings
            
            for i in 0..<points {
                let angle = Double(i) * 2 * .pi / Double(points)
                let point = CGPoint(
                    x: center.x + cos(angle) * radius,
                    y: center.y + sin(angle) * radius
                )
                
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
                
                // Connect to center for inner rings
                if ring <= 2 {
                    path.move(to: center)
                    path.addLine(to: point)
                }
            }
            
            path.closeSubpath()
        }
        
        return path
    }
}

// Legacy geometric shape for backward compatibility
struct GeometricShape: Shape {
    let sides: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        for i in 0..<sides {
            let angle = Double(i) * 2 * .pi / Double(sides) - .pi / 2
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Soft Rain Animation

class SoftRainAnimation: AnimatedBackground {
    let id = "soft_rain"
    let title = "Tranquil Storm"
    let category = BackgroundCategory.nature
    
    func createView(intensity: Float, speed: Float, colorTheme: ColorTheme, dimmed: Bool) -> AnyView {
        AnyView(EnhancedSoftRainView(intensity: intensity, speed: speed, colorTheme: colorTheme, dimmed: dimmed))
    }
}

struct EnhancedSoftRainView: View {
    let intensity: Float
    let speed: Float
    let colorTheme: ColorTheme
    let dimmed: Bool
    
    @State private var raindrops: [RaindropData] = []
    @State private var lightningFlashes: [LightningData] = []
    @State private var cloudLayers: [CloudLayerData] = []
    @State private var splashes: [SplashData] = []
    @State private var windPhase: Double = 0
    @State private var thunderRumble: Double = 0
    @State private var atmosphericPressure: Double = 0
    
    private struct RaindropData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        let length: CGFloat
        let opacity: Double
        let fallSpeed: CGFloat
        let thickness: CGFloat
        let windSway: CGFloat
    }
    
    private struct LightningData: Identifiable {
        let id = UUID()
        let path: [CGPoint]
        var intensity: Double
        var life: Double
        let maxLife: Double
        let branches: [[CGPoint]]
    }
    
    private struct CloudLayerData: Identifiable {
        let id = UUID()
        var x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat
        let opacity: Double
        let driftSpeed: CGFloat
        let darkness: Double
    }
    
    private struct SplashData: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        var rippleRadius: CGFloat
        var life: Double
        let maxLife: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic storm atmosphere
                ZStack {
                    // Base stormy sky
                    RadialGradient(
                        colors: [
                            dimmed ? .black.opacity(0.9) : .gray.opacity(0.6),
                            dimmed ? .gray.opacity(0.4) : .gray.opacity(0.7),
                            dimmed ? .blue.opacity(0.2) : .blue.opacity(0.4),
                            dimmed ? .black.opacity(0.6) : .black.opacity(0.8)
                        ],
                        center: .init(x: 0.3, y: 0.2),
                        startRadius: 0,
                        endRadius: geometry.size.height * 1.5
                    )
                    
                    // Atmospheric pressure effect
                    RadialGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(atmosphericPressure * (dimmed ? 0.02 : 0.08))
                        ],
                        center: .center,
                        startRadius: 100,
                        endRadius: 300
                    )
                    .blendMode(.screen)
                }
                
                // Multi-layered storm clouds
                ForEach(cloudLayers) { cloud in
                    StormCloudShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(cloud.opacity * cloud.darkness * (dimmed ? 0.3 : 0.6)),
                                    Color.black.opacity(cloud.opacity * cloud.darkness * (dimmed ? 0.4 : 0.7))
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: cloud.width, height: cloud.height)
                        .position(x: cloud.x, y: cloud.y)
                        .blur(radius: 8)
                        .shadow(color: .black.opacity(0.3), radius: 10)
                }
                
                // Lightning flashes
                ForEach(lightningFlashes) { lightning in
                    ZStack {
                        // Main lightning bolt
                        LightningBoltShape(points: lightning.path)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(lightning.intensity),
                                        Color.cyan.opacity(lightning.intensity * 0.8),
                                        Color.blue.opacity(lightning.intensity * 0.6)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 3
                            )
                            .blur(radius: 2)
                            .shadow(color: .white.opacity(lightning.intensity), radius: 8)
                        
                        // Lightning branches
                        ForEach(lightning.branches.indices, id: \.self) { branchIndex in
                            if branchIndex < lightning.branches.count {
                                LightningBoltShape(points: lightning.branches[branchIndex])
                                    .stroke(
                                        Color.white.opacity(lightning.intensity * 0.6),
                                        lineWidth: 1.5
                                    )
                                    .blur(radius: 1)
                            }
                        }
                    }
                }
                
                // Enhanced rain with wind effects
                ForEach(raindrops) { drop in
                    EnhancedRaindropShape()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(drop.opacity * (dimmed ? 0.4 : 0.7)),
                                    Color.cyan.opacity(drop.opacity * (dimmed ? 0.2 : 0.4)),
                                    Color.blue.opacity(drop.opacity * (dimmed ? 0.1 : 0.2))
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: drop.thickness
                        )
                        .frame(width: drop.thickness + 1, height: drop.length)
                        .position(
                            x: drop.x + sin(windPhase) * drop.windSway,
                            y: drop.y
                        )
                        .rotationEffect(.degrees(15 + sin(windPhase) * 10))
                        .blur(radius: 0.5)
                }
                
                // Water splashes and ripples
                ForEach(splashes) { splash in
                    ZStack {
                        // Ripple rings
                        ForEach(0..<3, id: \.self) { ring in
                            Circle()
                                .stroke(
                                    Color.white.opacity(
                                        (splash.life / splash.maxLife) * (dimmed ? 0.1 : 0.3) / Double(ring + 1)
                                    ),
                                    lineWidth: 1
                                )
                                .frame(
                                    width: splash.rippleRadius + CGFloat(ring * 15),
                                    height: splash.rippleRadius + CGFloat(ring * 15)
                                )
                                .position(x: splash.x, y: splash.y)
                        }
                        
                        // Central splash
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity((splash.life / splash.maxLife) * (dimmed ? 0.2 : 0.5)),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 5
                                )
                            )
                            .frame(width: 8, height: 8)
                            .position(x: splash.x, y: splash.y)
                    }
                }
                
                // Ground water accumulation
                ForEach(0..<Int(intensity * 15) + 5, id: \.self) { index in
                    let puddleSize = CGFloat.random(in: 20...60)
                    let reflectionIntensity = Double.random(in: 0.1...0.4)
                    
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(reflectionIntensity * (dimmed ? 0.1 : 0.3)),
                                    Color.cyan.opacity(reflectionIntensity * (dimmed ? 0.05 : 0.15)),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: puddleSize
                            )
                        )
                        .frame(
                            width: puddleSize,
                            height: puddleSize * 0.3
                        )
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: geometry.size.height - CGFloat.random(in: 10...40)
                        )
                        .scaleEffect(1.0 + sin(thunderRumble + Double(index) * 0.5) * 0.1)
                        .blur(radius: 2)
                }
                
                // Atmospheric fog effect
                ForEach(0..<Int(intensity * 5) + 2, id: \.self) { _ in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity((dimmed ? 0.01 : 0.03) * Double(intensity)),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(
                            width: CGFloat.random(in: 150...300),
                            height: CGFloat.random(in: 80...150)
                        )
                        .position(
                            x: CGFloat.random(in: -50...geometry.size.width + 50),
                            y: CGFloat.random(in: (geometry.size.height * 0.7)...geometry.size.height)
                        )
                        .blur(radius: 15)
                        .blendMode(.screen)
                }
            }
        }
        .onAppear {
            setupStormScene()
            startStormAnimations()
        }
    }
    
    private func setupStormScene() {
        setupRain()
        setupClouds()
    }
    
    private func setupRain() {
        raindrops = []
        let dropCount = Int(intensity * 150) + 30
        
        for _ in 0..<dropCount {
            raindrops.append(RaindropData(
                x: CGFloat.random(in: -100...UIScreen.main.bounds.width + 100),
                y: CGFloat.random(in: -UIScreen.main.bounds.height...0),
                length: CGFloat.random(in: 10...25),
                opacity: Double.random(in: 0.3...0.9),
                fallSpeed: CGFloat.random(in: 250...500) * CGFloat(speed),
                thickness: CGFloat.random(in: 0.8...2.0),
                windSway: CGFloat.random(in: 5...20)
            ))
        }
    }
    
    private func setupClouds() {
        cloudLayers = []
        let cloudCount = Int(intensity * 8) + 3
        
        for _ in 0..<cloudCount {
            cloudLayers.append(CloudLayerData(
                x: CGFloat.random(in: -200...UIScreen.main.bounds.width + 200),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height * 0.4),
                width: CGFloat.random(in: 200...400),
                height: CGFloat.random(in: 80...150),
                opacity: Double.random(in: 0.4...0.8),
                driftSpeed: CGFloat.random(in: 10...30),
                darkness: Double.random(in: 0.6...1.0)
            ))
        }
    }
    
    private func startStormAnimations() {
        // Wind effect
        withAnimation(
            .easeInOut(duration: 4.0 / Double(speed))
            .repeatForever(autoreverses: true)
        ) {
            windPhase = .pi
        }
        
        // Atmospheric pressure
        withAnimation(
            .easeInOut(duration: 8.0 / Double(speed))
            .repeatForever(autoreverses: true)
        ) {
            atmosphericPressure = 1.0
        }
        
        // Thunder rumble
        withAnimation(
            .easeInOut(duration: 3.0 / Double(speed))
            .repeatForever(autoreverses: true)
        ) {
            thunderRumble = 2 * .pi
        }
        
        // Continuous updates
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateStorm()
        }
        
        // Lightning strikes
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...8) / Double(speed), repeats: true) { _ in
            createLightning()
        }
    }
    
    private func updateStorm() {
        updateRain()
        updateClouds()
        updateLightning()
        updateSplashes()
    }
    
    private func updateRain() {
        let bounds = UIScreen.main.bounds
        
        for i in 0..<raindrops.count {
            raindrops[i].y += raindrops[i].fallSpeed * 0.016
            
            // Create splash when hitting ground
            if raindrops[i].y > bounds.height - 20 && Double.random(in: 0...1) < 0.1 {
                createSplash(at: CGPoint(x: raindrops[i].x, y: bounds.height - 10))
            }
            
            // Reset raindrop
            if raindrops[i].y > bounds.height + 50 {
                raindrops[i].y = -50
                raindrops[i].x = CGFloat.random(in: -100...bounds.width + 100)
            }
        }
    }
    
    private func updateClouds() {
        let bounds = UIScreen.main.bounds
        
        for i in 0..<cloudLayers.count {
            cloudLayers[i].x += cloudLayers[i].driftSpeed * 0.016
            
            if cloudLayers[i].x > bounds.width + 200 {
                cloudLayers[i].x = -200
            }
        }
    }
    
    private func createLightning() {
        let bounds = UIScreen.main.bounds
        var path: [CGPoint] = []
        
        // Create main lightning path
        let startX = CGFloat.random(in: 0...bounds.width)
        let startY: CGFloat = 0
        let endY = bounds.height * CGFloat.random(in: 0.3...0.8)
        
        var currentX = startX
        var currentY = startY
        
        while currentY < endY {
            path.append(CGPoint(x: currentX, y: currentY))
            currentX += CGFloat.random(in: -30...30)
            currentY += CGFloat.random(in: 20...50)
        }
        
        // Create branches
        var branches: [[CGPoint]] = []
        for _ in 0..<Int.random(in: 2...5) {
            if let branchStart = path.randomElement() {
                var branchPath: [CGPoint] = [branchStart]
                var branchX = branchStart.x
                var branchY = branchStart.y
                
                for _ in 0..<Int.random(in: 3...8) {
                    branchX += CGFloat.random(in: -20...20)
                    branchY += CGFloat.random(in: 10...30)
                    branchPath.append(CGPoint(x: branchX, y: branchY))
                }
                
                branches.append(branchPath)
            }
        }
        
        lightningFlashes.append(LightningData(
            path: path,
            intensity: Double.random(in: 0.8...1.0),
            life: 1.0,
            maxLife: 1.0,
            branches: branches
        ))
    }
    
    private func updateLightning() {
        for i in lightningFlashes.indices.reversed() {
            lightningFlashes[i].life -= 0.05
            lightningFlashes[i].intensity = max(0, lightningFlashes[i].life)
            
            if lightningFlashes[i].life <= 0 {
                lightningFlashes.remove(at: i)
            }
        }
    }
    
    private func createSplash(at point: CGPoint) {
        splashes.append(SplashData(
            x: point.x,
            y: point.y,
            rippleRadius: 0,
            life: 1.0,
            maxLife: 1.0
        ))
    }
    
    private func updateSplashes() {
        for i in splashes.indices.reversed() {
            splashes[i].rippleRadius += 2
            splashes[i].life -= 0.03
            
            if splashes[i].life <= 0 {
                splashes.remove(at: i)
            }
        }
    }
}

// MARK: - Enhanced Rain Shapes

struct EnhancedRaindropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Create a more realistic raindrop with slight taper
        let startX = rect.midX
        let endX = rect.midX + rect.width * 0.1 // Slight angle for wind
        
        path.move(to: CGPoint(x: startX, y: rect.minY))
        path.addLine(to: CGPoint(x: endX, y: rect.maxY))
        
        return path
    }
}

struct StormCloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Create billowing storm cloud shape
        let bumps = 8
        for i in 0...bumps {
            let x = rect.width * CGFloat(i) / CGFloat(bumps)
            let baseY = rect.height * 0.7
            let noise = sin(Double(i) * 0.8) * 0.3 + cos(Double(i) * 1.2) * 0.2
            let y = baseY + CGFloat(noise) * rect.height * 0.3
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        // Close the cloud shape
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

struct LightningBoltShape: Shape {
    let points: [CGPoint]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard points.count > 1 else { return path }
        
        path.move(to: points[0])
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        
        return path
    }
}

// Legacy raindrop shape for backward compatibility
struct RaindropShape: Shape {
    func path(in rect: CGRect) -> Path {
        return EnhancedRaindropShape().path(in: rect)
    }
}

// MARK: - Enhanced Sacred Geometry Shapes

struct RegularPolygonShape: Shape {
    let sides: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard sides >= 3 else { return path }
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let angleStep = 2 * Double.pi / Double(sides)
        
        let startAngle = -Double.pi / 2 // Start from top
        let firstPoint = CGPoint(
            x: center.x + radius * cos(startAngle),
            y: center.y + radius * sin(startAngle)
        )
        
        path.move(to: firstPoint)
        
        for i in 1..<sides {
            let angle = startAngle + angleStep * Double(i)
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            path.addLine(to: point)
        }
        
        path.closeSubpath()
        return path
    }
}

struct SpiralShape: Shape {
    let phase: Double
    let radius: CGFloat
    let spiralType: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2
        let scaledRadius = min(radius, maxRadius)
        
        let steps = 100
        let angleStep = 0.1
        
        for step in 0..<steps {
            let t = Double(step) * angleStep
            let currentRadius = scaledRadius * (Double(step) / Double(steps))
            
            let angle = switch spiralType {
            case 0: // Fibonacci spiral
                phase + t * 2
            case 1: // Logarithmic spiral
                phase + t * 1.5
            default: // Archimedean spiral
                phase + t
            }
            
            let x = center.x + CGFloat(currentRadius * cos(angle))
            let y = center.y + CGFloat(currentRadius * sin(angle))
            
            if step == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
}
