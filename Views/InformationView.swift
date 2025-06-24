//
//  InformationView.swift
//  SleepMate
//
//  Created by Claude on Phase 3 Migration
//

import SwiftUI

struct InformationView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @StateObject private var viewModel = ServiceContainer.shared.informationViewModel
    
    @State private var showingFAQ = false
    @State private var selectedFAQItem: FAQItem?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App header
                    appHeaderSection
                    
                    // Features section
                    featuresSection
                    
                    // Support section
                    supportSection
                    
                    // Social links section removed
                    
                    // FAQ section
                    faqSection
                    
                    // Footer
                    footerSection
                }
                .padding()
            }
            .navigationTitle("Information")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            setupViewModel()
        }
        .sheet(item: $selectedFAQItem) { faqItem in
            faqDetailSheet(faqItem)
        }
        .sheet(isPresented: $viewModel.showingShareSheet) {
            ShareSheet(activityItems: viewModel.shareItems)
        }
    }
    
    // MARK: - Subviews
    
    private var appHeaderSection: some View {
        VStack(spacing: 16) {
            // App icon placeholder
            RoundedRectangle(cornerRadius: 20)
                .fill(.blue)
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
            
            VStack(spacing: 8) {
                Text(viewModel.appName)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Better sleep through nature sounds")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text(viewModel.getVersionString())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                PrimaryButton("Rate App") {
                    HapticFeedback.light()
                    viewModel.rateApp()
                }
                
                SecondaryButton("Share") {
                    HapticFeedback.light()
                    viewModel.shareApp()
                }
            }
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Features")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(viewModel.features, id: \.title) { feature in
                    featureCard(feature)
                }
            }
        }
    }
    
    private func featureCard(_ feature: Feature) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: feature.icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
                
                Text(feature.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .frame(height: 120)
    }
    
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Support & Feedback")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                supportButton(
                    title: "Send Feedback",
                    subtitle: "Help us improve Sleepster",
                    icon: "envelope.fill",
                    action: { viewModel.sendFeedback() }
                )
                
                supportButton(
                    title: "Contact Support",
                    subtitle: "Get help with any issues",
                    icon: "questionmark.circle.fill",
                    action: { viewModel.sendSupportEmail() }
                )
                
                supportButton(
                    title: "Visit Website",
                    subtitle: "Learn more about our apps",
                    icon: "globe",
                    action: { viewModel.openWebsite() }
                )
            }
        }
    }
    
    private func supportButton(
        title: String,
        subtitle: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Frequently Asked Questions")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ForEach(viewModel.faqItems.prefix(3)) { faqItem in
                    faqItemButton(faqItem)
                }
                
                if viewModel.faqItems.count > 3 {
                    Button("View All FAQs") {
                        showingFAQ = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingFAQ) {
            allFAQsSheet
        }
    }
    
    private func faqItemButton(_ faqItem: FAQItem) -> some View {
        Button {
            selectedFAQItem = faqItem
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(faqItem.question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(String(faqItem.answer.prefix(80)) + (faqItem.answer.count > 80 ? "..." : ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 16) {
            Divider()
            
            VStack(spacing: 8) {
                Text(viewModel.getFormattedCopyright())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Made with ❤️ for better sleep")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Sheets
    
    private var allFAQsSheet: some View {
        NavigationView {
            List(viewModel.faqItems) { faqItem in
                Button {
                    selectedFAQItem = faqItem
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(faqItem.question)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(faqItem.answer)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("FAQ")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingFAQ = false
                    }
                }
            }
        }
    }
    
    private func faqDetailSheet(_ faqItem: FAQItem) -> some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(faqItem.question)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(faqItem.answer)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer(minLength: 32)
                    
                    VStack(spacing: 12) {
                        Text("Still need help?")
                            .font(.headline)
                        
                        PrimaryButton("Contact Support") {
                            viewModel.sendSupportEmail()
                            selectedFAQItem = nil
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("FAQ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedFAQItem = nil
                    }
                }
            }
        }
        // .presentationDetents([.medium, .large]) // iOS 16+ only
    }
    
    // MARK: - Helper Methods
    
    private func setupViewModel() {
        // In real implementation, this would be handled by dependency injection
        // viewModel = serviceContainer.informationViewModel
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return activityViewController
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview
#Preview {
    InformationView()
        .environmentObject(ServiceContainer())
}