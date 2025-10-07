//
//  LibraryServiceProtocol.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import Foundation
import CoreData
import Combine

/// Protocol defining library management operations
protocol LibraryServiceProtocol {
    /// Fetches all libraries for a specific user
    /// - Parameters:
    ///   - user: The user whose libraries to fetch
    ///   - context: The managed object context to use
    /// - Returns: Array of libraries
    func fetchLibraries(
        for user: User,
        in context: NSManagedObjectContext
    ) throws -> [Library]

    /// Creates a new library
    /// - Parameters:
    ///   - name: Library name
    ///   - path: File system path
    ///   - user: Owner user
    ///   - context: The managed object context to use
    /// - Returns: Created library
    func createLibrary(
        name: String,
        path: String,
        user: User,
        in context: NSManagedObjectContext
    ) throws -> Library

    /// Scans a library for audio files
    /// - Parameters:
    ///   - library: The library to scan
    ///   - context: The managed object context to use
    ///   - progressHandler: Closure called with scan progress (0.0 to 1.0)
    /// - Returns: Publisher emitting scan progress events
    func scanLibrary(
        _ library: Library,
        in context: NSManagedObjectContext,
        progressHandler: ((Double) -> Void)?
    ) -> AnyPublisher<ScanProgress, Error>

    /// Deletes a library and all its content
    /// - Parameters:
    ///   - library: The library to delete
    ///   - context: The managed object context to use
    func deleteLibrary(
        _ library: Library,
        in context: NSManagedObjectContext
    ) throws

    /// Updates library metadata
    /// - Parameters:
    ///   - library: The library to update
    ///   - name: New name (optional)
    ///   - path: New path (optional)
    ///   - context: The managed object context to use
    func updateLibrary(
        _ library: Library,
        name: String?,
        path: String?,
        in context: NSManagedObjectContext
    ) throws

    /// Gets statistics for a library
    /// - Parameters:
    ///   - library: The library to analyze
    ///   - context: The managed object context to use
    /// - Returns: Library statistics
    func getLibraryStatistics(
        for library: Library,
        in context: NSManagedObjectContext
    ) -> LibraryStatistics
}

// MARK: - Supporting Types

/// Progress information during library scanning
struct ScanProgress {
    let filesScanned: Int
    let totalFiles: Int
    let currentFile: String?
    let percentage: Double

    var isComplete: Bool {
        percentage >= 1.0
    }
}

/// Statistics about a library
struct LibraryStatistics {
    let artistCount: Int
    let albumCount: Int
    let trackCount: Int
    let totalDuration: TimeInterval
    let totalSize: Int64
    let lastScannedAt: Date?

    var durationFormatted: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}
