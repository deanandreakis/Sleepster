//
//  BrightnessControlView.swift
//  SleepMate
//
//  Created by Claude on Phase 3 Migration
//

import SwiftUI

struct BrightnessControlView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var brightness: Double = UIScreen.main.brightness
    @State private var autoAdjust = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.yellow)
                    
                    Text("Screen Brightness")
                        .font(.title2)
                        
                    Text("Adjust brightness for comfortable sleep")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Brightness control
                brightnessSlider
                
                // Quick presets
                brightnessPresets
                
                // Auto-adjust toggle
                autoAdjustSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("Brightness")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            brightness = UIScreen.main.brightness
        }
        // .presentationDetents([.medium, .large]) // iOS 16+ only
    }
    
    // MARK: - Subviews
    
    private var brightnessSlider: some View {
        VStack(spacing: 16) {
            // Current brightness display
            Text("\(Int(brightness * 100))%")
                .font(.system(size: 36, weight: .light, design: .rounded))
                .foregroundColor(.primary)
            
            // Brightness slider
            HStack(spacing: 16) {
                Image(systemName: "sun.min")
                    .foregroundColor(.secondary)
                    .font(.title3)
                
                Slider(value: $brightness, in: 0.01...1.0) { _ in
                    UIScreen.main.brightness = brightness
                    HapticFeedback.light()
                }
                .tint(.yellow)
                
                Image(systemName: "sun.max")
                    .foregroundColor(.secondary)
                    .font(.title3)
            }
            
            Text("Slide to adjust screen brightness")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var brightnessPresets: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Presets")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                presetButton("Dim", brightness: 0.1, icon: "moon.fill")
                presetButton("Low", brightness: 0.3, icon: "sun.min.fill")
                presetButton("Medium", brightness: 0.6, icon: "sun.max.fill")
                presetButton("Bright", brightness: 1.0, icon: "sun.max.fill")
            }
        }
    }
    
    private func presetButton(_ title: String, brightness: Double, icon: String) -> some View {
        Button {
            HapticFeedback.medium()
            withAnimation(.easeInOut(duration: 0.5)) {
                self.brightness = brightness
                UIScreen.main.brightness = brightness
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(brightness < 0.5 ? .indigo : .yellow)
                
                Text(title)
                    .font(.caption)
                        
                Text("\(Int(brightness * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.primary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var autoAdjustSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Auto-adjust for sleep", isOn: $autoAdjust)
                .onChange(of: autoAdjust) { enabled in
                    HapticFeedback.light()
                    if enabled {
                        enableAutoAdjust()
                    }
                }
            
            if autoAdjust {
                Text("Brightness will automatically dim when sleep mode starts and restore when it ends")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helper Methods
    
    private func enableAutoAdjust() {
        // In a real implementation, this would integrate with the sleep mode
        // to automatically adjust brightness when sleep starts/stops
        withAnimation(.easeInOut(duration: 2.0)) {
            brightness = 0.1
            UIScreen.main.brightness = 0.1
        }
    }
}

// MARK: - Preview
#Preview {
    BrightnessControlView()
}