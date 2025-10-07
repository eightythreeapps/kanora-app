//
//  TestDataSeeder.swift
//  Kanora
//
//  Created by Claude on 07/10/2025.
//

import Foundation
import CoreData

/// Utility for seeding test data into Core Data for development and testing
class TestDataSeeder {

    // MARK: - Public Methods

    /// Seed the database with Oasis discography data
    /// - Parameter context: The managed object context to insert data into
    /// - Returns: The created library with all data
    @discardableResult
    static func seedOasisDiscography(in context: NSManagedObjectContext) throws -> Library {
        // Check if data already exists
        let userRequest = User.fetchRequest()
        userRequest.predicate = NSPredicate(format: "username == %@", "TestUser")
        if let existingUser = try? context.fetch(userRequest).first,
           let library = existingUser.libraries?.allObjects.first as? Library {
            return library
        }

        // Create test user
        let user = User(username: "TestUser", email: "test@kanora.app", context: context)

        // Create library
        let library = Library(
            name: "My Music",
            path: "/Users/Shared/Music",
            type: "local",
            user: user,
            context: context
        )
        library.isDefault = true

        // Create Oasis artist
        let oasis = Artist(
            name: "Oasis",
            sortName: "Oasis",
            mbid: nil,
            library: library,
            context: context
        )

        // Add all albums
        try createDefinitelyMaybe(artist: oasis, context: context)
        try createWhatsTheStoryMorningGlory(artist: oasis, context: context)
        try createBeHereNow(artist: oasis, context: context)
        try createStandingOnTheShoulder(artist: oasis, context: context)
        try createHeathenChemistry(artist: oasis, context: context)
        try createDontBelieveTheTruth(artist: oasis, context: context)
        try createDigOutYourSoul(artist: oasis, context: context)

        // Save context
        try context.save()

        return library
    }

    // MARK: - Album Creation Methods

    private static func createDefinitelyMaybe(artist: Artist, context: NSManagedObjectContext) throws {
        let album = Album(title: "Definitely Maybe", artist: artist, year: 1994, context: context)

        let tracks: [(title: String, duration: String, trackNumber: Int)] = [
            ("Rock 'n' Roll Star", "05:24", 1),
            ("Shakermaker", "05:08", 2),
            ("Live Forever", "04:36", 3),
            ("Up In The Sky", "04:28", 4),
            ("Columbia", "06:17", 5),
            ("Supersonic", "04:43", 6),
            ("Bring It On Down", "04:17", 7),
            ("Cigarettes & Alcohol", "04:49", 8),
            ("Digsy's Dinner", "02:32", 9),
            ("Slide Away", "06:32", 10),
            ("Married With Children", "03:17", 11)
        ]

        try createTracks(tracks, album: album, context: context)
    }

    private static func createWhatsTheStoryMorningGlory(artist: Artist, context: NSManagedObjectContext) throws {
        let album = Album(title: "(What's the Story) Morning Glory?", artist: artist, year: 1995, context: context)

        let tracks: [(title: String, duration: String, trackNumber: Int)] = [
            ("Hello", "03:23", 1),
            ("Roll With It", "04:00", 2),
            ("Wonderwall", "04:18", 3),
            ("Don't Look Back In Anger", "04:49", 4),
            ("Hey Now!", "05:41", 5),
            ("Untitled (Swamp Song Excerpt 1)", "00:44", 6),
            ("Some Might Say", "05:27", 7),
            ("Cast No Shadow", "04:54", 8),
            ("She's Electric", "03:40", 9),
            ("Morning Glory", "05:03", 10),
            ("Untitled (Swamp Song Excerpt 2)", "00:39", 11),
            ("Champagne Supernova", "07:31", 12)
        ]

        try createTracks(tracks, album: album, context: context)
    }

    private static func createBeHereNow(artist: Artist, context: NSManagedObjectContext) throws {
        let album = Album(title: "Be Here Now", artist: artist, year: 1997, context: context)

        let tracks: [(title: String, duration: String, trackNumber: Int)] = [
            ("D'You Know What I Mean?", "07:42", 1),
            ("My Big Mouth", "05:02", 2),
            ("Magic Pie", "07:19", 3),
            ("Stand by Me", "05:56", 4),
            ("I Hope, I Think, I Know", "04:22", 5),
            ("The Girl in the Dirty Shirt", "05:49", 6),
            ("Fade In-Out", "06:52", 7),
            ("Don't Go Away", "04:48", 8),
            ("Be Here Now", "05:12", 9),
            ("All Around the World", "09:20", 10),
            ("It's Gettin' Better (Man!!)", "07:14", 11),
            ("All Around the World (Reprise)", "02:07", 12)
        ]

        try createTracks(tracks, album: album, context: context)
    }

    private static func createStandingOnTheShoulder(artist: Artist, context: NSManagedObjectContext) throws {
        let album = Album(title: "Standing on the Shoulder of Giants", artist: artist, year: 2000, context: context)

        let tracks: [(title: String, duration: String, trackNumber: Int)] = [
            ("Fuckin' in the Bushes", "03:19", 1),
            ("Go Let It Out", "04:38", 2),
            ("Who Feels Love?", "05:44", 3),
            ("Put Yer Money Where Yer Mouth Is", "04:27", 4),
            ("Little James", "04:15", 5),
            ("Gas Panic!", "06:08", 6),
            ("Where Did It All Go Wrong?", "04:26", 7),
            ("Sunday Morning Call", "05:12", 8),
            ("I Can See a Liar", "03:11", 9),
            ("Roll It Over", "04:04", 10)
        ]

        try createTracks(tracks, album: album, context: context)
    }

    private static func createHeathenChemistry(artist: Artist, context: NSManagedObjectContext) throws {
        let album = Album(title: "Heathen Chemistry", artist: artist, year: 2002, context: context)

        let tracks: [(title: String, duration: String, trackNumber: Int)] = [
            ("The Hindu Times", "03:46", 1),
            ("Force of Nature", "04:52", 2),
            ("Hung in a Bad Place", "03:29", 3),
            ("Stop Crying Your Heart Out", "05:03", 4),
            ("Songbird", "02:08", 5),
            ("Little by Little", "04:53", 6),
            ("A Quick Peep", "01:17", 7),
            ("(Probably) All in the Mind", "04:02", 8),
            ("She Is Love", "03:10", 9),
            ("Born on a Different Cloud", "06:09", 10),
            ("Better Man", "04:51", 11)
        ]

        try createTracks(tracks, album: album, context: context)
    }

    private static func createDontBelieveTheTruth(artist: Artist, context: NSManagedObjectContext) throws {
        let album = Album(title: "Don't Believe the Truth", artist: artist, year: 2005, context: context)

        let tracks: [(title: String, duration: String, trackNumber: Int)] = [
            ("Turn Up the Sun", "03:59", 1),
            ("Mucky Fingers", "03:56", 2),
            ("Lyla", "05:11", 3),
            ("Love Like a Bomb", "02:52", 4),
            ("The Importance of Being Idle", "03:40", 5),
            ("The Meaning of Soul", "01:43", 6),
            ("Guess God Thinks I'm Abel", "03:25", 7),
            ("Part of the Queue", "03:48", 8),
            ("Keep the Dream Alive", "05:46", 9),
            ("A Bell Will Ring", "03:08", 10),
            ("Let There Be Love", "05:32", 11)
        ]

        try createTracks(tracks, album: album, context: context)
    }

    private static func createDigOutYourSoul(artist: Artist, context: NSManagedObjectContext) throws {
        let album = Album(title: "Dig Out Your Soul", artist: artist, year: 2008, context: context)

        let tracks: [(title: String, duration: String, trackNumber: Int)] = [
            ("Bag It Up", "04:40", 1),
            ("The Turning", "05:05", 2),
            ("Waiting for the Rapture", "03:03", 3),
            ("The Shock of the Lightning", "05:00", 4),
            ("I'm Outta Time", "04:10", 5),
            ("(Get Off Your) High Horse Lady", "04:07", 6),
            ("Falling Down", "04:20", 7),
            ("To Be Where There's Life", "04:36", 8),
            ("Ain't Got Nothin'", "02:15", 9),
            ("The Nature of Reality", "02:37", 10),
            ("Soldier On", "04:17", 11)
        ]

        try createTracks(tracks, album: album, context: context)
    }

    // MARK: - Helper Methods

    private static func createTracks(
        _ trackData: [(title: String, duration: String, trackNumber: Int)],
        album: Album,
        context: NSManagedObjectContext
    ) throws {
        for data in trackData {
            let duration = parseDuration(data.duration)

            // Create dummy file path
            let fileName = data.title
                .lowercased()
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "[^a-z0-9_]", with: "", options: .regularExpression)
            let filePath = "/Users/Shared/Music/Oasis/\(album.title ?? "Unknown")/\(fileName).flac"

            let track = Track(
                title: data.title,
                filePath: filePath,
                duration: duration,
                format: "FLAC",
                album: album,
                context: context
            )
            track.trackNumber = Int16(data.trackNumber)
            track.discNumber = Int16(1)
            track.bitrate = 1411 // CD quality FLAC
            track.sampleRate = 44100
            track.fileSize = Int64(duration * 150_000) // Approximate FLAC file size
        }

        // Update album calculated properties
        album.updateCalculatedProperties()
    }

    /// Parse duration string "MM:SS" into TimeInterval (seconds)
    private static func parseDuration(_ durationString: String) -> TimeInterval {
        let components = durationString.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return 0 }
        return Double(components[0] * 60 + components[1])
    }
}
