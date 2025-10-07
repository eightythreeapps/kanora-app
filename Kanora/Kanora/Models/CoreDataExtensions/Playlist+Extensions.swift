//
//  Playlist+Extensions.swift
//  Kanora
//
//  Created by Claude on 06/10/2025.
//

import Foundation
import CoreData

extension Playlist {
    /// Convenience initializer for creating a new Playlist
    convenience init(
        name: String,
        description: String? = nil,
        isSmart: Bool = false,
        library: Library,
        context: NSManagedObjectContext
    ) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.desc = description
        self.isSmart = isSmart
        self.library = library
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Fetch playlists for a specific library
    static func playlistsInLibrary(
        _ library: Library
    ) -> NSFetchRequest<Playlist> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "library == %@", library)
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return request
    }

    /// Add track to playlist
    func addTrack(_ track: Track, context: NSManagedObjectContext) {
        let position = (items?.count ?? 0)
        _ = PlaylistItem(
            track: track,
            playlist: self,
            position: Int32(position),
            context: context
        )
        self.updatedAt = Date()
    }

    /// Remove track from playlist
    func removeTrack(at position: Int, context: NSManagedObjectContext) {
        guard let items = items as? Set<PlaylistItem> else { return }
        let sortedItems = items.sorted { $0.position < $1.position }

        if position < sortedItems.count {
            context.delete(sortedItems[position])

            // Update positions for remaining items
            for (index, item) in sortedItems.enumerated() where index > position {
                item.position = Int32(index - 1)
            }

            self.updatedAt = Date()
        }
    }

    /// Reorder tracks
    func moveTrack(from source: Int, to destination: Int) {
        guard let items = items as? Set<PlaylistItem> else { return }
        let sortedItems = items.sorted { $0.position < $1.position }

        guard source < sortedItems.count,
              destination < sortedItems.count else { return }

        let item = sortedItems[source]

        if source < destination {
            for index in (source + 1)...destination {
                sortedItems[index].position -= 1
            }
        } else {
            for index in destination..<source {
                sortedItems[index].position += 1
            }
        }

        item.position = Int32(destination)
        self.updatedAt = Date()
    }

    /// Total duration of all tracks in playlist
    var totalDuration: Double {
        guard let items = items as? Set<PlaylistItem> else { return 0 }
        return items.reduce(0.0) { $0 + ($1.track?.duration ?? 0) }
    }

    /// Track count
    var trackCount: Int {
        items?.count ?? 0
    }

    /// Sorted items
    var sortedItems: [PlaylistItem] {
        guard let items = items as? Set<PlaylistItem> else { return [] }
        return items.sorted { $0.position < $1.position }
    }
}
