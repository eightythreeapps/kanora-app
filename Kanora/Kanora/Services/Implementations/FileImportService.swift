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
        print("📋 Import mode: \(mode.displayNameText)")
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
        var artworkData: Data?

        for item in asset.commonMetadata {
            if let key = item.commonKey?.rawValue {
                switch key {
                case "title":
                    title = item.stringValue
                case "artist":
                    artist = item.stringValue
                case "albumName":
                    albumTitle = item.stringValue
                case "type":
                    genre = item.stringValue
                case "artwork":
                    // Extract artwork data
                    if let data = item.dataValue {
                        print("🎨 Found artwork in common metadata: \(data.count) bytes")
                        artworkData = data
                    }
                default:
                    break
                }
            }

            // Always check identifiers for track number, disc number, etc.
            if let identifier = item.identifier?.rawValue {
                print("🔍 Common metadata identifier: \(identifier)")

                // Track number - ALAC uses 'trkn', iTunes uses 'com.apple.iTunes.track-number'
                if trackNumber == nil && (identifier.contains("trackNumber") || identifier.contains("trkn") || identifier == "com.apple.iTunes.track-number") {
                    if let value = item.numberValue {
                        trackNumber = value.intValue
                        print("🔢 Found track number in common metadata (number): \(trackNumber!)")
                    } else if let stringValue = item.stringValue {
                        let components = stringValue.components(separatedBy: "/")
                        if let value = Int(components[0]) {
                            trackNumber = value
                            print("🔢 Found track number in common metadata (string): \(trackNumber!)")
                        }
                    } else if let data = item.dataValue {
                        // ALAC stores track numbers as binary data in iTunes-style 'trkn' atom
                        // Format: [padding1, padding2, track_high_byte, track_low_byte, total_high_byte, total_low_byte]
                        if data.count >= 4 {
                            let bytes = [UInt8](data)
                            let trackNum = Int(bytes[2]) * 256 + Int(bytes[3])
                            if trackNum > 0 {
                                trackNumber = trackNum
                                print("🔢 Found track number in common metadata (binary): \(trackNumber!) from \(data.count) bytes")
                            }
                        }
                    }
                }

                // Disc number
                if discNumber == nil && (identifier.contains("discNumber") || identifier.contains("disk") || identifier == "com.apple.iTunes.disc-number") {
                    if let value = item.numberValue {
                        discNumber = value.intValue
                        print("💿 Found disc number in common metadata (number): \(discNumber!)")
                    } else if let stringValue = item.stringValue {
                        let components = stringValue.components(separatedBy: "/")
                        if let value = Int(components[0]) {
                            discNumber = value
                            print("💿 Found disc number in common metadata (string): \(discNumber!)")
                        }
                    }
                }
            }
        }

        // Try all available metadata formats for additional tags
        print("🔍 Available metadata formats: \(asset.availableMetadataFormats)")
        for format in asset.availableMetadataFormats {
            let metadata = asset.metadata(forFormat: format)
            print("📋 Format: \(format.rawValue) - \(metadata.count) items")

            for item in metadata {
                // Try common keys first
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

                // Check specific identifiers for track number, disc number, etc.
                if let identifier = item.identifier?.rawValue {
                    // Debug: log all identifiers to see what's available
                    if trackNumber == nil || discNumber == nil {
                        let valueDesc = item.stringValue ?? item.numberValue?.description ?? (item.dataValue != nil ? "<binary \(item.dataValue!.count) bytes>" : "nil")
                        print("   🏷️ Identifier: \(identifier) - Value: \(valueDesc)")
                    }

                    // Track number - check for trkn (iTunes/ALAC), trackNumber, TRCK (ID3)
                    if trackNumber == nil && (identifier.contains("trkn") || identifier.contains("trackNumber") || identifier.contains("TRCK")) {
                        if let value = item.numberValue {
                            trackNumber = value.intValue
                            print("🔢 Found track number (number): \(trackNumber!)")
                        } else if let stringValue = item.stringValue {
                            // Handle formats like "3" or "3/12"
                            let components = stringValue.components(separatedBy: "/")
                            if let value = Int(components[0]) {
                                trackNumber = value
                                print("🔢 Found track number (string): \(trackNumber!)")
                            }
                        } else if let data = item.dataValue {
                            // ALAC/iTunes stores track numbers as binary data
                            // Format: [padding, padding, track_high_byte, track_low_byte, total_high, total_low]
                            if data.count >= 4 {
                                let bytes = [UInt8](data)
                                let trackNum = Int(bytes[2]) * 256 + Int(bytes[3])
                                if trackNum > 0 {
                                    trackNumber = trackNum
                                    print("🔢 Found track number (binary format): \(trackNumber!) from \(data.count) bytes")
                                }
                            } else if data.count >= 2 {
                                // Sometimes it's just 2 bytes
                                let bytes = [UInt8](data)
                                let trackNum = Int(bytes[0]) * 256 + Int(bytes[1])
                                if trackNum > 0 {
                                    trackNumber = trackNum
                                    print("🔢 Found track number (binary short format): \(trackNumber!) from \(data.count) bytes")
                                }
                            }
                        }
                    }

                    // Disc number - check for disk, discNumber, TPOS
                    if discNumber == nil && (identifier.contains("disk") || identifier.contains("discNumber") || identifier.contains("TPOS") || identifier.contains("partOfASet")) {
                        if let value = item.numberValue {
                            discNumber = value.intValue
                            print("💿 Found disc number (number): \(discNumber!)")
                        } else if let stringValue = item.stringValue {
                            let components = stringValue.components(separatedBy: "/")
                            if let value = Int(components[0]) {
                                discNumber = value
                                print("💿 Found disc number (string): \(discNumber!)")
                            }
                        } else if let data = item.dataValue {
                            // Same binary format as track number
                            if data.count >= 4 {
                                let bytes = [UInt8](data)
                                let discNum = Int(bytes[2]) * 256 + Int(bytes[3])
                                if discNum > 0 {
                                    discNumber = discNum
                                    print("💿 Found disc number (binary): \(discNumber!)")
                                }
                            }
                        }
                    }

                    // Year
                    if year == nil && (identifier.contains("date") || identifier.contains("TDRC") || identifier.contains("TYER")) {
                        if let stringValue = item.stringValue, stringValue.count >= 4 {
                            if let value = Int(stringValue.prefix(4)) {
                                year = value
                                print("📅 Found year: \(year!)")
                            }
                        }
                    }

                    // Album Artist
                    if albumArtist == nil && (identifier.contains("albumArtist") || identifier.contains("TPE2")) {
                        albumArtist = item.stringValue
                        if albumArtist != nil {
                            print("👤 Found album artist: \(albumArtist!)")
                        }
                    }

                    // Genre
                    if genre == nil && (identifier.contains("genre") || identifier.contains("TCON")) {
                        genre = item.stringValue
                        if genre != nil {
                            print("🎸 Found genre: \(genre!)")
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
            fileSize: Int64(fileSize),
            artworkData: artworkData
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

    func scanDirectory(_ directoryURL: URL) -> [URL] {
        print("📂 Scanning directory: \(directoryURL.path)")
        var audioFiles: [URL] = []

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            print("❌ Failed to create directory enumerator")
            return []
        }

        for case let fileURL as URL in enumerator {
            // Check if it's a file (not a directory)
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                  let isFile = resourceValues.isRegularFile,
                  isFile else {
                continue
            }

            // Check if it's an audio file
            if isValidAudioFile(fileURL) {
                audioFiles.append(fileURL)
                print("  ✅ Found audio file: \(fileURL.lastPathComponent)")
            }
        }

        print("📊 Scan complete: found \(audioFiles.count) audio files")
        return audioFiles
    }

    func pointAtDirectory(
        _ directoryURL: URL,
        library: Library,
        in context: NSManagedObjectContext
    ) -> AnyPublisher<ImportProgress, Error> {
        print("📍 Pointing library at directory: \(directoryURL.path)")

        // Update library path to point at this directory
        library.path = directoryURL.path

        // Scan directory for audio files
        let audioFiles = scanDirectory(directoryURL)
        print("🎵 Found \(audioFiles.count) audio files to import")

        // Import all files using "leave in place" mode
        return importFiles(audioFiles, into: library, in: context, mode: .pointAtDirectory)
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
                    if mode == .addToKanora {
                        print("📁 Adding file to Kanora (copy and organize)")
                        progress.send(ImportProgress(
                            filesProcessed: processedFiles,
                            totalFiles: totalFiles,
                            currentFile: fileName,
                            percentage: Double(processedFiles) / Double(totalFiles),
                            status: .copyingFile
                        ))

                        let destinationURL = try self.copyFileToKanora(url, metadata: metadata, library: backgroundLibrary)
                        filePath = destinationURL.path
                        print("✅ File copied and organized: \(filePath)")
                    } else {
                        // Point at directory - use original path
                        print("📍 Keeping file in place: \(url.path)")
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

    private func copyFileToKanora(_ sourceURL: URL, metadata: AudioMetadata, library: Library) throws -> URL {
        // Determine base directory - use library.path if it's a managed library, otherwise ~/Music/Kanora/
        let baseURL: URL
        if let libraryPath = library.path, libraryPath.contains("/Kanora/") {
            // Library already points to Kanora directory
            baseURL = URL(fileURLWithPath: libraryPath)
        } else {
            // Create new managed library path
            let musicDirectory = FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first!
            baseURL = musicDirectory.appendingPathComponent("Kanora").appendingPathComponent("music")
        }

        // Organize by Artist/Album
        let artistName = (metadata.albumArtist ?? metadata.artist ?? "Unknown Artist")
            .replacingOccurrences(of: "/", with: "-")  // Sanitize for file system
        let albumName = (metadata.albumTitle ?? "Unknown Album")
            .replacingOccurrences(of: "/", with: "-")

        let artistURL = baseURL.appendingPathComponent(artistName)
        let albumURL = artistURL.appendingPathComponent(albumName)

        let fileName = sourceURL.lastPathComponent
        let destinationURL = albumURL.appendingPathComponent(fileName)

        print("📂 Organizing to: \(artistName)/\(albumName)/\(fileName)")
        print("📥 Full destination: \(destinationURL.path)")

        // Ensure album directory exists
        try FileManager.default.createDirectory(at: albumURL, withIntermediateDirectories: true)

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

        // Save artwork if available and album doesn't have artwork yet
        if let artworkData = metadata.artworkData, album.artworkPath == nil {
            do {
                let artworkPath = try saveArtwork(artworkData, for: album, library: library)
                album.artworkPath = artworkPath
                print("🎨 Saved artwork to: \(artworkPath)")
            } catch {
                print("⚠️ Failed to save artwork: \(error.localizedDescription)")
            }
        }

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

    private func saveArtwork(_ artworkData: Data, for album: Album, library: Library) throws -> String {
        // Use ~/Music/Kanora/artwork/ directory
        let musicDirectory = FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first!
        let artworkDirectory = musicDirectory.appendingPathComponent("Kanora").appendingPathComponent("artwork")

        // Create artwork directory if needed
        try FileManager.default.createDirectory(at: artworkDirectory, withIntermediateDirectories: true)

        // Generate filename from album ID
        let filename = "\(album.id?.uuidString ?? UUID().uuidString).jpg"
        let artworkURL = artworkDirectory.appendingPathComponent(filename)

        // Write artwork data
        try artworkData.write(to: artworkURL)

        return artworkURL.path
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
