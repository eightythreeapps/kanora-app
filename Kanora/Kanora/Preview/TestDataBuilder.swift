//
//  TestDataBuilder.swift
//  Kanora
//
//  Created by Ben Reed on 07/10/2025.
//

import CoreData
import Foundation

/// Provides realistic test data for SwiftUI previews and unit tests.
/// All builder methods accept an NSManagedObjectContext and insert entities into that context.
struct TestDataBuilder {

    // MARK: - Static Test Data Arrays

    /// Realistic artist names for test data
    private static let artistNames = [
        "The Beatles", "Pink Floyd", "Led Zeppelin", "Queen", "The Rolling Stones",
        "David Bowie", "Radiohead", "Nirvana", "The Smiths", "Joy Division",
        "Miles Davis", "John Coltrane", "Herbie Hancock", "Nina Simone", "Billie Holiday",
        "Daft Punk", "Aphex Twin", "Kraftwerk", "Brian Eno", "Boards of Canada"
    ]

    /// Realistic album titles paired with artist indices
    private static let albumData: [(artistIndex: Int, title: String, year: Int, genre: String)] = [
        (0, "Abbey Road", 1969, "Rock"),
        (0, "Sgt. Pepper's Lonely Hearts Club Band", 1967, "Rock"),
        (0, "Revolver", 1966, "Rock"),
        (1, "The Dark Side of the Moon", 1973, "Progressive Rock"),
        (1, "Wish You Were Here", 1975, "Progressive Rock"),
        (1, "The Wall", 1979, "Progressive Rock"),
        (2, "Led Zeppelin IV", 1971, "Rock"),
        (2, "Physical Graffiti", 1975, "Rock"),
        (3, "A Night at the Opera", 1975, "Rock"),
        (3, "Bohemian Rhapsody", 1975, "Rock"),
        (4, "Sticky Fingers", 1971, "Rock"),
        (4, "Let It Bleed", 1969, "Rock"),
        (5, "The Rise and Fall of Ziggy Stardust", 1972, "Glam Rock"),
        (5, "Heroes", 1977, "Art Rock"),
        (6, "OK Computer", 1997, "Alternative Rock"),
        (6, "Kid A", 2000, "Electronic"),
        (7, "Nevermind", 1991, "Grunge"),
        (7, "In Utero", 1993, "Grunge"),
        (8, "The Queen Is Dead", 1986, "Indie Rock"),
        (8, "Meat Is Murder", 1985, "Indie Rock"),
        (11, "A Love Supreme", 1965, "Jazz"),
        (12, "Head Hunters", 1973, "Jazz Fusion"),
        (13, "Nina Simone Sings the Blues", 1967, "Jazz"),
        (15, "Random Access Memories", 2013, "Electronic"),
        (16, "Selected Ambient Works 85-92", 1992, "Electronic")
    ]

    /// Realistic track titles for generated tracks
    private static let trackTitles = [
        "Come Together", "Something", "Here Comes the Sun", "Octopus's Garden",
        "I Want You (She's So Heavy)", "Because", "You Never Give Me Your Money",
        "Breathe", "Time", "The Great Gig in the Sky", "Money", "Us and Them",
        "Stairway to Heaven", "Black Dog", "Rock and Roll", "Going to California",
        "Bohemian Rhapsody", "Love of My Life", "You're My Best Friend",
        "Smells Like Teen Spirit", "Come As You Are", "Lithium", "In Bloom",
        "Paranoid Android", "Karma Police", "No Surprises", "Lucky",
        "So What", "Freddie Freeloader", "Blue in Green", "All Blues"
    ]

    /// Audio formats for realistic track data
    private static let audioFormats = ["FLAC", "ALAC", "MP3", "AAC", "WAV"]

    /// Audio codecs for realistic track data
    private static let audioCodecs = ["FLAC", "ALAC", "LAME MP3", "AAC LC", "PCM"]

    // MARK: - User Builders

    /// Creates a default test user
    static func createDefaultUser(in context: NSManagedObjectContext) -> User {
        let user = User(context: context)
        user.id = UUID()
        user.username = "testuser"
        user.email = "test@example.com"
        user.createdAt = Date()
        user.isActive = true
        user.lastLoginAt = Date()
        return user
    }

    /// Creates multiple test users
    static func createUsers(count: Int, in context: NSManagedObjectContext) -> [User] {
        let usernames = ["alice", "bob", "charlie", "diana", "evan"]
        return (0..<min(count, usernames.count)).map { index in
            let user = User(context: context)
            user.id = UUID()
            user.username = usernames[index]
            user.email = "\(usernames[index])@example.com"
            user.createdAt = Date().addingTimeInterval(-Double(index) * 86400)
            user.isActive = true
            user.lastLoginAt = Date().addingTimeInterval(-Double(index) * 3600)
            return user
        }
    }

    // MARK: - Library Builders

    /// Creates an empty library
    static func createEmptyLibrary(for user: User, in context: NSManagedObjectContext) -> Library {
        let library = Library(context: context)
        library.id = UUID()
        library.name = "My Music"
        library.path = "/Users/testuser/Music"
        library.type = "local"
        library.isDefault = true
        library.createdAt = Date()
        library.updatedAt = Date()
        library.user = user
        return library
    }

    /// Creates a library with specified size of content
    static func createLibrary(
        size: LibrarySize,
        for user: User,
        in context: NSManagedObjectContext
    ) -> Library {
        let library = createEmptyLibrary(for: user, in: context)

        switch size {
        case .empty:
            // No content
            break

        case .small:
            // 3 artists, 5 albums, 25 tracks, 2 playlists
            let artists = createArtists(count: 3, in: library, context: context)
            let albums = createAlbums(for: artists, maxAlbums: 5, context: context)
            _ = createTracks(for: albums, tracksPerAlbum: 5, context: context)
            _ = createPlaylists(count: 2, in: library, context: context)

        case .medium:
            // 10 artists, 20 albums, 150 tracks, 5 playlists
            let artists = createArtists(count: 10, in: library, context: context)
            let albums = createAlbums(for: artists, maxAlbums: 20, context: context)
            _ = createTracks(for: albums, tracksPerAlbum: 8, context: context)
            _ = createPlaylists(count: 5, in: library, context: context)

        case .large:
            // 20 artists, 50 albums, 400 tracks, 10 playlists
            let artists = createArtists(count: 20, in: library, context: context)
            let albums = createAlbums(for: artists, maxAlbums: 50, context: context)
            _ = createTracks(for: albums, tracksPerAlbum: 10, context: context)
            _ = createPlaylists(count: 10, in: library, context: context)
        }

        library.lastScannedAt = Date()
        return library
    }

    // MARK: - Artist Builders

    /// Creates multiple artists in a library
    static func createArtists(
        count: Int,
        in library: Library,
        context: NSManagedObjectContext
    ) -> [Artist] {
        return (0..<min(count, artistNames.count)).map { index in
            let artist = Artist(context: context)
            artist.id = UUID()
            artist.name = artistNames[index]
            artist.sortName = artistNames[index]
            artist.biography = "Biography for \(artistNames[index])"
            artist.createdAt = Date().addingTimeInterval(-Double(index) * 3600)
            artist.updatedAt = Date()
            artist.library = library
            return artist
        }
    }

    /// Creates a single artist with specified details
    static func createArtist(
        name: String,
        biography: String? = nil,
        in library: Library,
        context: NSManagedObjectContext
    ) -> Artist {
        let artist = Artist(context: context)
        artist.id = UUID()
        artist.name = name
        artist.sortName = name
        artist.biography = biography
        artist.createdAt = Date()
        artist.updatedAt = Date()
        artist.library = library
        return artist
    }

    // MARK: - Album Builders

    /// Creates albums for given artists
    static func createAlbums(
        for artists: [Artist],
        maxAlbums: Int,
        context: NSManagedObjectContext
    ) -> [Album] {
        var albums: [Album] = []
        var albumCount = 0

        for artist in artists {
            let artistIndex = artistNames.firstIndex(of: artist.name ?? "") ?? 0
            let artistAlbums = albumData.filter { $0.artistIndex == artistIndex }

            for albumInfo in artistAlbums.prefix(maxAlbums - albumCount) {
                let album = Album(context: context)
                album.id = UUID()
                album.title = albumInfo.title
                album.sortTitle = albumInfo.title
                album.year = Int32(albumInfo.year)
                album.genre = albumInfo.genre
                album.createdAt = Date()
                album.updatedAt = Date()
                album.artist = artist
                albums.append(album)

                albumCount += 1
                if albumCount >= maxAlbums {
                    return albums
                }
            }
        }

        return albums
    }

    /// Creates a single album with specified details
    static func createAlbum(
        title: String,
        year: Int?,
        genre: String?,
        for artist: Artist,
        context: NSManagedObjectContext
    ) -> Album {
        let album = Album(context: context)
        album.id = UUID()
        album.title = title
        album.sortTitle = title
        album.year = year.map { Int32($0) } ?? 0
        album.genre = genre
        album.createdAt = Date()
        album.updatedAt = Date()
        album.artist = artist
        return album
    }

    // MARK: - Track Builders

    /// Creates tracks for given albums
    static func createTracks(
        for albums: [Album],
        tracksPerAlbum: Int,
        context: NSManagedObjectContext
    ) -> [Track] {
        var allTracks: [Track] = []

        for (albumIndex, album) in albums.enumerated() {
            var albumDuration: Double = 0

            for trackNum in 1...tracksPerAlbum {
                let trackIndex = (albumIndex * tracksPerAlbum + trackNum - 1) % trackTitles.count
                let duration = Double.random(in: 120...420) // 2-7 minutes
                let track = createTrack(
                    title: trackTitles[trackIndex],
                    trackNumber: trackNum,
                    duration: duration,
                    format: audioFormats[trackNum % audioFormats.count],
                    codec: audioCodecs[trackNum % audioCodecs.count],
                    for: album,
                    context: context
                )
                allTracks.append(track)
                albumDuration += duration
            }

            album.trackCount = Int32(tracksPerAlbum)
            album.totalDuration = albumDuration
        }

        return allTracks
    }

    /// Creates a single track with specified details
    static func createTrack(
        title: String,
        trackNumber: Int,
        duration: Double,
        format: String,
        codec: String,
        for album: Album,
        context: NSManagedObjectContext
    ) -> Track {
        let track = Track(context: context)
        track.id = UUID()
        track.title = title
        track.trackNumber = Int16(trackNumber)
        track.discNumber = 1
        track.duration = duration
        track.format = format
        track.codec = codec
        track.filePath = "/Music/\(album.artist?.name ?? "Unknown")/\(album.title ?? "Unknown")/\(trackNumber) \(title).\(format.lowercased())"
        track.fileSize = Int64(duration * 1000 * 320) // Approximate file size
        track.bitrate = format == "FLAC" || format == "ALAC" || format == "WAV" ? 1411 : 320
        track.sampleRate = 44100
        track.channels = 2
        track.genre = album.genre
        track.year = album.year
        track.playCount = 0
        track.createdAt = Date()
        track.updatedAt = Date()
        track.album = album
        return track
    }

    // MARK: - Playlist Builders

    /// Creates playlists in a library
    static func createPlaylists(
        count: Int,
        in library: Library,
        context: NSManagedObjectContext
    ) -> [Playlist] {
        let playlistNames = [
            "Favorites", "Workout", "Chill", "Focus", "Party",
            "Road Trip", "Study", "Sleep", "Morning", "Evening"
        ]

        return (0..<min(count, playlistNames.count)).map { index in
            let playlist = Playlist(context: context)
            playlist.id = UUID()
            playlist.name = playlistNames[index]
            playlist.desc = "My \(playlistNames[index].lowercased()) playlist"
            playlist.isSmart = false
            playlist.createdAt = Date().addingTimeInterval(-Double(index) * 86400)
            playlist.updatedAt = Date()
            playlist.library = library
            return playlist
        }
    }

    /// Creates a playlist with tracks
    static func createPlaylist(
        name: String,
        description: String?,
        tracks: [Track],
        in library: Library,
        context: NSManagedObjectContext
    ) -> Playlist {
        let playlist = Playlist(context: context)
        playlist.id = UUID()
        playlist.name = name
        playlist.desc = description
        playlist.isSmart = false
        playlist.createdAt = Date()
        playlist.updatedAt = Date()
        playlist.library = library

        // Add tracks to playlist
        for (index, track) in tracks.enumerated() {
            let item = PlaylistItem(context: context)
            item.id = UUID()
            item.position = Int32(index)
            item.addedAt = Date()
            item.playlist = playlist
            item.track = track
        }

        return playlist
    }

    // MARK: - Complete Data Graph Builders

    /// Creates a complete data graph based on the preview state
    static func createDataGraph(
        for state: PreviewState,
        in context: NSManagedObjectContext
    ) -> (user: User, library: Library) {
        let user = createDefaultUser(in: context)

        let library: Library
        switch state {
        case .empty:
            library = createLibrary(size: .empty, for: user, in: context)

        case .populated, .loading, .error:
            // Loading and error use same data as populated
            library = createLibrary(size: .medium, for: user, in: context)
        }

        return (user, library)
    }
}

// MARK: - Supporting Types

extension TestDataBuilder {
    /// Library size options for test data generation
    enum LibrarySize {
        case empty
        case small
        case medium
        case large
    }
}
