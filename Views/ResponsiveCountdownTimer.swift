//
//  ResponsiveCountdownTimer.swift
//  SleepMate
//
//  Created by Claude to fix UI responsiveness issues
//

import SwiftUI

struct ResponsiveCountdownTimer: View {
    let duration: TimeInterval
    let completion: () -> Void
    @State private var progress: Double = 1.0
    @State private var isActive: Bool = false
    
    var body: some View {
        ResponsiveTimerInternal(
            duration: duration,
            progress: progress,
            isActive: isActive,
            completion: completion
        )
        .onAppear {
            startTimer()
        }
        .onChange(of: duration) { newDuration in
            resetTimer(with: newDuration)
        }
    }
    
    func startTimer() {
        guard !isActive else { return }
        isActive = true
        progress = 1.0
        
        withAnimation(.linear(duration: duration)) {
            progress = 0.0
        }
    }
    
    func stopTimer() {
        isActive = false
        progress = 1.0
    }
    
    func resetTimer(with newDuration: TimeInterval) {
        stopTimer()
        // Small delay to ensure animation stops before restarting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            startTimer()
        }
    }
}

private struct ResponsiveTimerInternal: Animatable, View {
    let duration: TimeInterval
    var progress: Double
    let isActive: Bool
    let completion: () -> Void
    
    var animatableData: Double {
        get { progress }
        set { 
            progress = newValue
            // Check for completion
            if progress <= 0.001 && isActive {
                completion()
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        isActive ? Color.blue : Color.gray.opacity(0.3),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                
                // Timer text
                VStack(spacing: 4) {
                    Text(timeText)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .monospacedDigit()
                        .transition(.scale)
                        .id(timeText) // Forces rebuild when text changes
                    
                    if isActive {
                        Text("remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var timeText: String {
        let secondsRemaining = duration * max(0, progress)
        let totalSeconds = Int(round(secondsRemaining))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - View Extension for easy usage
extension View {
    func responsiveCountdownTimer(
        duration: TimeInterval,
        isActive: Bool,
        completion: @escaping () -> Void
    ) -> some View {
        self.overlay(
            Group {
                if isActive {
                    ResponsiveCountdownTimer(
                        duration: duration,
                        completion: completion
                    )
                }
            }
        )
    }
}