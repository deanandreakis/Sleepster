//
//  ShortcutsSettingsView.swift
//  SleepMate
//
//  Created by Claude on Phase 5 Migration
//

import SwiftUI
import Intents
import IntentsUI

struct ShortcutsSettingsView: View {
    @StateObject private var shortcutsManager = ShortcutsManager.shared
    @State private var showingAddShortcut = false
    @State private var selectedIntent: INIntent?
    @State private var showingIntentPicker = false
    
    var body: some View {
        NavigationView {
            List {
                // Introduction Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "shortcuts")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            Text("Siri & Shortcuts")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("Create voice shortcuts to control Sleepster with Siri or the Shortcuts app. Say things like \"Start sleeping with Sleepster\" or \"Play rain sounds\".")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                // Quick Setup Section
                Section("Quick Setup") {
                    ForEach(quickShortcuts, id: \.title) { shortcut in
                        QuickShortcutRow(shortcut: shortcut)
                    }
                }
                
                // Existing Shortcuts
                if !shortcutsManager.donatedShortcuts.isEmpty {
                    Section("Your Shortcuts") {
                        ForEach(shortcutsManager.donatedShortcuts, id: \.identifier) { voiceShortcut in
                            ExistingShortcutRow(voiceShortcut: voiceShortcut)
                        }
                        .onDelete(perform: deleteShortcuts)
                    }
                }
                
                // Advanced Section
                Section("Advanced") {
                    Button(action: {
                        showingIntentPicker = true
                    }) {
                        Label("Add Custom Shortcut", systemImage: "plus.circle")
                    }
                    
                    Button(action: {
                        Task {
                            await shortcutsManager.donateCommonShortcuts()
                        }
                    }) {
                        Label("Re-donate Shortcuts", systemImage: "arrow.clockwise")
                    }
                    
                    Button(action: {
                        Task {
                            await shortcutsManager.clearAllShortcuts()
                        }
                    }) {
                        Label("Clear All Shortcuts", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                // Tips Section
                Section("Tips") {
                    VStack(alignment: .leading, spacing: 8) {
                        tipRow(icon: "mic", text: "Use natural phrases like \"Good night Sleepster\" or \"Start my sleep sounds\"")
                        tipRow(icon: "speaker.wave.2", text: "Create shortcuts for your favorite sound combinations")
                        tipRow(icon: "timer", text: "Set up timer shortcuts for different sleep durations")
                        tipRow(icon: "chart.line.uptrend.xyaxis", text: "Ask Siri \"Check my sleep stats\" to hear your recent sleep data")
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Shortcuts")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if !shortcutsManager.isInitialized {
                    shortcutsManager.setupShortcuts()
                }
            }
            .refreshable {
                await shortcutsManager.loadExistingShortcuts()
            }
        }
        .sheet(isPresented: $showingAddShortcut) {
            if let intent = selectedIntent {
                AddShortcutView(intent: intent)
            }
        }
        .actionSheet(isPresented: $showingIntentPicker) {
            ActionSheet(
                title: Text("Choose Shortcut Type"),
                buttons: [
                    .default(Text("Start Sleep")) {
                        selectedIntent = StartSleepIntent()
                        showingAddShortcut = true
                    },
                    .default(Text("Play Sounds")) {
                        selectedIntent = PlaySoundsIntent()
                        showingAddShortcut = true
                    },
                    .default(Text("Stop Audio")) {
                        selectedIntent = StopAudioIntent()
                        showingAddShortcut = true
                    },
                    .default(Text("Set Timer")) {
                        selectedIntent = SetSleepTimerIntent()
                        showingAddShortcut = true
                    },
                    .default(Text("Check Sleep Stats")) {
                        selectedIntent = CheckSleepStatsIntent()
                        showingAddShortcut = true
                    },
                    .cancel()
                ]
            )
        }
    }
    
    // MARK: - Quick Shortcuts Data
    
    private var quickShortcuts: [QuickShortcut] {
        [
            QuickShortcut(
                title: "Start Sleep Session",
                description: "Begin sleep tracking and play your preferred sounds",
                phrase: "Start sleeping with Sleepster",
                intent: StartSleepIntent(),
                icon: "bed.double"
            ),
            QuickShortcut(
                title: "Play Sleep Sounds",
                description: "Start playing your recent or favorite sounds",
                phrase: "Play sleep sounds",
                intent: PlaySoundsIntent(),
                icon: "speaker.wave.2"
            ),
            QuickShortcut(
                title: "Stop Everything",
                description: "Stop all audio and sleep tracking",
                phrase: "Stop Sleepster",
                intent: StopAudioIntent(),
                icon: "stop.circle"
            ),
            QuickShortcut(
                title: "30-Minute Timer",
                description: "Set a 30-minute sleep timer",
                phrase: "Set sleep timer for 30 minutes",
                intent: {
                    let intent = SetSleepTimerIntent()
                    intent.duration = NSNumber(value: 30)
                    return intent
                }(),
                icon: "timer"
            ),
            QuickShortcut(
                title: "Check Sleep Stats",
                description: "Get your recent sleep statistics",
                phrase: "Check my sleep stats",
                intent: CheckSleepStatsIntent(),
                icon: "chart.bar"
            )
        ]
    }
    
    // MARK: - Helper Methods
    
    private func deleteShortcuts(at offsets: IndexSet) {
        for index in offsets {
            let shortcut = shortcutsManager.donatedShortcuts[index]
            Task {
                await shortcutsManager.deleteShortcut(withIdentifier: shortcut.identifier.uuidString)
            }
        }
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Supporting Views

struct QuickShortcutRow: View {
    let shortcut: QuickShortcut
    @State private var showingAddShortcut = false
    
    var body: some View {
        Button(action: {
            showingAddShortcut = true
        }) {
            HStack {
                Image(systemName: shortcut.icon)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(shortcut.title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text(shortcut.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\"" + shortcut.phrase + "\"")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .italic()
                }
                
                Spacer()
                
                Image(systemName: "plus.circle")
                    .foregroundColor(.blue)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingAddShortcut) {
            AddShortcutView(intent: shortcut.intent)
        }
    }
}

struct ExistingShortcutRow: View {
    let voiceShortcut: INVoiceShortcut
    
    var body: some View {
        HStack {
            Image(systemName: iconForIntent(voiceShortcut.shortcut.intent ?? INIntent()))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(voiceShortcut.shortcut.intent?.suggestedInvocationPhrase ?? "Custom Shortcut")
                    .font(.subheadline)
                
                if !voiceShortcut.invocationPhrase.isEmpty {
                    Text("\"" + voiceShortcut.invocationPhrase + "\"")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .italic()
                }
            }
            
            Spacer()
            
            Text("Added")
                .font(.caption)
                .foregroundColor(.green)
        }
    }
    
    private func iconForIntent(_ intent: INIntent) -> String {
        switch intent {
        case is StartSleepIntent:
            return "bed.double"
        case is PlaySoundsIntent:
            return "speaker.wave.2"
        case is StopAudioIntent:
            return "stop.circle"
        case is SetSleepTimerIntent:
            return "timer"
        case is CheckSleepStatsIntent:
            return "chart.bar"
        default:
            return "shortcuts"
        }
    }
}

struct AddShortcutView: UIViewControllerRepresentable {
    let intent: INIntent
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> INUIAddVoiceShortcutViewController {
        guard let shortcut = INShortcut(intent: intent) else {
            return INUIAddVoiceShortcutViewController(shortcut: INShortcut(intent: INIntent())!)
        }
        let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: INUIAddVoiceShortcutViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }
    
    class Coordinator: NSObject, INUIAddVoiceShortcutViewControllerDelegate {
        let dismiss: DismissAction
        
        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }
        
        func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
            dismiss()
            
            if let error = error {
                print("Failed to add voice shortcut: \(error)")
            } else if let voiceShortcut = voiceShortcut {
                print("Added voice shortcut: \(voiceShortcut.invocationPhrase)")
                
                // Refresh shortcuts list
                Task {
                    await ShortcutsManager.shared.loadExistingShortcuts()
                }
            }
        }
        
        func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
            dismiss()
        }
    }
}

// MARK: - Supporting Types

struct QuickShortcut {
    let title: String
    let description: String
    let phrase: String
    let intent: INIntent
    let icon: String
}

// MARK: - Preview

#Preview {
    ShortcutsSettingsView()
}