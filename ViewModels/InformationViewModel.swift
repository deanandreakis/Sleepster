//
//  InformationViewModel.swift
//  SleepMate
//
//  Created by Claude on Phase 2 Migration
//

import Foundation
import SwiftUI
import MessageUI

@MainActor
class InformationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var appVersion = "2.5"
    @Published var buildNumber = "115"
    @Published var showingMailComposer = false
    @Published var showingShareSheet = false
    @Published var mailResult: Result<MFMailComposeResult, Error>?
    @Published var shareItems: [Any] = []
    
    // MARK: - App Information
    let appName = "Sleepster"
    let developerName = "Dean Andreakis"
    let copyrightYear = "2024"
    let appStoreURL = "https://apps.apple.com/app/sleepster/id123456789" // Replace with actual URL
    
    // MARK: - Social Links
    let facebookURL = "https://facebook.com/sleepsterapp"
    let twitterURL = "https://twitter.com/sleepsterapp"
    let websiteURL = "https://sleepsterapp.com"
    
    // MARK: - Support Information
    let supportEmail = "support@sleepsterapp.com"
    let feedbackEmail = "feedback@sleepsterapp.com"
    
    // MARK: - Features List
    let features = [
        Feature(title: "Nature Sounds", description: "High-quality nature sounds for peaceful sleep", icon: "speaker.wave.3"),
        Feature(title: "Sleep Timer", description: "Automatic fade-out timer for uninterrupted sleep", icon: "timer"),
        Feature(title: "Background Images", description: "Beautiful nature backgrounds for relaxation", icon: "photo"),
        Feature(title: "Dark Mode", description: "Easy on the eyes in low light conditions", icon: "moon"),
        Feature(title: "3D Touch", description: "Quick sleep shortcut from home screen", icon: "hand.tap"),
        Feature(title: "Premium Sounds", description: "Unlock additional premium nature sounds", icon: "star")
    ]
    
    // MARK: - FAQ Items
    let faqItems = [
        FAQItem(question: "How do I set a sleep timer?", answer: "Tap the timer icon in the main screen to set a duration. The app will automatically fade out the sound when the timer expires."),
        FAQItem(question: "Can I use my own background images?", answer: "Currently, you can choose from our curated collection of nature backgrounds or search for new ones online."),
        FAQItem(question: "Why does the sound stop when I lock my phone?", answer: "Make sure 'Disable Auto-Lock' is enabled in Settings to prevent the phone from sleeping while using the app."),
        FAQItem(question: "How do I restore my purchases?", answer: "Go to Settings and tap 'Restore Purchases' to restore any premium features you've previously purchased."),
        FAQItem(question: "The app uses too much battery. What can I do?", answer: "Try using solid color backgrounds instead of images, and consider using shorter timer durations.")
    ]
    
    // MARK: - Initialization
    init() {
        loadAppInfo()
    }
    
    private func loadAppInfo() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appVersion = version
        }
        
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            buildNumber = build
        }
    }
    
    // MARK: - Actions
    func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
    func openAppStore() {
        openURL(appStoreURL)
    }
    
    func openFacebook() {
        openURL(facebookURL)
    }
    
    func openTwitter() {
        openURL(twitterURL)
    }
    
    func openWebsite() {
        openURL(websiteURL)
    }
    
    func sendEmail(to email: String, subject: String = "") {
        let mailtoString = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        openURL(mailtoString)
    }
    
    func sendSupportEmail() {
        let subject = "Sleepster Support - Version \(appVersion)"
        let deviceInfo = getDeviceInfo()
        let body = "\n\n---\nDevice Info:\n\(deviceInfo)"
        
        if MFMailComposeViewController.canSendMail() {
            showMailComposer(to: supportEmail, subject: subject, body: body)
        } else {
            sendEmail(to: supportEmail, subject: subject)
        }
    }
    
    func sendFeedback() {
        let subject = "Sleepster Feedback - Version \(appVersion)"
        
        if MFMailComposeViewController.canSendMail() {
            showMailComposer(to: feedbackEmail, subject: subject, body: "")
        } else {
            sendEmail(to: feedbackEmail, subject: subject)
        }
    }
    
    private func showMailComposer(to: String, subject: String, body: String) {
        // This would show the MFMailComposeViewController
        // For now, fall back to mailto
        let mailtoString = "mailto:\(to)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        openURL(mailtoString)
    }
    
    func shareApp() {
        let shareText = "Check out Sleepster - the best app for peaceful sleep with nature sounds!"
        let shareURL = URL(string: appStoreURL)!
        
        shareItems = [shareText, shareURL]
        showingShareSheet = true
    }
    
    func rateApp() {
        let rateURL = "\(appStoreURL)?action=write-review"
        openURL(rateURL)
    }
    
    // MARK: - Device Information
    private func getDeviceInfo() -> String {
        let device = UIDevice.current
        let systemVersion = device.systemVersion
        let deviceModel = getDeviceModel()
        let appVersion = self.appVersion
        let buildNumber = self.buildNumber
        
        return """
        App Version: \(appVersion) (\(buildNumber))
        iOS Version: \(systemVersion)
        Device: \(deviceModel)
        """
    }
    
    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)) ?? UnicodeScalar(0))
        }
        return identifier
    }
    
    // MARK: - Helper Methods
    func getFormattedCopyright() -> String {
        return "© \(copyrightYear) \(developerName). All rights reserved."
    }
    
    func getVersionString() -> String {
        return "Version \(appVersion) (\(buildNumber))"
    }
}

// MARK: - Supporting Types

struct Feature {
    let title: String
    let description: String
    let icon: String
}

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}