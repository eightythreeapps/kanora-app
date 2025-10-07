//
//  Album+Extensions.swift
//  Kanora
//
//  Created by Claude on 06/10/2025.
//

import Foundation
import CoreData

extension Album {
    /// Convenience initializer for creating a new Album
    convenience init(
        title: String,
        artist: Artist,
        year: Int? = nil,
        context: NSManagedObjectContext
    ) {
        self.init(context: context)
        self.id = UUID()
        self.title = title
        self.sortTitle = title
        self.artist = artist
        self.year = Int32(year ?? 0)
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Fetch albums for a specific artist
    static func albumsForArtist(
        _ artist: Artist
    ) -> NSFetchRequest<Album> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "artist == %@", artist)
        request.sortDescriptors = [
            NSSortDescriptor(key: "year", ascending: true),
            NSSortDescriptor(key: "sortTitle", ascending: true)
        ]
        return request
    }

    /// Find album by title and artist
    static func findByTitle(
        _ title: String,
        artist: Artist,
        context: NSManagedObjectContext
    ) -> Album? {
        let request = fetchRequest()
        request.predicate = NSPredicate(
            format: "title ==[cd] %@ AND artist == %@",
            title,
            artist
        )
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Find or create album
    static func findOrCreate(
        title: String,
        artist: Artist,
        year: Int? = nil,
        context: NSManagedObjectContext
    ) -> Album {
        if let existing = findByTitle(title, artist: artist, context: context) {
            return existing
        }
        return Album(
            title: title,
            artist: artist,
            year: year,
            context: context
        )
    }

    /// Update calculated properties
    func updateCalculatedProperties() {
        guard let tracks = tracks as? Set<Track> else { return }
        self.trackCount = Int32(tracks.count)
        self.totalDuration = tracks.reduce(0.0) { $0 + $1.duration }
        self.updatedAt = Date()
    }

    /// Formatted duration string
    var durationFormatted: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        let seconds = Int(totalDuration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
