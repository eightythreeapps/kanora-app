//
//  FileImportServiceProtocol.swift
//  Kanora
//
//  Created by Claude on 07/10/2025.
//

import Foundation
import CoreData
import Combine
import UniformTypeIdentifiers

/// Protocol defining file import operations
protocol FileImportServiceProtocol {
    /// Imports audio files into a library
    /// - Parameters:
    ///   - urls: File URLs to import
    ///   - library: Target library
    ///   - context: Managed object context
    ///   - mode: Import mode (copy or leave in place)
    /// - Returns: Publisher emitting import progress
    func importFiles(
        _ urls: [URL],
        into library: Library,
        in context: NSManagedObjectContext,
        mode: ImportMode
    ) -> AnyPublisher<ImportProgress, Error>

    /// Validates if a URL points to a supported audio file
    /// - Parameter url: File URL to validate
    /// - Returns: True if the file is a supported audio format
    func isValidAudioFile(_ url: URL) -> Bool

    /// Extracts metadata from an audio file
    /// - Parameter url: Audio file URL
    /// - Returns: Extracted metadata
    func extractMetadata(from url: URL) throws -> AudioMetadata

    /// Checks if a file already exists in the library
    /// - Parameters:
    ///   - url: File URL to check
    ///   - library: Library to search
    ///   - context: Managed object context
    /// - Returns: Existing track if found
    func findDuplicate(
        for url: URL,
        in library: Library,
        context: NSManagedObjectContext
    ) throws -> Track?
}

// MARK: - Supporting Types

/// Import mode - how files should be handled
enum ImportMode: String, CaseIterable {
    case copyToLibrary = "copy"
    case leaveInPlace = "inPlace"

    var displayName: String {
        switch self {
        case .copyToLibrary:
            return "Copy files to library"
        case .leaveInPlace:
            return "Leave files in original location"
        }
    }

    var description: String {
        switch self {
        case .copyToLibrary:
            return "Files will be copied to ~/Music/Kanora/music/"
        case .leaveInPlace:
            return "Files will remain in their current location"
        }
    }
}

/// Progress information during file import
struct ImportProgress {
    let filesProcessed: Int
    let totalFiles: Int
    let currentFile: String?
    let percentage: Double
    let status: ImportStatus

    var isComplete: Bool {
        percentage >= 1.0
    }
}

/// Import status
enum ImportStatus {
    case preparing
    case importing
    case extractingMetadata
    case copyingFile
    case complete
    case error(String)
}

/// Extracted audio file metadata
struct AudioMetadata {
    let title: String?
    let artist: String?
    let albumTitle: String?
    let albumArtist: String?
    let trackNumber: Int?
    let discNumber: Int?
    let year: Int?
    let genre: String?
    let duration: TimeInterval
    let format: String?
    let bitrate: Int?
    let sampleRate: Int?
    let fileSize: Int64
}

/// Supported audio file formats
enum AudioFormat: String, CaseIterable {
    case mp3 = "mp3"
    case flac = "flac"
    case m4a = "m4a"
    case wav = "wav"
    case aac = "aac"

    var utType: UTType? {
        switch self {
        case .mp3:
            return UTType.mp3
        case .flac:
            return UTType(filenameExtension: "flac")
        case .m4a:
            return UTType.mpeg4Audio
        case .wav:
            return UTType.wav
        case .aac:
            return UTType(filenameExtension: "aac")
        }
    }

    static var allExtensions: [String] {
        allCases.map { $0.rawValue }
    }
}

/// Import errors
enum ImportError: LocalizedError {
    case invalidFile(String)
    case unsupportedFormat(String)
    case metadataExtractionFailed(String)
    case fileCopyFailed(String)
    case databaseError(String)
    case duplicateFile

    var errorDescription: String? {
        switch self {
        case .invalidFile(let path):
            return "Invalid file: \(path)"
        case .unsupportedFormat(let format):
            return "Unsupported format: \(format)"
        case .metadataExtractionFailed(let file):
            return "Failed to extract metadata from: \(file)"
        case .fileCopyFailed(let reason):
            return "Failed to copy file: \(reason)"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .duplicateFile:
            return "File already exists in library"
        }
    }
}
