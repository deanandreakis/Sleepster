//
//  ErrorHandler.swift
//  SleepMate
//
//  Created by Claude on Phase 4 Migration
//

import Foundation
import SwiftUI
import os.log

/// Centralized error handling and logging system
@MainActor
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var isShowingError = false
    
    private let logger = Logger(subsystem: "com.deanware.sleepmate", category: "ErrorHandler")
    
    private init() {}
    
    // MARK: - Public Interface
    
    /// Handle an error with optional user presentation
    func handle(_ error: Error, shouldPresent: Bool = false, context: String = "") {
        let appError = mapToAppError(error, context: context)
        
        // Log the error
        logError(appError)
        
        // Present to user if requested
        if shouldPresent {
            presentError(appError)
        }
    }
    
    /// Present error to user
    func presentError(_ error: AppError) {
        currentError = error
        isShowingError = true
    }
    
    /// Clear current error
    func clearError() {
        currentError = nil
        isShowingError = false
    }
    
    // MARK: - Error Mapping
    
    private func mapToAppError(_ error: Error, context: String) -> AppError {
        switch error {
        case is DecodingError:
            return AppError(
                type: .dataCorruption,
                title: "Data Error",
                message: "Failed to process server response",
                recoveryAction: "Please try again later",
                context: context,
                underlyingError: error
            )
            
        case let urlError as URLError:
            return AppError(
                type: .network,
                title: "Connection Error",
                message: urlError.localizedDescription,
                recoveryAction: "Check your internet connection and try again",
                context: context,
                underlyingError: error
            )
            
        default:
            return AppError(
                type: .unknown,
                title: "Unexpected Error",
                message: error.localizedDescription,
                recoveryAction: "Please try again",
                context: context,
                underlyingError: error
            )
        }
    }
    
    // MARK: - Logging
    
    private func logError(_ error: AppError) {
        let logMessage = """
        Error occurred:
        Type: \(error.type)
        Title: \(error.title)
        Message: \(error.message)
        Context: \(error.context)
        Underlying: \(error.underlyingError?.localizedDescription ?? "None")
        """
        
        switch error.type {
        case .critical:
            logger.critical("\(logMessage)")
        case .network, .dataCorruption:
            logger.error("\(logMessage)")
        case .userAction, .validation:
            logger.info("\(logMessage)")
        case .unknown:
            logger.fault("\(logMessage)")
        }
        
        // In debug mode, also print to console
        #if DEBUG
        print("🚨 \(logMessage)")
        #endif
    }
}

// MARK: - App Error Model

struct AppError: Error, Identifiable {
    let id = UUID()
    let type: ErrorType
    let title: String
    let message: String
    let recoveryAction: String?
    let context: String
    let underlyingError: Error?
    let timestamp = Date()
    
    enum ErrorType {
        case network
        case dataCorruption
        case userAction
        case validation
        case critical
        case unknown
        
        var icon: String {
            switch self {
            case .network:
                return "wifi.slash"
            case .dataCorruption:
                return "exclamationmark.triangle"
            case .userAction:
                return "info.circle"
            case .validation:
                return "checkmark.circle"
            case .critical:
                return "xmark.circle"
            case .unknown:
                return "questionmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .network:
                return .orange
            case .dataCorruption:
                return .red
            case .userAction:
                return .blue
            case .validation:
                return .yellow
            case .critical:
                return .red
            case .unknown:
                return .gray
            }
        }
    }
}

// MARK: - Error Alert View

struct ErrorAlertView: View {
    @ObservedObject var errorHandler: ErrorHandler
    
    var body: some View {
        EmptyView()
            .alert(
                errorHandler.currentError?.title ?? "Error",
                isPresented: $errorHandler.isShowingError,
                presenting: errorHandler.currentError
            ) { error in
                if let recoveryAction = error.recoveryAction {
                    Button("OK") {
                        errorHandler.clearError()
                    }
                    Button(recoveryAction) {
                        // Could implement specific recovery actions here
                        errorHandler.clearError()
                    }
                } else {
                    Button("OK") {
                        errorHandler.clearError()
                    }
                }
            } message: { error in
                Text(error.message)
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Add error handling to any view
    func withErrorHandling() -> some View {
        self
            .overlay(
                ErrorAlertView(errorHandler: ErrorHandler.shared)
            )
    }
}