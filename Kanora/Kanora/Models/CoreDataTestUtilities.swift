//
//  CoreDataTestUtilities.swift
//  Kanora
//
//  Created by Claude on 06/10/2025.
//

import Foundation
import CoreData

/// Utilities for testing Core Data functionality
struct CoreDataTestUtilities {
    /// Create an in-memory persistence controller for testing
    static func createInMemoryController() -> PersistenceController {
        return PersistenceController(inMemory: true)
    }

    /// Create sample data for testing
    static func createSampleData(
        in context: NSManagedObjectContext
    ) {
        // Create a test user
        let user = User(username: "testuser", email: "test@example.com", context: context)

        // Create a test library
        let library = Library(
            name: "Test Library",
            path: "/Users/test/Music",
            user: user,
            context: context
        )
        library.isDefault = true

        // Create test artists
        let artist1 = Artist(
            name: "The Beatles",
            sortName: "Beatles, The",
            library: library,
            context: context
        )

        let artist2 = Artist(
            name: "Pink Floyd",
            sortName: "Pink Floyd",
            library: library,
            context: context
        )

        // Create test albums
        let album1 = Album(
            title: "Abbey Road",
            artist: artist1,
            year: 1969,
            context: context
        )

        let album2 = Album(
            title: "The Dark Side of the Moon",
            artist: artist2,
            year: 1973,
            context: context
        )

        // Create test tracks
        let track1 = Track(
            title: "Come Together",
            filePath: "/Users/test/Music/Beatles/Abbey Road/01 Come Together.mp3",
            duration: 259.0,
            format: "mp3",
            album: album1,
            context: context
        )
        track1.trackNumber = 1
        track1.bitrate = 320

        let track2 = Track(
            title: "Something",
            filePath: "/Users/test/Music/Beatles/Abbey Road/02 Something.mp3",
            duration: 182.0,
            format: "mp3",
            album: album1,
            context: context
        )
        track2.trackNumber = 2
        track2.bitrate = 320

        let track3 = Track(
            title: "Time",
            filePath: "/Users/test/Music/Pink Floyd/Dark Side/05 Time.mp3",
            duration: 413.0,
            format: "mp3",
            album: album2,
            context: context
        )
        track3.trackNumber = 5
        track3.bitrate = 320

        // Create a test playlist
        let playlist = Playlist(
            name: "Favorites",
            description: "My favorite tracks",
            library: library,
            context: context
        )

        playlist.addTrack(track1, context: context)
        playlist.addTrack(track3, context: context)

        // Update calculated properties
        album1.updateCalculatedProperties()
        album2.updateCalculatedProperties()

        // Save context
        do {
            try context.save()
        } catch {
            print("Error creating sample data: \(error)")
        }
    }

    /// Clear all data from context
    static func clearAllData(in context: NSManagedObjectContext) {
        let entities = [
            "PlaylistItem",
            "Playlist",
            "Track",
            "Album",
            "Artist",
            "Library",
            "User"
        ]

        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try context.execute(deleteRequest)
                try context.save()
            } catch {
                print("Error clearing \(entityName): \(error)")
            }
        }
    }

    /// Verify data integrity
    static func verifyDataIntegrity(in context: NSManagedObjectContext) -> [String] {
        var issues: [String] = []

        // Check for tracks without albums
        let orphanedTracks = NSFetchRequest<Track>(entityName: "Track")
        orphanedTracks.predicate = NSPredicate(format: "album == nil")
        if let count = try? context.count(for: orphanedTracks), count > 0 {
            issues.append("Found \(count) tracks without albums")
        }

        // Check for albums without artists
        let orphanedAlbums = NSFetchRequest<Album>(entityName: "Album")
        orphanedAlbums.predicate = NSPredicate(format: "artist == nil")
        if let count = try? context.count(for: orphanedAlbums), count > 0 {
            issues.append("Found \(count) albums without artists")
        }

        // Check for artists without libraries
        let orphanedArtists = NSFetchRequest<Artist>(entityName: "Artist")
        orphanedArtists.predicate = NSPredicate(format: "library == nil")
        if let count = try? context.count(for: orphanedArtists), count > 0 {
            issues.append("Found \(count) artists without libraries")
        }

        // Check for duplicate file paths
        let allTracks = NSFetchRequest<Track>(entityName: "Track")
        if let tracks = try? context.fetch(allTracks) {
            let filePaths = tracks.map { $0.filePath }
            let uniquePaths = Set(filePaths)
            if filePaths.count != uniquePaths.count {
                issues.append("Found duplicate file paths")
            }
        }

        return issues
    }
}
