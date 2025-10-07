//
//  Library+Extensions.swift
//  Kanora
//
//  Created by Claude on 06/10/2025.
//

import Foundation
import CoreData

extension Library {
    /// Convenience initializer for creating a new Library
    convenience init(
        name: String,
        path: String,
        type: String = "local",
        user: User,
        context: NSManagedObjectContext
    ) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.path = path
        self.type = type
        self.user = user
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isDefault = false
    }

    /// Fetch request for libraries belonging to a specific user
    static func librariesForUser(
        _ user: User
    ) -> NSFetchRequest<Library> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "user == %@", user)
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return request
    }

    /// Get the default library for a user
    static func defaultLibrary(
        for user: User,
        in context: NSManagedObjectContext
    ) -> Library? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "user == %@ AND isDefault == YES", user)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Update the last scanned timestamp
    func updateLastScanned() {
        self.lastScannedAt = Date()
        self.updatedAt = Date()
    }

    /// Get total track count
    var trackCount: Int {
        guard let artists = artists as? Set<Artist> else { return 0 }
        var total = 0
        for artist in artists {
            guard let albums = artist.albums as? Set<Album> else { continue }
            for album in albums {
                total += album.tracks?.count ?? 0
            }
        }
        return total
    }
}
