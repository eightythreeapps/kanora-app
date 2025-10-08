import Foundation
import CoreData
#if canImport(AppKit)
import AppKit
private typealias PlatformImage = NSImage
#elseif canImport(UIKit)
import UIKit
private typealias PlatformImage = UIImage
#endif

struct LibrarySummary: Identifiable, Equatable {
    let id: UUID
    let name: String
    let path: String
    let type: String
    let isDefault: Bool
    let createdAt: Date?
    let updatedAt: Date?

    init(
        id: UUID,
        name: String,
        path: String,
        type: String,
        isDefault: Bool,
        createdAt: Date?,
        updatedAt: Date?
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.type = type
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init?(library: Library) {
        guard let id = library.id else {
            return nil
        }

        self.init(
            id: id,
            name: library.name?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? "Untitled Library",
            path: library.path ?? "",
            type: library.type ?? "local",
            isDefault: library.isDefault,
            createdAt: library.createdAt,
            updatedAt: library.updatedAt
        )
    }
}

struct TrackViewData: Identifiable, Equatable {
    let id: UUID
    let title: String
    let artistName: String
    let albumTitle: String
    let duration: TimeInterval
    let artworkPath: String?

    init(
        id: UUID,
        title: String,
        artistName: String,
        albumTitle: String,
        duration: TimeInterval,
        artworkPath: String?
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.albumTitle = albumTitle
        self.duration = duration
        self.artworkPath = artworkPath
    }

    init?(track: Track) {
        guard let id = track.id else {
            return nil
        }

        self.init(
            id: id,
            title: track.title?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? "Unknown Track",
            artistName: track.album?.artist?.name?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? "Unknown Artist",
            albumTitle: track.album?.title?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? "Unknown Album",
            duration: track.duration,
            artworkPath: track.album?.artworkPath
        )
    }

    var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    #if canImport(AppKit) || canImport(UIKit)
    var artworkImage: PlatformImage? {
        guard let artworkPath else { return nil }
        return PlatformImage(contentsOfFile: artworkPath)
    }
    #else
    var artworkImage: Any? { nil }
    #endif
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
