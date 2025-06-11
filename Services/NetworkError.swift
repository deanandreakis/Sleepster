//
//  NetworkError.swift
//  SleepMate
//
//  Created by Claude on Phase 4 Migration
//

import Foundation

/// Comprehensive error handling for network operations
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case decodingError(Error)
    case httpError(Int)
    case networkUnavailable
    case timeout
    case unauthorized
    case rateLimited
    case serverError(String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .noData:
            return "No data received from server"
        case .invalidResponse:
            return "Invalid response format"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        case .networkUnavailable:
            return "Network is unavailable"
        case .timeout:
            return "Request timed out"
        case .unauthorized:
            return "Unauthorized access"
        case .rateLimited:
            return "Rate limit exceeded"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Please check your internet connection and try again"
        case .timeout:
            return "Please try again later"
        case .rateLimited:
            return "Please wait a moment before trying again"
        case .unauthorized:
            return "Please check your API credentials"
        default:
            return "Please try again later"
        }
    }
}

/// Result type alias for network operations
typealias NetworkResult<T> = Result<T, NetworkError>