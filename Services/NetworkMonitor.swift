//
//  NetworkMonitor.swift
//  SleepMate
//
//  Created by Claude on Phase 4 Migration
//

import Network
import Foundation
import Combine

/// Monitors network connectivity and provides real-time updates
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = false
    @Published var connectionType: ConnectionType = .unknown
    
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
        
        var description: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .ethernet: return "Ethernet"
            case .unknown: return "Unknown"
            }
        }
    }
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        Task { @MainActor in
            stopMonitoring()
        }
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateConnectionStatus(path)
            }
        }
        monitor.start(queue: monitorQueue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
    
    private func updateConnectionStatus(_ path: NWPath) {
        isConnected = path.status == .satisfied
        
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
        
        #if DEBUG
        print("Network Status: \(isConnected ? "Connected" : "Disconnected") via \(connectionType.description)")
        #endif
    }
    
    /// Check if network is available for expensive operations
    var isExpensiveConnectionAllowed: Bool {
        return !monitor.currentPath.isExpensive || connectionType == .wifi
    }
    
    /// Check if connection is constrained (low data mode)
    var isConstrained: Bool {
        return monitor.currentPath.isConstrained
    }
}