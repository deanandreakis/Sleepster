//
//  PaywallView.swift
//  SleepMate
//
//  Created by Claude on Phase 5 Migration
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var storeKitManager = StoreKitManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let presentationContext: PresentationContext
    
    enum PresentationContext {
        case backgroundsLocked
        case soundMixingLocked
        case premiumFeatures
        case subscription
        
        var title: String {
            switch self {
            case .backgroundsLocked:
                return "Unlock Beautiful Backgrounds"
            case .soundMixingLocked:
                return "Mix Multiple Sounds"
            case .premiumFeatures:
                return "Go Premium"
            case .subscription:
                return "Sleep Better with Premium"
            }
        }
        
        var subtitle: String {
            switch self {
            case .backgroundsLocked:
                return "Access unlimited background images and Flickr search"
            case .soundMixingLocked:
                return "Create the perfect sleep environment with sound mixing"
            case .premiumFeatures:
                return "Unlock all features for the ultimate sleep experience"
            case .subscription:
                return "Premium features plus sleep tracking and widgets"
            }
        }
        
        var heroImage: String {
            switch self {
            case .backgroundsLocked:
                return "photo.stack"
            case .soundMixingLocked:
                return "speaker.wave.3"
            case .premiumFeatures:
                return "crown.fill"
            case .subscription:
                return "moon.stars.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section
                    heroSection
                    
                    // Features Section
                    featuresSection
                    
                    // Products Section
                    productsSection
                    
                    // Subscription Benefits (if applicable)
                    if presentationContext == .subscription {
                        subscriptionBenefitsSection
                    }
                    
                    // Purchase Actions
                    purchaseActionsSection
                    
                    // Footer
                    footerSection
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Restore") {
                        restorePurchases()
                    }
                    .disabled(isRestoring)
                }
            }
        }
        .task {
            await storeKitManager.loadProducts()
        }
        .alert("Purchase Successful!", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Thank you for your purchase! Premium features are now unlocked.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Hero Image
            Image(systemName: presentationContext.heroImage)
                .font(.system(size: 60))
                .foregroundStyle(.blue.gradient)
                .frame(width: 100, height: 100)
                .background(
                    Circle()
                        .fill(.blue.opacity(0.1))
                        .frame(width: 120, height: 120)
                )
            
            // Title and Subtitle
            VStack(spacing: 8) {
                Text(presentationContext.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(presentationContext.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What You Get")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(featuresForContext, id: \.title) { feature in
                    FeatureCardView(feature: feature)
                }
            }
        }
    }
    
    private var featuresForContext: [Feature] {
        switch presentationContext {
        case .backgroundsLocked:
            return [
                Feature(title: "Unlimited Backgrounds", description: "Access to thousands of beautiful images", icon: "photo.stack"),
                Feature(title: "Flickr Integration", description: "Search and use photos from Flickr", icon: "magnifyingglass"),
                Feature(title: "High Resolution", description: "Crystal clear HD backgrounds", icon: "4k.tv"),
                Feature(title: "Custom Upload", description: "Use your own photos", icon: "square.and.arrow.up")
            ]
        case .soundMixingLocked:
            return [
                Feature(title: "Mix 5 Sounds", description: "Combine multiple nature sounds", icon: "speaker.wave.3"),
                Feature(title: "Individual Volume", description: "Control each sound separately", icon: "slider.horizontal.3"),
                Feature(title: "Sound Presets", description: "Save your favorite combinations", icon: "heart.circle"),
                Feature(title: "Premium Sounds", description: "Access exclusive sound library", icon: "music.note")
            ]
        case .premiumFeatures, .subscription:
            return [
                Feature(title: "All Backgrounds", description: "Unlimited access to all backgrounds", icon: "photo.stack"),
                Feature(title: "Sound Mixing", description: "Mix multiple sounds simultaneously", icon: "speaker.wave.3"),
                Feature(title: "Audio Effects", description: "10-band EQ, reverb, and delay", icon: "waveform"),
                Feature(title: "Sleep Tracking", description: "Monitor your sleep patterns", icon: "bed.double"),
                Feature(title: "Widgets", description: "Quick access from home screen", icon: "rectangle.3.group"),
                Feature(title: "Priority Support", description: "Get help when you need it", icon: "headphones")
            ]
        }
    }
    
    // MARK: - Products Section
    
    private var productsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Plan")
                .font(.headline)
                .foregroundColor(.primary)
            
            if storeKitManager.isLoading {
                ProgressView("Loading products...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(relevantProducts, id: \.id) { product in
                    ProductCardView(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        onSelect: { selectedProduct = product }
                    )
                }
            }
        }
    }
    
    private var relevantProducts: [Product] {
        switch presentationContext {
        case .backgroundsLocked:
            return storeKitManager.products.filter { 
                $0.id == StoreKitManager.ProductType.multipleBackgrounds.rawValue ||
                $0.id == StoreKitManager.ProductType.premiumPack.rawValue
            }
        case .soundMixingLocked:
            return storeKitManager.products.filter { 
                $0.id == StoreKitManager.ProductType.multipleSounds.rawValue ||
                $0.id == StoreKitManager.ProductType.premiumPack.rawValue
            }
        case .premiumFeatures:
            return storeKitManager.products.filter { 
                $0.id == StoreKitManager.ProductType.premiumPack.rawValue ||
                $0.id == StoreKitManager.ProductType.yearlySubscription.rawValue
            }
        case .subscription:
            return storeKitManager.products.filter { 
                $0.id == StoreKitManager.ProductType.yearlySubscription.rawValue
            }
        }
    }
    
    // MARK: - Subscription Benefits
    
    private var subscriptionBenefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Premium Benefits")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(subscriptionManager.subscriptionBenefits, id: \.self) { benefit in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text(benefit)
                        .font(.subheadline)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Purchase Actions
    
    private var purchaseActionsSection: some View {
        VStack(spacing: 16) {
            // Main Purchase Button
            if let selectedProduct = selectedProduct {
                PrimaryButton(
                    isPurchasing ? "Purchasing..." : "Get \(selectedProduct.displayName) - \(selectedProduct.formattedPrice)"
                ) {
                    purchaseProduct(selectedProduct)
                }
                .disabled(isPurchasing)
            } else if let firstProduct = relevantProducts.first {
                PrimaryButton("Select a Plan") {
                    selectedProduct = firstProduct
                }
            }
            
            // Terms and Privacy
            HStack {
                Link("Terms of Service", destination: URL(string: "https://sleepster.app/terms")!)
                Text("•")
                    .foregroundColor(.secondary)
                Link("Privacy Policy", destination: URL(string: "https://sleepster.app/privacy")!)
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("Premium features unlock immediately after purchase")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if presentationContext == .subscription {
                Text("Subscription auto-renews. Cancel anytime in App Store settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Actions
    
    private func purchaseProduct(_ product: Product) {
        Task {
            isPurchasing = true
            
            await storeKitManager.purchase(product)
            
            isPurchasing = false
            
            if let error = storeKitManager.errorMessage {
                errorMessage = error
                showingError = true
            } else if storeKitManager.isPurchased(product.id) {
                showingSuccess = true
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            isRestoring = true
            
            await storeKitManager.restoreCompletedTransactions()
            
            isRestoring = false
            
            if let error = storeKitManager.errorMessage {
                errorMessage = error
                showingError = true
            }
        }
    }
}

// MARK: - Supporting Views

struct FeatureCardView: View {
    let feature: Feature
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: feature.icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(feature.title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(feature.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ProductCardView: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(product.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    if let period = product.subscriptionPeriod {
                        Text(period)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                VStack {
                    Text(product.formattedPrice)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if product.isSubscription {
                        Text("per year")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .blue : .gray.opacity(0.3), lineWidth: 2)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            )
        }
        .buttonStyle(.plain)
    }
}

struct Feature {
    let title: String
    let description: String
    let icon: String
}

// MARK: - Preview

#Preview {
    PaywallView(presentationContext: .premiumFeatures)
}