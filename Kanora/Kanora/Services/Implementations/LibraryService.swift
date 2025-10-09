//
//  LibraryService.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import Foundation
import CoreData
import Combine

/// Default implementation of LibraryServiceProtocol
class LibraryService: LibraryServiceProtocol {
    // MARK: - Properties

    private let persistence: PersistenceController
    private let fileImportService: FileImportServiceProtocol
    private let logger = AppLogger.libraryService
    private let scanQueue = DispatchQueue(
        label: "com.kanora.libraryservice.scan",
        qos: .userInitiated
    )

    // MARK: - Initialization

    init(
        persistence: PersistenceController,
        fileImportService: FileImportServiceProtocol? = nil
    ) {
        self.persistence = persistence
        self.fileImportService = fileImportService ?? FileImportService(persistence: persistence)
    }

    // MARK: - LibraryServiceProtocol

    func fetchLibraries(
        for user: User,
        in context: NSManagedObjectContext
    ) throws -> [Library] {
        let request = Library.librariesForUser(user)
        return try context.fetch(request)
    }

    func createLibrary(
        name: String,
        path: String,
        user: User,
        in context: NSManagedObjectContext
    ) throws -> Library {
        let library = Library(
            name: name,
            path: path,
            user: user,
            context: context
        )

        try persistence.save(context: context)
        return library
    }

    func scanLibrary(
        _ library: Library,
        in context: NSManagedObjectContext,
        progressHandler: ((Double) -> Void)?
    ) -> AnyPublisher<ScanProgress, Error> {
        let subject = PassthroughSubject<ScanProgress, Error>()

        guard let path = library.path, !path.isEmpty else {
            logger.error("❌ Missing library path for library: \(library.objectID)")
            subject.send(completion: .failure(LibraryServiceError.missingLibraryPath))
            return subject.eraseToAnyPublisher()
        }

        let libraryID = library.objectID
        let directoryURL = URL(fileURLWithPath: path, isDirectory: true)

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            logger.error("❌ Library path is not a directory: \(directoryURL.path)")
            subject.send(
                completion: .failure(
                    LibraryServiceError.libraryDirectoryNotFound(directoryURL.path)
                )
            )
            return subject.eraseToAnyPublisher()
        }

        scanQueue.async { [weak self] in
            guard let self else { return }

            self.logger.info("🚀 Starting scan for library at path: \(directoryURL.path)")

            let audioFiles = self.fileImportService.scanDirectory(directoryURL)
            let totalFiles = audioFiles.count

            let initialProgress = ScanProgress(
                filesScanned: 0,
                totalFiles: totalFiles,
                currentFile: nil,
                percentage: totalFiles == 0 ? 1.0 : 0.0
            )
            self.publish(
                progress: initialProgress,
                to: subject,
                handler: progressHandler
            )

            if totalFiles > 0 {
                for (index, fileURL) in audioFiles.enumerated() {
                    let filesScanned = index + 1
                    let progress = ScanProgress(
                        filesScanned: filesScanned,
                        totalFiles: totalFiles,
                        currentFile: fileURL.lastPathComponent,
                        percentage: Double(filesScanned) / Double(totalFiles)
                    )

                    self.publish(
                        progress: progress,
                        to: subject,
                        handler: progressHandler
                    )
                }
            }

            self.completeScan(
                for: libraryID,
                in: context,
                subject: subject
            )
        }

        return subject.eraseToAnyPublisher()
    }

    func deleteLibrary(
        _ library: Library,
        in context: NSManagedObjectContext
    ) throws {
        context.delete(library)
        try persistence.save(context: context)
    }

    func updateLibrary(
        _ library: Library,
        name: String?,
        path: String?,
        in context: NSManagedObjectContext
    ) throws {
        if let name = name {
            library.name = name
        }
        if let path = path {
            library.path = path
        }
        library.updatedAt = Date()

        try persistence.save(context: context)
    }

    func getLibraryStatistics(
        for library: Library,
        in context: NSManagedObjectContext
    ) -> LibraryStatistics {
        let artistCount = library.artists?.count ?? 0

        var albumCount = 0
        var trackCount = 0
        var totalDuration: TimeInterval = 0

        if let artists = library.artists as? Set<Artist> {
            for artist in artists {
                if let albums = artist.albums as? Set<Album> {
                    albumCount += albums.count
                    for album in albums {
                        if let tracks = album.tracks as? Set<Track> {
                            trackCount += tracks.count
                            totalDuration += tracks.reduce(0.0) { $0 + $1.duration }
                        }
                    }
                }
            }
        }

        return LibraryStatistics(
            artistCount: artistCount,
            albumCount: albumCount,
            trackCount: trackCount,
            totalDuration: totalDuration,
            totalSize: 0, // TODO: Calculate from actual file sizes
            lastScannedAt: library.lastScannedAt
        )
    }

    // MARK: - Private Helpers

    private func publish(
        progress: ScanProgress,
        to subject: PassthroughSubject<ScanProgress, Error>,
        handler: ((Double) -> Void)?
    ) {
        logger.debug(
            "📡 Scan progress: \(progress.filesScanned)/\(progress.totalFiles) " +
            "(\(Int(progress.percentage * 100))%)"
        )

        subject.send(progress)

        if let handler = handler {
            DispatchQueue.main.async {
                handler(progress.percentage)
            }
        }
    }

    private func completeScan(
        for libraryID: NSManagedObjectID,
        in context: NSManagedObjectContext,
        subject: PassthroughSubject<ScanProgress, Error>
    ) {
        context.perform { [weak self] in
            guard let self else { return }

            do {
                if let managedLibrary = try context.existingObject(with: libraryID) as? Library {
                    managedLibrary.updateLastScanned()
                    try self.persistence.save(context: context)
                } else {
                    self.logger.warning("⚠️ Unable to cast managed object to Library for ID: \(libraryID)")
                }

                subject.send(completion: .finished)
            } catch {
                self.logger.error("❌ Failed to finalize library scan: \(error.localizedDescription)")
                subject.send(completion: .failure(error))
            }
        }
    }
}

// MARK: - LibraryServiceError

enum LibraryServiceError: LocalizedError {
    case missingLibraryPath
    case libraryDirectoryNotFound(String)

    var errorDescription: String? {
        switch self {
        case .missingLibraryPath:
            return "Library path is missing."
        case .libraryDirectoryNotFound(let path):
            return "Library directory not found at path: \(path)"
        }
    }
}
