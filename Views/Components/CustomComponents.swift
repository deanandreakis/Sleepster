//
//  CustomComponents.swift
//  SleepMate
//
//  Created by Claude on Phase 3 Migration
//

import SwiftUI

// MARK: - Custom Button Styles
struct SleepsterButtonStyle: ButtonStyle {
    let color: Color
    let isEnabled: Bool
    
    init(color: Color = .blue, isEnabled: Bool = true) {
        self.color = color
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? color : Color.gray.opacity(0.5))
                    .shadow(color: configuration.isPressed ? .clear : color.opacity(0.3), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .disabled(!isEnabled)
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isEnabled: Bool
    
    init(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(title, action: action)
            .buttonStyle(SleepsterButtonStyle(color: .blue, isEnabled: isEnabled))
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    let isEnabled: Bool
    
    init(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(title, action: action)
            .buttonStyle(SleepsterButtonStyle(color: .gray, isEnabled: isEnabled))
    }
}

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color
    
    init(progress: Double, lineWidth: CGFloat = 8, color: Color = .blue) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.color = color
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}

// MARK: - Timer Display
struct TimerDisplayView: View {
    let timeText: String
    let isActive: Bool
    
    var body: some View {
        Text(timeText)
            .font(.system(size: 48, weight: .light, design: .monospaced))
            .foregroundColor(isActive ? .primary : .secondary)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .shadow(radius: isActive ? 8 : 4)
            )
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.easeInOut, value: isActive)
    }
}

// MARK: - Volume Slider
struct VolumeSliderView: View {
    @Binding var volume: Float
    let onVolumeChange: (Float) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "speaker.fill")
                    .foregroundColor(.secondary)
                
                Text("Volume")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(volume * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "speaker.wave.1")
                    .foregroundColor(.secondary)
                
                Slider(value: Binding(
                    get: { volume },
                    set: { newValue in
                        volume = newValue
                        onVolumeChange(newValue)
                    }
                ), in: 0...1)
                .accentColor(.blue)
                
                Image(systemName: "speaker.wave.3")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Loading View
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(32)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(actionTitle, action: action)
                    .padding(.top)
            }
        }
        .padding(32)
    }
}

// MARK: - Card View
struct CardView<Content: View>: View {
    let content: Content
    let padding: CGFloat
    
    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Haptic Feedback
struct HapticFeedback {
    @MainActor
    static func light() {
        guard ServiceContainer.shared.settingsManager.isHapticsEnabled else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    @MainActor
    static func medium() {
        guard ServiceContainer.shared.settingsManager.isHapticsEnabled else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    @MainActor
    static func heavy() {
        guard ServiceContainer.shared.settingsManager.isHapticsEnabled else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    @MainActor
    static func success() {
        guard ServiceContainer.shared.settingsManager.isHapticsEnabled else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    @MainActor
    static func error() {
        guard ServiceContainer.shared.settingsManager.isHapticsEnabled else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
}