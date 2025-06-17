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
            // Phase 2: Real animation implementations
            CountingSheepAnimation(),
            GentleWavesAnimation(),
            FireflyMeadowAnimation(),
            ShootingStarsAnimation(),
            GeometricPatternsAnimation(),
            SoftRainAnimation()
        ]
    }
    
    func animation(for id: String) -> AnimatedBackground? {
        return animations.first { $0.id == id }
    }
    
    func animationsForCategory(_ category: BackgroundCategory) -> [AnimatedBackground] {
        return animations.filter { $0.category == category }
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
        default:
            return [Color.blue.opacity(alpha), Color.gray.opacity(alpha)]
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
    let title = "Counting Sheep"
    let category = BackgroundCategory.classic
    
    func createView(intensity: Float, speed: Float, colorTheme: ColorTheme, dimmed: Bool) -> AnyView {
        AnyView(CountingSheepView(intensity: intensity, speed: speed, colorTheme: colorTheme, dimmed: dimmed))
    }
}

struct CountingSheepView: View {
    let intensity: Float
    let speed: Float
    let colorTheme: ColorTheme
    let dimmed: Bool
    
    @State private var sheepPositions: [SheepData] = []
    @State private var animationTimer: Timer?
    
    private struct SheepData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var jumpHeight: CGFloat = 0
        var isJumping: Bool = false
        var jumpPhase: Double = 0
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Night sky background
                LinearGradient(
                    colors: [
                        dimmed ? .black.opacity(0.9) : .black.opacity(0.8),
                        dimmed ? .indigo.opacity(0.3) : .indigo.opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Fence
                Rectangle()
                    .fill(dimmed ? .brown.opacity(0.4) : .brown.opacity(0.6))
                    .frame(width: geometry.size.width, height: 8)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.7)
                
                // Fence posts
                ForEach(0..<Int(geometry.size.width / 60), id: \.self) { index in
                    Rectangle()
                        .fill(dimmed ? .brown.opacity(0.5) : .brown.opacity(0.7))
                        .frame(width: 4, height: 40)
                        .position(x: CGFloat(index * 60 + 30), y: geometry.size.height * 0.7 - 16)
                }
                
                // Sheep
                ForEach(sheepPositions) { sheep in
                    SheepShape()
                        .fill(dimmed ? .white.opacity(0.3) : .white.opacity(0.7))
                        .frame(width: 30, height: 20)
                        .position(x: sheep.x, y: sheep.y - sheep.jumpHeight)
                        .animation(.easeInOut(duration: 0.8 / Double(speed)), value: sheep.jumpHeight)
                }
                
                // Stars in background
                ForEach(0..<Int(intensity * 20), id: \.self) { _ in
                    Circle()
                        .fill(dimmed ? .white.opacity(0.1) : .white.opacity(0.3))
                        .frame(width: 2, height: 2)
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height * 0.5)
                        )
                }
            }
        }
        .onAppear {
            setupSheep()
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func setupSheep() {
        sheepPositions = []
        for i in 0..<Int(intensity * 5) + 1 {
            sheepPositions.append(SheepData(
                x: -50 - CGFloat(i * 100),
                y: UIScreen.main.bounds.height * 0.7
            ))
        }
    }
    
    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 2.0 / Double(speed), repeats: true) { _ in
            animateSheep()
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func animateSheep() {
        for i in 0..<sheepPositions.count {
            if !sheepPositions[i].isJumping {
                sheepPositions[i].isJumping = true
                sheepPositions[i].jumpHeight = 40
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 / Double(speed)) {
                    if i < sheepPositions.count {
                        sheepPositions[i].jumpHeight = 0
                        sheepPositions[i].x += 80
                        sheepPositions[i].isJumping = false
                        
                        // Reset sheep position if off screen
                        if sheepPositions[i].x > UIScreen.main.bounds.width + 50 {
                            sheepPositions[i].x = -50
                        }
                    }
                }
                break // Only animate one sheep at a time
            }
        }
    }
}

struct SheepShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Body (oval)
        path.addEllipse(in: CGRect(x: rect.minX + 5, y: rect.minY + 5, width: rect.width - 10, height: rect.height - 10))
        
        // Head (circle)
        path.addEllipse(in: CGRect(x: rect.maxX - 8, y: rect.minY, width: 8, height: 8))
        
        return path
    }
}

// MARK: - Gentle Waves Animation

class GentleWavesAnimation: AnimatedBackground {
    let id = "gentle_waves"
    let title = "Gentle Waves"
    let category = BackgroundCategory.nature
    
    func createView(intensity: Float, speed: Float, colorTheme: ColorTheme, dimmed: Bool) -> AnyView {
        AnyView(GentleWavesView(intensity: intensity, speed: speed, colorTheme: colorTheme, dimmed: dimmed))
    }
}

struct GentleWavesView: View {
    let intensity: Float
    let speed: Float
    let colorTheme: ColorTheme
    let dimmed: Bool
    
    @State private var waveOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Ocean background
                LinearGradient(
                    colors: [
                        dimmed ? .blue.opacity(0.2) : .blue.opacity(0.4),
                        dimmed ? .teal.opacity(0.3) : .teal.opacity(0.6),
                        dimmed ? .cyan.opacity(0.1) : .cyan.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Multiple wave layers
                ForEach(0..<Int(intensity * 3) + 1, id: \.self) { layer in
                    WaveShape(
                        waveHeight: CGFloat(intensity * 20) + CGFloat(layer * 10),
                        frequency: 1.5 + Double(layer) * 0.5,
                        offset: waveOffset + CGFloat(layer * 50)
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                (dimmed ? .white.opacity(0.05) : .white.opacity(0.1)),
                                (dimmed ? .white.opacity(0.02) : .white.opacity(0.05))
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blendMode(.screen)
                }
                
                // Foam effect
                ForEach(0..<Int(intensity * 10), id: \.self) { _ in
                    Circle()
                        .fill(dimmed ? .white.opacity(0.02) : .white.opacity(0.05))
                        .frame(width: CGFloat.random(in: 3...8), height: CGFloat.random(in: 3...8))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: geometry.size.height * 0.6...geometry.size.height)
                        )
                        .animation(
                            .easeInOut(duration: Double.random(in: 2...4) / Double(speed))
                            .repeatForever(autoreverses: true),
                            value: waveOffset
                        )
                }
            }
        }
        .onAppear {
            withAnimation(
                .linear(duration: 4.0 / Double(speed))
                .repeatForever(autoreverses: false)
            ) {
                waveOffset = 360
            }
        }
    }
}

struct WaveShape: Shape {
    let waveHeight: CGFloat
    let frequency: Double
    let offset: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let midHeight = height * 0.7
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let angle = (Double(x) / Double(width)) * frequency * 2 * .pi + Double(offset) * .pi / 180
            let y = midHeight + sin(angle) * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Firefly Meadow Animation

class FireflyMeadowAnimation: AnimatedBackground {
    let id = "firefly_meadow"
    let title = "Firefly Meadow"
    let category = BackgroundCategory.nature
    
    func createView(intensity: Float, speed: Float, colorTheme: ColorTheme, dimmed: Bool) -> AnyView {
        AnyView(FireflyMeadowView(intensity: intensity, speed: speed, colorTheme: colorTheme, dimmed: dimmed))
    }
}

struct FireflyMeadowView: View {
    let intensity: Float
    let speed: Float
    let colorTheme: ColorTheme
    let dimmed: Bool
    
    @State private var fireflies: [FireflyData] = []
    
    private struct FireflyData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var opacity: Double
        var size: CGFloat
        var velocity: CGVector
        var glowPhase: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Night meadow background
                LinearGradient(
                    colors: [
                        dimmed ? .black.opacity(0.9) : .black.opacity(0.7),
                        dimmed ? .green.opacity(0.1) : .green.opacity(0.3),
                        dimmed ? .green.opacity(0.2) : .green.opacity(0.4)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Grass silhouettes
                ForEach(0..<Int(geometry.size.width / 20), id: \.self) { index in
                    GrassShape()
                        .fill(dimmed ? .black.opacity(0.3) : .black.opacity(0.5))
                        .frame(
                            width: CGFloat.random(in: 3...8),
                            height: CGFloat.random(in: 20...50)
                        )
                        .position(
                            x: CGFloat(index * 20) + CGFloat.random(in: -5...5),
                            y: geometry.size.height - CGFloat.random(in: 10...25)
                        )
                }
                
                // Fireflies
                ForEach(fireflies) { firefly in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    .yellow.opacity(firefly.opacity),
                                    .yellow.opacity(firefly.opacity * 0.5),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: firefly.size
                            )
                        )
                        .frame(width: firefly.size, height: firefly.size)
                        .position(x: firefly.x, y: firefly.y)
                        .animation(
                            .easeInOut(duration: 1.5 / Double(speed))
                            .repeatForever(autoreverses: true),
                            value: firefly.opacity
                        )
                }
            }
        }
        .onAppear {
            setupFireflies(in: UIScreen.main.bounds)
            startFireflyAnimation()
        }
    }
    
    private func setupFireflies(in bounds: CGRect) {
        fireflies = []
        let count = Int(intensity * 15) + 5
        
        for _ in 0..<count {
            fireflies.append(FireflyData(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: bounds.height * 0.2...bounds.height * 0.8),
                opacity: Double.random(in: 0.2...0.8),
                size: CGFloat.random(in: 8...16),
                velocity: CGVector(
                    dx: Double.random(in: -20...20) * Double(speed),
                    dy: Double.random(in: -10...10) * Double(speed)
                ),
                glowPhase: Double.random(in: 0...2 * .pi)
            ))
        }
    }
    
    private func startFireflyAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateFireflies()
        }
    }
    
    private func updateFireflies() {
        let bounds = UIScreen.main.bounds
        
        for i in 0..<fireflies.count {
            // Update position
            fireflies[i].x += fireflies[i].velocity.dx * 0.1
            fireflies[i].y += fireflies[i].velocity.dy * 0.1
            
            // Update glow
            fireflies[i].glowPhase += 0.1 * Double(speed)
            fireflies[i].opacity = 0.3 + 0.5 * (sin(fireflies[i].glowPhase) + 1) / 2
            
            // Wrap around screen
            if fireflies[i].x < -20 { fireflies[i].x = bounds.width + 20 }
            if fireflies[i].x > bounds.width + 20 { fireflies[i].x = -20 }
            if fireflies[i].y < -20 { fireflies[i].y = bounds.height + 20 }
            if fireflies[i].y > bounds.height + 20 { fireflies[i].y = -20 }
            
            // Random direction changes
            if Double.random(in: 0...1) < 0.02 {
                fireflies[i].velocity = CGVector(
                    dx: Double.random(in: -20...20) * Double(speed),
                    dy: Double.random(in: -10...10) * Double(speed)
                )
            }
        }
    }
}

struct GrassShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Simple grass blade
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX + rect.width * 0.2, y: rect.minY),
            control: CGPoint(x: rect.midX + rect.width * 0.1, y: rect.midY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control: CGPoint(x: rect.midX - rect.width * 0.1, y: rect.midY)
        )
        
        return path
    }
}

// MARK: - Shooting Stars Animation

class ShootingStarsAnimation: AnimatedBackground {
    let id = "shooting_stars"
    let title = "Shooting Stars"
    let category = BackgroundCategory.celestial
    
    func createView(intensity: Float, speed: Float, colorTheme: ColorTheme, dimmed: Bool) -> AnyView {
        AnyView(ShootingStarsView(intensity: intensity, speed: speed, colorTheme: colorTheme, dimmed: dimmed))
    }
}

struct ShootingStarsView: View {
    let intensity: Float
    let speed: Float
    let colorTheme: ColorTheme
    let dimmed: Bool
    
    @State private var stars: [StarData] = []
    @State private var shootingStars: [ShootingStarData] = []
    
    private struct StarData: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        var twinklePhase: Double
        var brightness: Double
    }
    
    private struct ShootingStarData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        let endX: CGFloat
        let endY: CGFloat
        var progress: Double
        let trailLength: CGFloat
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Night sky background
                LinearGradient(
                    colors: [
                        dimmed ? .black.opacity(0.95) : .black.opacity(0.85),
                        dimmed ? .purple.opacity(0.1) : .purple.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Static stars
                ForEach(stars) { star in
                    Circle()
                        .fill(
                            Color.white.opacity(
                                dimmed ? star.brightness * 0.3 : star.brightness * 0.7
                            )
                        )
                        .frame(width: star.size, height: star.size)
                        .position(x: star.x, y: star.y)
                        .animation(
                            .easeInOut(duration: Double.random(in: 1...3) / Double(speed))
                            .repeatForever(autoreverses: true),
                            value: star.brightness
                        )
                }
                
                // Shooting stars
                ForEach(shootingStars) { shootingStar in
                    ShootingStarShape(
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
                                .white.opacity(dimmed ? 0.3 : 0.8),
                                .blue.opacity(dimmed ? 0.1 : 0.4),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
                }
            }
        }
        .onAppear {
            setupStars(in: UIScreen.main.bounds)
            startStarAnimation()
        }
    }
    
    private func setupStars(in bounds: CGRect) {
        stars = []
        let starCount = Int(intensity * 50) + 20
        
        for _ in 0..<starCount {
            stars.append(StarData(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: 0...bounds.height * 0.7),
                size: CGFloat.random(in: 1...3),
                twinklePhase: Double.random(in: 0...2 * .pi),
                brightness: Double.random(in: 0.3...1.0)
            ))
        }
        
        startTwinkling()
    }
    
    private func startTwinkling() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            for i in 0..<stars.count {
                stars[i].twinklePhase += 0.1 * Double(speed)
                stars[i].brightness = 0.3 + 0.7 * (sin(stars[i].twinklePhase) + 1) / 2
            }
        }
    }
    
    private func startStarAnimation() {
        Timer.scheduledTimer(withTimeInterval: 3.0 / Double(speed), repeats: true) { _ in
            createShootingStar()
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            updateShootingStars()
        }
    }
    
    private func createShootingStar() {
        let bounds = UIScreen.main.bounds
        let startX = CGFloat.random(in: -100...bounds.width + 100)
        let startY = CGFloat.random(in: -100...bounds.height * 0.5)
        
        shootingStars.append(ShootingStarData(
            x: startX,
            y: startY,
            endX: startX + CGFloat.random(in: 100...300),
            endY: startY + CGFloat.random(in: 50...200),
            progress: 0,
            trailLength: CGFloat.random(in: 30...80)
        ))
    }
    
    private func updateShootingStars() {
        for i in shootingStars.indices.reversed() {
            shootingStars[i].progress += 0.05 * Double(speed)
            
            if shootingStars[i].progress >= 1.0 {
                shootingStars.remove(at: i)
            }
        }
    }
}

struct ShootingStarShape: Shape {
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
        
        let trailStartProgress = max(0, progress - 0.3)
        let trailStartX = startX + (endX - startX) * CGFloat(trailStartProgress)
        let trailStartY = startY + (endY - startY) * CGFloat(trailStartProgress)
        
        path.move(to: CGPoint(x: trailStartX, y: trailStartY))
        path.addLine(to: CGPoint(x: currentX, y: currentY))
        
        return path
    }
}

// MARK: - Geometric Patterns Animation

class GeometricPatternsAnimation: AnimatedBackground {
    let id = "geometric_patterns"
    let title = "Geometric Patterns"
    let category = BackgroundCategory.abstract
    
    func createView(intensity: Float, speed: Float, colorTheme: ColorTheme, dimmed: Bool) -> AnyView {
        AnyView(GeometricPatternsView(intensity: intensity, speed: speed, colorTheme: colorTheme, dimmed: dimmed))
    }
}

struct GeometricPatternsView: View {
    let intensity: Float
    let speed: Float
    let colorTheme: ColorTheme
    let dimmed: Bool
    
    @State private var rotationAngle: Double = 0
    @State private var scaleEffect: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        dimmed ? .black.opacity(0.9) : .black.opacity(0.7),
                        dimmed ? .purple.opacity(0.1) : .purple.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Rotating geometric patterns
                ForEach(0..<Int(intensity * 5) + 1, id: \.self) { layer in
                    GeometricShape(sides: 6)
                        .stroke(
                            Color.white.opacity(dimmed ? 0.05 : 0.15),
                            lineWidth: 1
                        )
                        .frame(
                            width: CGFloat(layer * 50 + 50),
                            height: CGFloat(layer * 50 + 50)
                        )
                        .rotationEffect(.degrees(rotationAngle + Double(layer * 30)))
                        .scaleEffect(scaleEffect + CGFloat(layer) * 0.1)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                
                // Floating triangles
                ForEach(0..<Int(intensity * 8), id: \.self) { index in
                    GeometricShape(sides: 3)
                        .fill(Color.white.opacity(dimmed ? 0.02 : 0.05))
                        .frame(width: 20, height: 20)
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .rotationEffect(.degrees(rotationAngle * 2 + Double(index * 45)))
                }
            }
        }
        .onAppear {
            withAnimation(
                .linear(duration: 20.0 / Double(speed))
                .repeatForever(autoreverses: false)
            ) {
                rotationAngle = 360
            }
            
            withAnimation(
                .easeInOut(duration: 4.0 / Double(speed))
                .repeatForever(autoreverses: true)
            ) {
                scaleEffect = 1.2
            }
        }
    }
}

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
    let title = "Soft Rain"
    let category = BackgroundCategory.nature
    
    func createView(intensity: Float, speed: Float, colorTheme: ColorTheme, dimmed: Bool) -> AnyView {
        AnyView(SoftRainView(intensity: intensity, speed: speed, colorTheme: colorTheme, dimmed: dimmed))
    }
}

struct SoftRainView: View {
    let intensity: Float
    let speed: Float
    let colorTheme: ColorTheme
    let dimmed: Bool
    
    @State private var raindrops: [RaindropData] = []
    
    private struct RaindropData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        let length: CGFloat
        let opacity: Double
        let fallSpeed: CGFloat
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Stormy sky background
                LinearGradient(
                    colors: [
                        dimmed ? .gray.opacity(0.2) : .gray.opacity(0.4),
                        dimmed ? .blue.opacity(0.1) : .blue.opacity(0.3),
                        dimmed ? .black.opacity(0.3) : .black.opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Rain drops
                ForEach(raindrops) { drop in
                    RaindropShape()
                        .stroke(
                            Color.white.opacity(drop.opacity * (dimmed ? 0.3 : 0.6)),
                            lineWidth: 1
                        )
                        .frame(width: 2, height: drop.length)
                        .position(x: drop.x, y: drop.y)
                        .rotationEffect(.degrees(15)) // Slight angle for wind effect
                }
                
                // Ground puddle reflections
                ForEach(0..<Int(intensity * 5), id: \.self) { _ in
                    Ellipse()
                        .fill(Color.white.opacity(dimmed ? 0.01 : 0.03))
                        .frame(
                            width: CGFloat.random(in: 10...30),
                            height: CGFloat.random(in: 3...8)
                        )
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: geometry.size.height - CGFloat.random(in: 10...50)
                        )
                }
            }
        }
        .onAppear {
            setupRain(in: UIScreen.main.bounds)
            startRainAnimation()
        }
    }
    
    private func setupRain(in bounds: CGRect) {
        raindrops = []
        let dropCount = Int(intensity * 100) + 20
        
        for _ in 0..<dropCount {
            raindrops.append(RaindropData(
                x: CGFloat.random(in: -50...bounds.width + 50),
                y: CGFloat.random(in: -bounds.height...0),
                length: CGFloat.random(in: 8...20),
                opacity: Double.random(in: 0.2...0.8),
                fallSpeed: CGFloat.random(in: 200...400) * CGFloat(speed)
            ))
        }
    }
    
    private func startRainAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            updateRain()
        }
    }
    
    private func updateRain() {
        let bounds = UIScreen.main.bounds
        
        for i in 0..<raindrops.count {
            raindrops[i].y += raindrops[i].fallSpeed * 0.02
            
            // Reset raindrop if it falls off screen
            if raindrops[i].y > bounds.height + 50 {
                raindrops[i].y = -50
                raindrops[i].x = CGFloat.random(in: -50...bounds.width + 50)
            }
        }
    }
}

struct RaindropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}