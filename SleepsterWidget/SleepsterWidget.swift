//
//  SleepsterWidget.swift
//  SleepsterWidget
//
//  Created by Dean Andreakis on 6/11/25.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider for iOS 15.0 compatibility
struct SleepsterProvider: TimelineProvider {
    func placeholder(in context: Context) -> SleepsterEntry {
        SleepsterEntry(
            date: Date(),
            isTimerActive: false,
            remainingTime: 0,
            activeSoundsCount: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SleepsterEntry) -> ()) {
        let entry = SleepsterEntry(
            date: Date(),
            isTimerActive: false,
            remainingTime: 0,
            activeSoundsCount: 2
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepsterEntry>) -> ()) {
        var entries: [SleepsterEntry] = []

        // Generate timeline entries
        let currentDate = Date()
        for minuteOffset in 0..<60 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = SleepsterEntry(
                date: entryDate,
                isTimerActive: minuteOffset < 30, // Simulate timer running for 30 minutes
                remainingTime: TimeInterval(max(0, 30 - minuteOffset) * 60), // Remaining seconds
                activeSoundsCount: 2
            )
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Timeline Entry
struct SleepsterEntry: TimelineEntry {
    let date: Date
    let isTimerActive: Bool
    let remainingTime: TimeInterval // in seconds
    let activeSoundsCount: Int
}

// MARK: - Widget View
struct SleepsterWidgetView: View {
    var entry: SleepsterProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: SleepsterEntry
    
    var body: some View {
        VStack(spacing: 8) {
            // App Icon and Name
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("Sleepster")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
            
            // Timer Status
            if entry.isTimerActive {
                VStack(spacing: 4) {
                    Text("Timer Active")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatTime(entry.remainingTime))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            } else {
                VStack(spacing: 4) {
                    Text("Ready to Sleep")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Image(systemName: "play.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }
            
            // Active Sounds
            if entry.activeSoundsCount > 0 {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("\(entry.activeSoundsCount) sounds")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.1))
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: SleepsterEntry
    
    var body: some View {
        HStack {
            // Left side - Status
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    Text("Sleepster")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                
                if entry.isTimerActive {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep Timer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatTime(entry.remainingTime))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ready for Sleep")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Tap to Start")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            // Right side - Quick Actions
            VStack(spacing: 12) {
                // Simple visual indicator - tapping widget opens main app
                VStack(spacing: 4) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                    Text("Start")
                        .font(.caption2)
                }
                .foregroundColor(.blue)
                
                if entry.activeSoundsCount > 0 {
                    VStack(spacing: 2) {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(.orange)
                        Text("\(entry.activeSoundsCount)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.05))
    }
}

// MARK: - Widget Configuration
struct SleepsterWidget: Widget {
    let kind: String = "SleepsterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepsterProvider()) { entry in
            SleepsterWidgetView(entry: entry)
        }
        .configurationDisplayName("Sleepster")
        .description("Quick access to your sleep timer and sounds")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Utility Functions
private func formatTime(_ timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    let seconds = Int(timeInterval) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

// MARK: - Preview
struct SleepsterWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SleepsterWidgetView(entry: SleepsterEntry(
                date: Date(),
                isTimerActive: true,
                remainingTime: 1800, // 30 minutes
                activeSoundsCount: 2
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            SleepsterWidgetView(entry: SleepsterEntry(
                date: Date(),
                isTimerActive: false,
                remainingTime: 0,
                activeSoundsCount: 0
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
