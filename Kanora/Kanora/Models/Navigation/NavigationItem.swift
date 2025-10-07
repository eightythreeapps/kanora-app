//
//  NavigationItem.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import Foundation
import SwiftUI
import Combine

/// Represents a navigation item in the sidebar
struct NavigationItem: Identifiable, Hashable {
    let id = UUID()
    let title: LocalizedStringKey
    let icon: String
    let destination: NavigationDestination
    let section: NavigationSection
    let badge: Int?

    init(
        title: LocalizedStringKey,
        icon: String,
        destination: NavigationDestination,
        section: NavigationSection,
        badge: Int? = nil
    ) {
        self.title = title
        self.icon = icon
        self.destination = destination
        self.section = section
        self.badge = badge
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: NavigationItem, rhs: NavigationItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// Navigation sections in the sidebar
enum NavigationSection: String, CaseIterable {
    case library = "navigation.library"
    case media = "navigation.media"
    case settings = "navigation.settings"
}

/// Navigation destinations
enum NavigationDestination: Hashable {
    // Library
    case artists
    case albums
    case tracks
    case playlists

    // Media
    case cdRipping
    case importFiles

    // Player
    case nowPlaying

    // Settings
    case preferences
    case apiServer
}

/// Navigation state manager
@MainActor
class NavigationState: ObservableObject {
    @Published var selectedDestination: NavigationDestination = .artists
    @Published var selectedPlaylist: Playlist?
    @Published var selectedArtist: Artist?
    @Published var selectedAlbum: Album?

    // Navigation items organized by section
    let navigationItems: [NavigationSection: [NavigationItem]] = [
        .library: [
            NavigationItem(
                title: L10n.Navigation.artists,
                icon: "music.mic",
                destination: .artists,
                section: .library
            ),
            NavigationItem(
                title: L10n.Navigation.albums,
                icon: "square.stack",
                destination: .albums,
                section: .library
            ),
            NavigationItem(
                title: L10n.Navigation.tracks,
                icon: "music.note.list",
                destination: .tracks,
                section: .library
            ),
            NavigationItem(
                title: L10n.Navigation.playlists,
                icon: "music.note.list",
                destination: .playlists,
                section: .library
            )
        ],
        .media: [
            NavigationItem(
                title: L10n.Navigation.cdRipping,
                icon: "opticaldiscdrive",
                destination: .cdRipping,
                section: .media
            ),
            NavigationItem(
                title: L10n.Navigation.importFiles,
                icon: "square.and.arrow.down",
                destination: .importFiles,
                section: .media
            )
        ],
        .settings: [
            NavigationItem(
                title: L10n.Navigation.preferences,
                icon: "gearshape",
                destination: .preferences,
                section: .settings
            ),
            NavigationItem(
                title: L10n.Navigation.apiServer,
                icon: "server.rack",
                destination: .apiServer,
                section: .settings
            )
        ]
    ]

    func navigate(to destination: NavigationDestination) {
        selectedDestination = destination
        selectedPlaylist = nil
        selectedArtist = nil
        selectedAlbum = nil
    }

    func selectPlaylist(_ playlist: Playlist) {
        selectedDestination = .playlists
        selectedPlaylist = playlist
        selectedArtist = nil
        selectedAlbum = nil
    }

    func selectArtist(_ artist: Artist) {
        selectedDestination = .artists
        selectedArtist = artist
        selectedAlbum = nil
    }

    func selectAlbum(_ album: Album) {
        selectedAlbum = album
    }
}
