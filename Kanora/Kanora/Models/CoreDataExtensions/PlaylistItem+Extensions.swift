//
//  PlaylistItem+Extensions.swift
//  Kanora
//
//  Created by Claude on 06/10/2025.
//

import Foundation
import CoreData

extension PlaylistItem {
    /// Convenience initializer for creating a new PlaylistItem
    convenience init(
        track: Track,
        playlist: Playlist,
        position: Int32,
        context: NSManagedObjectContext
    ) {
        self.init(context: context)
        self.id = UUID()
        self.track = track
        self.playlist = playlist
        self.position = position
        self.addedAt = Date()
    }

}
