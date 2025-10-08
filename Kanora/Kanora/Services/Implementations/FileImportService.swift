//
//  FileImportService.swift
//  Kanora
//
//  Created by Claude on 07/10/2025.
//

import Foundation
import CoreData
import Combine
import AVFoundation
import UniformTypeIdentifiers

/// Service for importing audio files into the library
class FileImportService: FileImportServiceProtocol {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    // MARK: - FileImportServiceProtocol

    func importFiles(
        _ urls: [URL],
        into library: Library,
        in context: NSManagedObjectContext,
        mode: ImportMode
    ) -> AnyPublisher<ImportProgress, Error> {
        print("🎵 FileImportService.importFiles called with \(urls.count) URLs")
        print("📋 Import mode: \(mode.displayName)")
        let subject = PassthroughSubject<ImportProgress, Error>()

        // Perform import in background
        Task {
            print("📦 Starting background import task")
            do {
                try await performImport(urls, into: library, mode: mode, progress: subject)
                print("✅ performImport completed successfully")
            } catch {
                print("❌ performImport failed: \(error.localizedDescription)")
                subject.send(completion: .failure(error))
            }
        }

        return subject.eraseToAnyPublisher()
    }

    func isValidAudioFile(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }

        let ext = url.pathExtension.lowercased()
        return AudioFormat.allExtensions.contains(ext)
    }

    func extractMetadata(from url: URL) throws -> AudioMetadata {
        print("🎼 extractMetadata called for: \(url.lastPathComponent)")
        print("📍 URL path: \(url.path)")
        print("🔓 URL is file URL: \(url.isFileURL)")

        let asset = AVURLAsset(url: url)
        print("✅ Created AVURLAsset")

        // Get duration
        let duration = asset.duration.seconds
        print("⏱️ Duration: \(duration)s")

        // Get file size
        print("📏 Getting file size...")
        let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        print("📦 File size: \(fileSize) bytes")

        // Extract metadata
        var title: String?
        var artist: String?
        var albumTitle: String?
        var albumArtist: String?
        var trackNumber: Int?
        var discNumber: Int?
        var year: Int?
        var genre: String?

        for item in asset.commonMetadata {
            guard let key = item.commonKey?.rawValue else { continue }

            switch key {
            case "title":
                title = item.stringValue
            case "artist":
                artist = item.stringValue
            case "albumName":
                albumTitle = item.stringValue
            case "type":
                genre = item.stringValue
            default:
                break
            }
        }

        // Try ID3 tags for MP3
        if url.pathExtension.lowercased() == "mp3" {
            for format in asset.availableMetadataFormats {
                let metadata = asset.metadata(forFormat: format)

                for item in metadata {
                    if let key = item.commonKey?.rawValue {
                        switch key {
                        case "title":
                            title = title ?? item.stringValue
                        case "artist":
                            artist = artist ?? item.stringValue
                        case "albumName":
                            albumTitle = albumTitle ?? item.stringValue
                        default:
                            break
                        }
                    }
                }
            }
        }

        // Get audio track information
        var format: String?
        var bitrate: Int?
        var sampleRate: Int?

        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            if let descriptions = audioTrack.formatDescriptions as? [CMFormatDescription],
               let description = descriptions.first {
                let audioFormat = CMFormatDescriptionGetMediaSubType(description)
                format = fourCCToString(audioFormat)
            }

            bitrate = Int(audioTrack.estimatedDataRate / 1000) // Convert to kbps
            sampleRate = Int(audioTrack.naturalTimeScale)
        }

        // Fallback to filename if no title
        if title == nil {
            title = url.deletingPathExtension().lastPathComponent
        }

        return AudioMetadata(
            title: title,
            artist: artist,
            albumTitle: albumTitle,
            albumArtist: albumArtist,
            trackNumber: trackNumber,
            discNumber: discNumber,
            year: year,
            genre: genre,
            duration: duration,
            format: format ?? url.pathExtension.uppercased(),
            bitrate: bitrate,
            sampleRate: sampleRate,
            fileSize: Int64(fileSize)
        )
    }

    func findDuplicate(
        for url: URL,
        in library: Library,
        context: NSManagedObjectContext
    ) throws -> Track? {
        let fileName = url.lastPathComponent

        let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "filePath ENDSWITH %@ AND album.artist.library == %@",
            fileName,
            library
        )
        fetchRequest.fetchLimit = 1

        return try context.fetch(fetchRequest).first
    }

    // MARK: - Private Methods

    private func performImport(
        _ urls: [URL],
        into library: Library,
        mode: ImportMode,
        progress: PassthroughSubject<ImportProgress, Error>
    ) async throws {
        print("🔄 performImport started with \(urls.count) files")
        let totalFiles = urls.count
        var processedFiles = 0

        // Send preparing status
        print("📤 Sending preparing status")
        progress.send(ImportProgress(
            filesProcessed: 0,
            totalFiles: totalFiles,
            currentFile: nil,
            percentage: 0.0,
            status: .preparing
        ))

        // Use background context
        print("🗄️ Starting background task")
        await persistence.performBackgroundTask { context in
            print("📝 Inside background context")
            do {
            // Get library in background context
            guard let backgroundLibrary = try? context.existingObject(with: library.objectID) as? Library else {
                print("❌ Library not found in background context")
                throw ImportError.databaseError("Library not found")
            }
            print("✅ Got library in background context: \(backgroundLibrary.name ?? "unknown")")

            for url in urls {
                let fileName = url.lastPathComponent
                print("📂 Processing file: \(fileName)")

                // Send progress
                progress.send(ImportProgress(
                    filesProcessed: processedFiles,
                    totalFiles: totalFiles,
                    currentFile: fileName,
                    percentage: Double(processedFiles) / Double(totalFiles),
                    status: .importing
                ))

                do {
                    // Validate file
                    print("🔍 Validating file: \(fileName)")
                    guard self.isValidAudioFile(url) else {
                        print("❌ Invalid audio file: \(fileName)")
                        throw ImportError.unsupportedFormat(url.pathExtension)
                    }
                    print("✅ File is valid")

                    // Check for duplicates
                    print("🔎 Checking for duplicates")
                    if let _ = try self.findDuplicate(for: url, in: backgroundLibrary, context: context) {
                        print("⏭️ Skipping duplicate: \(fileName)")
                        // Skip duplicate
                        processedFiles += 1
                        continue
                    }

                    // Extract metadata
                    print("🎵 Extracting metadata from \(fileName)")
                    progress.send(ImportProgress(
                        filesProcessed: processedFiles,
                        totalFiles: totalFiles,
                        currentFile: fileName,
                        percentage: Double(processedFiles) / Double(totalFiles),
                        status: .extractingMetadata
                    ))

                    let metadata = try self.extractMetadata(from: url)
                    print("✅ Metadata extracted: \(metadata.title ?? "Unknown")")

                    // Handle file based on import mode
                    let filePath: String
                    if mode == .copyToLibrary {
                        print("📁 Copying file to library")
                        progress.send(ImportProgress(
                            filesProcessed: processedFiles,
                            totalFiles: totalFiles,
                            currentFile: fileName,
                            percentage: Double(processedFiles) / Double(totalFiles),
                            status: .copyingFile
                        ))

                        let destinationURL = try self.copyFileToLibrary(url, library: backgroundLibrary)
                        filePath = destinationURL.path
                        print("✅ File copied to: \(filePath)")
                    } else {
                        // Leave in place - use original path
                        print("📍 Leaving file in place: \(url.path)")
                        filePath = url.path
                    }

                    // Create database entities
                    try self.createTrack(from: metadata, filePath: filePath, library: backgroundLibrary, context: context)

                    processedFiles += 1

                    // Save periodically
                    if processedFiles % 10 == 0 {
                        try context.save()
                    }
                } catch {
                    // Log error but continue with other files
                    print("Error importing \(fileName): \(error.localizedDescription)")
                }
            }

                // Final save
                try context.save()
            } catch {
                progress.send(completion: .failure(error))
                return
            }
        }

        // Send completion
        progress.send(ImportProgress(
            filesProcessed: totalFiles,
            totalFiles: totalFiles,
            currentFile: nil,
            percentage: 1.0,
            status: .complete
        ))
        progress.send(completion: .finished)
    }

    private func copyFileToLibrary(_ sourceURL: URL, library: Library) throws -> URL {
        // Use ~/Music/Kanora/music/ as the base directory
        let musicDirectory = FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first!
        let kanoraBaseURL = musicDirectory.appendingPathComponent("Kanora").appendingPathComponent("music")

        // Use library name as subdirectory if available, otherwise "default"
        let libraryName = library.name ?? "default"
        let libraryURL = kanoraBaseURL.appendingPathComponent(libraryName)

        let fileName = sourceURL.lastPathComponent
        let destinationURL = libraryURL.appendingPathComponent(fileName)

        print("📂 Library directory: \(libraryURL.path)")
        print("📥 Destination: \(destinationURL.path)")

        // Ensure library directory exists
        try FileManager.default.createDirectory(at: libraryURL, withIntermediateDirectories: true)

        // Copy file
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            print("⚠️ File already exists, removing: \(destinationURL.lastPathComponent)")
            try FileManager.default.removeItem(at: destinationURL)
        }

        print("📋 Copying from: \(sourceURL.path)")
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        print("✅ Copy successful")

        return destinationURL
    }

    private func createTrack(
        from metadata: AudioMetadata,
        filePath: String,
        library: Library,
        context: NSManagedObjectContext
    ) throws {
        // Find or create artist
        let artistName = metadata.artist ?? String(localized: "library.unknown_artist")
        let artist = try findOrCreateArtist(name: artistName, library: library, context: context)

        // Find or create album
        let albumTitle = metadata.albumTitle ?? String(localized: "library.unknown_album")
        let album = try findOrCreateAlbum(title: albumTitle, artist: artist, year: metadata.year, context: context)

        // Create track
        let track = Track(
            title: metadata.title ?? URL(fileURLWithPath: filePath).deletingPathExtension().lastPathComponent,
            filePath: filePath,
            duration: metadata.duration,
            format: metadata.format ?? "Unknown",
            album: album,
            context: context
        )

        // Set additional properties
        track.trackNumber = Int16(metadata.trackNumber ?? 0)
        track.discNumber = Int16(metadata.discNumber ?? 1)
        track.bitrate = Int32(metadata.bitrate ?? 0)

        // Update album duration
        album.totalDuration += metadata.duration
    }

    private func findOrCreateArtist(
        name: String,
        library: Library,
        context: NSManagedObjectContext
    ) throws -> Artist {
        let fetchRequest: NSFetchRequest<Artist> = Artist.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "name == %@ AND library == %@",
            name,
            library
        )
        fetchRequest.fetchLimit = 1

        if let existing = try context.fetch(fetchRequest).first {
            return existing
        }

        return Artist(name: name, library: library, context: context)
    }

    private func findOrCreateAlbum(
        title: String,
        artist: Artist,
        year: Int?,
        context: NSManagedObjectContext
    ) throws -> Album {
        let fetchRequest: NSFetchRequest<Album> = Album.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "title == %@ AND artist == %@",
            title,
            artist
        )
        fetchRequest.fetchLimit = 1

        if let existing = try context.fetch(fetchRequest).first {
            return existing
        }

        return Album(
            title: title,
            artist: artist,
            year: year,
            context: context
        )
    }

    private func fourCCToString(_ fourCC: FourCharCode) -> String {
        let bytes: [CChar] = [
            CChar((fourCC >> 24) & 0xFF),
            CChar((fourCC >> 16) & 0xFF),
            CChar((fourCC >> 8) & 0xFF),
            CChar(fourCC & 0xFF),
            0
        ]
        return String(cString: bytes)
    }
}
