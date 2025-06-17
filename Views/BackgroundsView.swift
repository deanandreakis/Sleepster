//
//  BackgroundsView.swift
//  SleepMate
//
//  Created by Claude on Phase 1 Migration - Animated Backgrounds
//

import SwiftUI

struct BackgroundsView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @StateObject private var viewModel: BackgroundsViewModel
    @EnvironmentObject var appState: AppState
    
    @State private var selectedCategory: BackgroundCategory = .classic
    @State private var showingCustomization = false
    @State private var showingFavorites = false
    @State private var animationSettings = AnimationSettings.default
    @State private var selectedAnimationForPreview: AnimatedBackground?
    @State private var showingPreviewModal = false
    
    init() {
        // ViewModel will be injected via environment in real usage
        let container = ServiceContainer()
        self._viewModel = StateObject(wrappedValue: container.backgroundsViewModel)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category tabs
                categoryTabsSection
                
                // Animation grid
                animationGridSection
                
                // Customization panel
                if showingCustomization {
                    customizationPanel
                }
            }
            .navigationTitle(showingFavorites ? "Favorites" : "Animations")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        HapticFeedback.light()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingFavorites.toggle()
                        }
                    } label: {
                        Image(systemName: showingFavorites ? "star.fill" : "star")
                            .foregroundColor(showingFavorites ? .yellow : .accentColor)
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        HapticFeedback.light()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingCustomization.toggle()
                        }
                    } label: {
                        Image(systemName: showingCustomization ? "slider.horizontal.3.fill" : "slider.horizontal.3")
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadAnimations()
            // Sync animation settings with view model
            animationSettings = viewModel.animationSettings
        }
        .onChange(of: animationSettings) { newSettings in
            viewModel.updateSettings(newSettings)
        }
        .sheet(isPresented: $showingPreviewModal) {
            if let animation = selectedAnimationForPreview {
                AnimationPreviewModal(
                    animation: animation,
                    settings: $animationSettings,
                    onSelect: {
                        viewModel.selectAnimation(animation.id)
                        showingPreviewModal = false
                        HapticFeedback.success()
                    },
                    onFavorite: {
                        viewModel.toggleFavorite(animation.id)
                        HapticFeedback.light()
                    }
                )
            }
        }
    }
    
    // MARK: - Category Tabs
    private var categoryTabsSection: some View {
        Group {
            if !showingFavorites {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(BackgroundCategory.allCases, id: \.self) { category in
                            CategoryTab(
                                title: category.displayName,
                                isSelected: selectedCategory == category
                            ) {
                                HapticFeedback.light()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Animation Grid
    private var animationGridSection: some View {
        ScrollView {
            if displayedAnimations.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: showingFavorites ? "star.slash" : "moon.zzz")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text(showingFavorites ? "No Favorites Yet" : "No Animations Found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if showingFavorites {
                        Text("Tap the star on any animation to add it to your favorites")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(displayedAnimations, id: \.id) { animation in
                        EnhancedAnimationCard(
                            animation: animation,
                            isSelected: viewModel.selectedAnimationId == animation.id,
                            isFavorite: viewModel.isFavorite(animation.id),
                            settings: animationSettings,
                            onTap: {
                                HapticFeedback.medium()
                                viewModel.selectAnimation(animation.id)
                            },
                            onLongPress: {
                                HapticFeedback.light()
                                selectedAnimationForPreview = animation
                                showingPreviewModal = true
                            },
                            onFavorite: {
                                HapticFeedback.light()
                                viewModel.toggleFavorite(animation.id)
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Customization Panel
    private var customizationPanel: some View {
        VStack(spacing: 0) {
            Divider()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "paintbrush.pointed")
                        .foregroundColor(.accentColor)
                    Text("Customization")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    
                    // Reset button
                    Button("Reset") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            animationSettings = AnimationSettings.default
                        }
                        HapticFeedback.light()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.accentColor)
                }
                
                // Speed control with enhanced UI
                VStack(spacing: 8) {
                    HStack {
                        Label("Speed", systemImage: "speedometer")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(speedLabel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "tortoise")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        Slider(value: $animationSettings.speed, in: 0.25...2.0, step: 0.25)
                            .tint(.accentColor)
                        
                        Image(systemName: "hare")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Intensity control with enhanced UI
                VStack(spacing: 8) {
                    HStack {
                        Label("Intensity", systemImage: "slider.horizontal.below.rectangle")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(intensityLabel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "circle.dotted")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        Slider(value: $animationSettings.intensity, in: 0.0...1.0, step: 0.25)
                            .tint(.accentColor)
                        
                        Image(systemName: "circle.hexagongrid")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Color theme with enhanced UI
                VStack(spacing: 12) {
                    HStack {
                        Label("Color Theme", systemImage: "paintpalette")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(animationSettings.colorTheme.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    HStack(spacing: 12) {
                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                            EnhancedColorThemeButton(
                                theme: theme,
                                isSelected: animationSettings.colorTheme == theme
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    animationSettings.colorTheme = theme
                                }
                                HapticFeedback.light()
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
    }
    
    private var speedLabel: String {
        switch animationSettings.speed {
        case 0.25: return "Ultra Slow"
        case 0.5: return "Slow"
        case 0.75: return "Relaxed"
        case 1.0: return "Normal"
        case 1.25: return "Lively"
        case 1.5: return "Fast"
        case 1.75: return "Very Fast"
        case 2.0: return "Energetic"
        default: return "\(String(format: "%.1fx", animationSettings.speed))"
        }
    }
    
    // MARK: - Computed Properties
    private var displayedAnimations: [AnimatedBackground] {
        if showingFavorites {
            let favoriteIds = viewModel.favoriteAnimations.compactMap { $0.animationType }
            return AnimationRegistry.shared.animations.filter { favoriteIds.contains($0.id) }
        } else {
            return AnimationRegistry.shared.animationsForCategory(selectedCategory)
        }
    }
    
    private var intensityLabel: String {
        switch animationSettings.intensity {
        case 0.0..<0.33: return "Low"
        case 0.33..<0.67: return "Medium"
        default: return "High"
        }
    }
}

// MARK: - Category Tab
struct CategoryTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.accentColor : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Animation Card
struct EnhancedAnimationCard: View {
    let animation: AnimatedBackground
    let isSelected: Bool
    let isFavorite: Bool
    let settings: AnimationSettings
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onFavorite: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Preview area with live animation
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .frame(height: 140)
                    .foregroundColor(.clear)
                    .overlay(
                        animation.createView(
                            intensity: settings.intensity,
                            speed: settings.speed * 0.5, // Slower for preview
                            colorTheme: settings.colorTheme,
                            dimmed: false
                        )
                        .clipped()
                        .cornerRadius(16)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: isSelected ? 3 : 1)
                    )
                
                // Favorite button overlay
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onFavorite) {
                            Image(systemName: isFavorite ? "star.fill" : "star")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(isFavorite ? .yellow : .white)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 28, height: 28)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    Spacer()
                }
                .padding(12)
                
                // Selection indicator
                if isSelected {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.accentColor)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 32, height: 32)
                                )
                            Spacer()
                        }
                    }
                    .padding(12)
                }
            }
            
            // Title and category
            VStack(spacing: 4) {
                Text(animation.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                
                Text(animation.category.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50) {
            onLongPress()
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
}

// MARK: - Enhanced Color Theme Button
struct EnhancedColorThemeButton: View {
    let theme: ColorTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(themeColor)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), 
                                       lineWidth: isSelected ? 3 : 1)
                        )
                        .shadow(
                            color: isSelected ? Color.accentColor.opacity(0.3) : Color.clear,
                            radius: isSelected ? 4 : 0
                        )
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Text(theme.displayName)
                    .font(isSelected ? .caption2.weight(.semibold) : .caption2.weight(.regular))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var themeColor: Color {
        switch theme {
        case .defaultTheme: return .blue
        case .warm: return .orange
        case .cool: return .cyan
        case .monochrome: return .gray
        }
    }
}

// MARK: - Legacy Color Theme Button (for backward compatibility)
struct ColorThemeButton: View {
    let theme: ColorTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        EnhancedColorThemeButton(theme: theme, isSelected: isSelected, action: action)
    }
}

// MARK: - Animation Preview Modal
struct AnimationPreviewModal: View {
    let animation: AnimatedBackground
    @Binding var settings: AnimationSettings
    let onSelect: () -> Void
    let onFavorite: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Full-screen preview
                ZStack {
                    animation.createView(
                        intensity: settings.intensity,
                        speed: settings.speed,
                        colorTheme: settings.colorTheme,
                        dimmed: false
                    )
                    .ignoresSafeArea()
                    
                    // Overlay controls
                    VStack {
                        Spacer()
                        
                        // Live settings panel
                        VStack(spacing: 16) {
                            // Title
                            Text(animation.title)
                                .font(.title2.weight(.bold))
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                            
                            // Settings controls with live updates
                            VStack(spacing: 12) {
                                // Speed
                                HStack {
                                    Text("Speed")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(String(format: "%.1fx", settings.speed))")
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                Slider(value: $settings.speed, in: 0.25...2.0, step: 0.25)
                                    .tint(.white)
                                
                                // Intensity
                                HStack {
                                    Text("Intensity")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(intensityLabel)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                Slider(value: $settings.intensity, in: 0.0...1.0, step: 0.25)
                                    .tint(.white)
                                
                                // Color themes
                                HStack {
                                    Text("Theme")
                                        .foregroundColor(.white)
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                                            Button {
                                                settings.colorTheme = theme
                                                HapticFeedback.light()
                                            } label: {
                                                Circle()
                                                    .fill(themeColor(for: theme))
                                                    .frame(width: 24, height: 24)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(.white, lineWidth: settings.colorTheme == theme ? 2 : 0)
                                                    )
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        onFavorite()
                    } label: {
                        Image(systemName: "star")
                            .foregroundColor(.white)
                    }
                    
                    Button("Select") {
                        onSelect()
                    }
                    .foregroundColor(.white)
                    .font(.body.weight(.semibold))
                }
            }
        }
    }
    
    private var intensityLabel: String {
        switch settings.intensity {
        case 0.0..<0.33: return "Low"
        case 0.33..<0.67: return "Medium"
        default: return "High"
        }
    }
    
    private func themeColor(for theme: ColorTheme) -> Color {
        switch theme {
        case .defaultTheme: return .blue
        case .warm: return .orange
        case .cool: return .cyan
        case .monochrome: return .gray
        }
    }
}

#Preview {
    BackgroundsView()
        .environmentObject(ServiceContainer())
        .environmentObject(AppState.shared)
}