//
//  APIServerServiceProtocol.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import Foundation
import Combine

/// Protocol defining API server operations
protocol APIServerServiceProtocol {
    /// Current server state
    var state: ServerState { get }

    /// Server URL when running
    var serverURL: URL? { get }

    /// Server port
    var port: Int { get set }

    /// Publisher for server state changes
    var statePublisher: AnyPublisher<ServerState, Never> { get }

    /// Starts the API server
    /// - Returns: Publisher emitting success or error
    func start() -> AnyPublisher<Void, Error>

    /// Stops the API server
    /// - Returns: Publisher emitting success or error
    func stop() -> AnyPublisher<Void, Error>

    /// Restarts the API server
    /// - Returns: Publisher emitting success or error
    func restart() -> AnyPublisher<Void, Error>

    /// Gets server configuration
    /// - Returns: Current server configuration
    func getConfiguration() -> ServerConfiguration

    /// Updates server configuration
    /// - Parameter configuration: New configuration
    /// - Returns: Publisher emitting success or error
    func updateConfiguration(_ configuration: ServerConfiguration) -> AnyPublisher<Void, Error>

    /// Gets server statistics
    /// - Returns: Current server statistics
    func getStatistics() -> ServerStatistics
}

// MARK: - Supporting Types

/// Server state enumeration
enum ServerState: Equatable {
    case stopped
    case starting
    case running
    case stopping
    case error(String)

    var isRunning: Bool {
        if case .running = self {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }
}

/// Server configuration
struct ServerConfiguration {
    var port: Int
    var enableAuth: Bool
    var enableCORS: Bool
    var maxConnections: Int
    var logLevel: LogLevel

    enum LogLevel: String, Codable {
        case debug
        case info
        case warning
        case error
    }

    static let `default` = ServerConfiguration(
        port: 8080,
        enableAuth: false,
        enableCORS: true,
        maxConnections: 100,
        logLevel: .info
    )
}

/// Server statistics
struct ServerStatistics {
    let uptime: TimeInterval
    let requestCount: Int
    let activeConnections: Int
    let averageResponseTime: TimeInterval
    let errorCount: Int

    var uptimeFormatted: String {
        let hours = Int(uptime) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        let seconds = Int(uptime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
