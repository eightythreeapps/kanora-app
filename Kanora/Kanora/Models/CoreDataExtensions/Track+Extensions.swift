//
//  Track+Extensions.swift
//  Kanora
//
//  Created by Claude on 06/10/2025.
//

import Foundation
import CoreData

extension Track {
    /// Convenience initializer for creating a new Track
    convenience init(
        title: String,
        filePath: String,
        duration: Double,
        format: String,
        album: Album,
        context: NSManagedObjectContext
    ) {
        self.init(context: context)
        self.id = UUID()
        self.title = title
        self.filePath = filePath
        self.duration = duration
        self.format = format
        self.album = album
        self.createdAt = Date()
        self.updatedAt = Date()
        self.playCount = 0
    }

    /// Fetch tracks for a specific album
    static func tracksForAlbum(
        _ album: Album
    ) -> NSFetchRequest<Track> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "album == %@", album)
        request.sortDescriptors = [
            NSSortDescriptor(key: "discNumber", ascending: true),
            NSSortDescriptor(key: "trackNumber", ascending: true)
        ]
        return request
    }

    /// Find track by file path
    static func findByFilePath(
        _ filePath: String,
        context: NSManagedObjectContext
    ) -> Track? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "filePath == %@", filePath)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Recently played tracks
    static func recentlyPlayedTracks(
        limit: Int = 50
    ) -> NSFetchRequest<Track> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "lastPlayedAt != nil")
        request.sortDescriptors = [
            NSSortDescriptor(key: "lastPlayedAt", ascending: false)
        ]
        request.fetchLimit = limit
        return request
    }

    /// Most played tracks
    static func mostPlayedTracks(
        limit: Int = 50
    ) -> NSFetchRequest<Track> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "playCount > 0")
        request.sortDescriptors = [
            NSSortDescriptor(key: "playCount", ascending: false)
        ]
        request.fetchLimit = limit
        return request
    }

    /// Increment play count
    func incrementPlayCount() {
        self.playCount += 1
        self.lastPlayedAt = Date()
        self.updatedAt = Date()
    }

    /// Formatted duration string (mm:ss)
    var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Formatted file size
    var fileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    /// Artist name (convenience)
    var artistName: String {
        album?.artist?.name ?? L10n.Library.unknownArtistName
    }

    /// Album title (convenience)
    var albumTitle: String {
        album?.title ?? L10n.Library.unknownAlbumName
    }
}
