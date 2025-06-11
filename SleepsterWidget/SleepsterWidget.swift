//
//  SleepsterWidget.swift
//  SleepMate
//
//  Created by Claude on Phase 5 Migration
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct SleepsterEntry: TimelineEntry {
    let date: Date
    let isPlaying: Bool
    let currentSound: String?
    let sleepSessionActive: Bool
    let lastSleepDuration: TimeInterval?
    let nextBedtime: Date?
}

// MARK: - Widget Provider

struct SleepsterProvider: TimelineProvider {
    func placeholder(in context: Context) -> SleepsterEntry {
        SleepsterEntry(
            date: Date(),
            isPlaying: false,
            currentSound: "Ocean Waves",
            sleepSessionActive: false,
            lastSleepDuration: 8.5 * 3600,
            nextBedtime: Calendar.current.date(byAdding: .hour, value: 2, to: Date())
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SleepsterEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepsterEntry>) -> Void) {
        let currentEntry = createEntry()
        
        // Update every 15 minutes
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdateDate))
        
        completion(timeline)
    }
    
    private func createEntry() -> SleepsterEntry {
        // Get current app state from UserDefaults (shared between app and widget)
        let userDefaults = UserDefaults(suiteName: "group.com.deanware.sleepmate")
        
        let isPlaying = userDefaults?.bool(forKey: "isAudioPlaying") ?? false
        let currentSound = userDefaults?.string(forKey: "currentSound")
        let sleepSessionActive = userDefaults?.bool(forKey: "sleepSessionActive") ?? false
        let lastSleepDuration = userDefaults?.double(forKey: "lastSleepDuration")
        
        // Calculate next bedtime (assuming 10 PM default)
        let calendar = Calendar.current
        var nextBedtime = calendar.dateInterval(of: .day, for: Date())?.end
        nextBedtime = calendar.date(byAdding: .hour, value: -2, to: nextBedtime ?? Date())
        
        return SleepsterEntry(
            date: Date(),
            isPlaying: isPlaying,
            currentSound: currentSound,
            sleepSessionActive: sleepSessionActive,
            lastSleepDuration: lastSleepDuration == 0 ? nil : lastSleepDuration,
            nextBedtime: nextBedtime
        )
    }
}

// MARK: - Widget Views

struct SleepsterSmallWidgetView: View {
    let entry: SleepsterEntry
    
    var body: some View {
        VStack(spacing: 8) {
            // App Icon
            Image(systemName: "moon.stars.fill")
                .font(.title)
                .foregroundStyle(.blue.gradient)
            
            // Status
            if entry.sleepSessionActive {
                Text("Sleep Tracking")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                
                Text("Active")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else if entry.isPlaying {
                Text("Playing")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                if let sound = entry.currentSound {
                    Text(sound)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            } else {
                Text("Sleepster")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("Ready")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct SleepsterMediumWidgetView: View {
    let entry: SleepsterEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Left side - Status
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .foregroundStyle(.blue.gradient)
                    
                    Text("Sleepster")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                if entry.sleepSessionActive {
                    Label("Sleep tracking active", systemImage: "bed.double.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if entry.isPlaying {
                    Label("Audio playing", systemImage: "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    if let sound = entry.currentSound {
                        Text(sound)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Label("Ready for sleep", systemImage: "moon.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Spacer()
            
            // Right side - Quick Actions
            VStack(spacing: 8) {
                // Sleep Now button
                Button(intent: StartSleepIntent()) {
                    VStack(spacing: 4) {
                        Image(systemName: "bed.double")
                            .font(.title2)
                        Text("Sleep")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .frame(width: 60, height: 50)
                    .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                
                // Stop button (if playing)
                if entry.isPlaying || entry.sleepSessionActive {
                    Button(intent: StopAudioIntent()) {
                        VStack(spacing: 4) {
                            Image(systemName: "stop.fill")
                                .font(.title2)
                            Text("Stop")
                                .font(.caption2)
                        }
                        .foregroundColor(.white)
                        .frame(width: 60, height: 50)
                        .background(.red.gradient, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct SleepsterLargeWidgetView: View {
    let entry: SleepsterEntry
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "moon.stars.fill")
                    .font(.title)
                    .foregroundStyle(.blue.gradient)
                
                Text("Sleepster")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if entry.sleepSessionActive {
                    Label("Tracking", systemImage: "record.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            // Sleep Statistics
            if let lastSleep = entry.lastSleepDuration {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last Sleep Session")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        
                        Text(formatDuration(lastSleep))
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text(sleepQuality(for: lastSleep))
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.green.opacity(0.2), in: Capsule())
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            
            // Quick Actions
            HStack(spacing: 12) {
                Button(intent: StartSleepIntent()) {
                    VStack(spacing: 8) {
                        Image(systemName: "bed.double")
                            .font(.title2)
                        Text("Sleep Now")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                
                Button(intent: PlaySoundsIntent()) {
                    VStack(spacing: 8) {
                        Image(systemName: "speaker.wave.2")
                            .font(.title2)
                        Text("Sounds")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(.green.gradient, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                
                if entry.isPlaying || entry.sleepSessionActive {
                    Button(intent: StopAudioIntent()) {
                        VStack(spacing: 8) {
                            Image(systemName: "stop.fill")
                                .font(.title2)
                            Text("Stop")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(.red.gradient, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    private func sleepQuality(for duration: TimeInterval) -> String {
        let hours = duration / 3600
        
        switch hours {
        case 8...:
            return "Excellent"
        case 7..<8:
            return "Good"
        case 6..<7:
            return "Fair"
        default:
            return "Poor"
        }
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
        .description("Quick access to sleep sounds and tracking")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct SleepsterWidgetView: View {
    let entry: SleepsterEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SleepsterSmallWidgetView(entry: entry)
        case .systemMedium:
            SleepsterMediumWidgetView(entry: entry)
        case .systemLarge:
            SleepsterLargeWidgetView(entry: entry)
        default:
            SleepsterSmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct SleepsterWidgetBundle: WidgetBundle {
    var body: some Widget {
        SleepsterWidget()
        SleepStatisticsWidget()
    }
}

// MARK: - Sleep Statistics Widget

struct SleepStatisticsWidget: Widget {
    let kind: String = "SleepStatisticsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepStatisticsProvider()) { entry in
            SleepStatisticsWidgetView(entry: entry)
        }
        .configurationDisplayName("Sleep Statistics")
        .description("View your sleep patterns and insights")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct SleepStatisticsEntry: TimelineEntry {
    let date: Date
    let weeklyAverage: TimeInterval
    let sleepEfficiency: Double
    let consistency: Double
    let trend: SleepTrend
}

enum SleepTrend {
    case improving, stable, declining
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.circle.fill"
        case .stable: return "minus.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .orange
        }
    }
}

struct SleepStatisticsProvider: TimelineProvider {
    func placeholder(in context: Context) -> SleepStatisticsEntry {
        SleepStatisticsEntry(
            date: Date(),
            weeklyAverage: 8 * 3600,
            sleepEfficiency: 85.0,
            consistency: 78.0,
            trend: .improving
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SleepStatisticsEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepStatisticsEntry>) -> Void) {
        let currentEntry = createEntry()
        
        // Update once per hour
        let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdateDate))
        
        completion(timeline)
    }
    
    private func createEntry() -> SleepStatisticsEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.deanware.sleepmate")
        
        let weeklyAverage = userDefaults?.double(forKey: "weeklyAverageSleep") ?? 8 * 3600
        let sleepEfficiency = userDefaults?.double(forKey: "sleepEfficiency") ?? 85.0
        let consistency = userDefaults?.double(forKey: "sleepConsistency") ?? 78.0
        let trendValue = userDefaults?.integer(forKey: "sleepTrend") ?? 0
        
        let trend: SleepTrend
        switch trendValue {
        case 1: trend = .improving
        case -1: trend = .declining
        default: trend = .stable
        }
        
        return SleepStatisticsEntry(
            date: Date(),
            weeklyAverage: weeklyAverage,
            sleepEfficiency: sleepEfficiency,
            consistency: consistency,
            trend: trend
        )
    }
}

struct SleepStatisticsWidgetView: View {
    let entry: SleepStatisticsEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.blue.gradient)
                
                Text("Sleep Statistics")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: entry.trend.icon)
                    .foregroundColor(entry.trend.color)
            }
            
            // Statistics Grid
            if family == .systemLarge {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    StatCard(
                        title: "Weekly Average",
                        value: formatDuration(entry.weeklyAverage),
                        icon: "clock.fill",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Sleep Efficiency",
                        value: "\(Int(entry.sleepEfficiency))%",
                        icon: "gauge.high",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Consistency",
                        value: "\(Int(entry.consistency))%",
                        icon: "calendar",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "Trend",
                        value: entry.trend == .improving ? "↗️" : entry.trend == .declining ? "↘️" : "→",
                        icon: "arrow.triangle.2.circlepath",
                        color: entry.trend.color
                    )
                }
            } else {
                HStack(spacing: 12) {
                    StatCard(
                        title: "Weekly Avg",
                        value: formatDuration(entry.weeklyAverage),
                        icon: "clock.fill",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Efficiency",
                        value: "\(Int(entry.sleepEfficiency))%",
                        icon: "gauge.high",
                        color: .green
                    )
                }
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                
                Spacer()
            }
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    SleepsterWidget()
} timeline: {
    SleepsterEntry(
        date: Date(),
        isPlaying: true,
        currentSound: "Ocean Waves",
        sleepSessionActive: false,
        lastSleepDuration: 8.5 * 3600,
        nextBedtime: Calendar.current.date(byAdding: .hour, value: 2, to: Date())
    )
}