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

    // MARK: - Initialization

    init(persistence: PersistenceController) {
        self.persistence = persistence
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
        // TODO: Implement actual file scanning logic
        // For now, return a mock publisher
        return Future<ScanProgress, Error> { promise in
            let progress = ScanProgress(
                filesScanned: 0,
                totalFiles: 0,
                currentFile: nil,
                percentage: 1.0
            )
            promise(.success(progress))
        }.eraseToAnyPublisher()
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
}
