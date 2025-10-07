//
//  Artist+Extensions.swift
//  Kanora
//
//  Created by Claude on 06/10/2025.
//

import Foundation
import CoreData

extension Artist {
    /// Convenience initializer for creating a new Artist
    convenience init(
        name: String,
        sortName: String? = nil,
        mbid: String? = nil,
        library: Library,
        context: NSManagedObjectContext
    ) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.sortName = sortName ?? name
        self.mbid = mbid
        self.library = library
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Fetch artists for a specific library
    static func artistsInLibrary(
        _ library: Library
    ) -> NSFetchRequest<Artist> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "library == %@", library)
        request.sortDescriptors = [NSSortDescriptor(key: "sortName", ascending: true)]
        return request
    }

    /// Find artist by name in a library
    static func findByName(
        _ name: String,
        in library: Library,
        context: NSManagedObjectContext
    ) -> Artist? {
        let request = fetchRequest()
        request.predicate = NSPredicate(
            format: "name ==[cd] %@ AND library == %@",
            name,
            library
        )
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Find or create artist
    static func findOrCreate(
        name: String,
        sortName: String? = nil,
        mbid: String? = nil,
        in library: Library,
        context: NSManagedObjectContext
    ) -> Artist {
        if let existing = findByName(name, in: library, context: context) {
            return existing
        }
        return Artist(
            name: name,
            sortName: sortName,
            mbid: mbid,
            library: library,
            context: context
        )
    }

    /// Total album count
    var albumCount: Int {
        albums?.count ?? 0
    }

    /// Total track count across all albums
    var trackCount: Int {
        guard let albums = albums as? Set<Album> else { return 0 }
        return albums.reduce(0) { count, album in
            count + (album.tracks?.count ?? 0)
        }
    }
}
