//
//  ContentView.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import SwiftUI
import CoreData
import Combine

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var navigationState = NavigationState()
    private let services = ServiceContainer.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            if #available(iOS 16.0, macOS 13.0, *) {
                // Use NavigationStack on iPhone, NavigationSplitView on iPad/Mac
                if horizontalSizeClass == .compact {
                    compactLayout
                } else {
                    splitViewLayout
                }
            } else {
                // Fallback for macOS 12
                fallbackLayout
            }

            // Floating mini player (only show when not on Now Playing view)
            if navigationState.selectedDestination != .nowPlaying {
                FloatingMiniPlayer(services: services)
            }
        }
    }

    // MARK: - Layout Variants

    @available(iOS 16.0, macOS 13.0, *)
    private var splitViewLayout: some View {
        NavigationSplitView(
            sidebar: {
                SidebarView(navigationState: navigationState, navigationMode: .split)
            },
            content: {
                contentColumn
            },
            detail: {
                detailColumn
            }
        )
        .environment(\.managedObjectContext, viewContext)
        .environmentObject(navigationState)
    }

    @available(iOS 16.0, macOS 13.0, *)
    private var compactLayout: some View {
        NavigationStack {
            SidebarView(navigationState: navigationState, navigationMode: .stack)
                .navigationDestination(for: NavigationDestination.self) { destination in
                    // Update navigation state
                    DispatchQueue.main.async {
                        navigationState.navigate(to: destination)
                    }
                    // Return the appropriate view
                    return destinationView(for: destination)
                }
        }
        .environment(\.managedObjectContext, viewContext)
        .environmentObject(navigationState)
    }

    @available(iOS 16.0, macOS 13.0, *)
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .artists:
            ArtistsView()
        case .albums:
            AlbumsView()
        case .tracks:
            TracksView()
        case .playlists:
            PlaylistsView()
        case .nowPlaying:
            NowPlayingView(services: services)
        case .cdRipping:
            PlaceholderView(
                icon: "opticaldiscdrive",
                title: L10n.Navigation.cdRipping,
                message: L10n.Placeholders.cdRippingMessage
            )
        case .importFiles:
            PlaceholderView(
                icon: "square.and.arrow.down",
                title: L10n.Navigation.importFiles,
                message: L10n.Placeholders.importFilesMessage
            )
        case .preferences:
            PlaceholderView(
                icon: "gearshape",
                title: L10n.Navigation.preferences,
                message: L10n.Placeholders.preferencesMessage
            )
        case .apiServer:
            PlaceholderView(
                icon: "server.rack",
                title: L10n.Navigation.apiServer,
                message: L10n.Placeholders.apiServerMessage
            )
        }
    }

    private var fallbackLayout: some View {
        HStack(spacing: 0) {
            SidebarView(navigationState: navigationState, navigationMode: .split)

            Divider()

            contentColumn

            Divider()

            detailColumn
        }
        .environment(\.managedObjectContext, viewContext)
        .environmentObject(navigationState)
    }

    // MARK: - Column Views

    @ViewBuilder
    private var contentColumn: some View {
        switch navigationState.selectedDestination {
        case .artists:
            ArtistsView()
        case .albums:
            AlbumsView()
        case .tracks:
            TracksView()
        case .playlists:
            PlaylistsView()
        case .nowPlaying:
            NowPlayingView(services: services)
        case .cdRipping:
            PlaceholderView(
                icon: "opticaldiscdrive",
                title: L10n.Navigation.cdRipping,
                message: L10n.Placeholders.cdRippingMessage
            )
        case .importFiles:
            PlaceholderView(
                icon: "square.and.arrow.down",
                title: L10n.Navigation.importFiles,
                message: L10n.Placeholders.importFilesMessage
            )
        case .preferences:
            PlaceholderView(
                icon: "gearshape",
                title: L10n.Navigation.preferences,
                message: L10n.Placeholders.preferencesMessage
            )
        case .apiServer:
            PlaceholderView(
                icon: "server.rack",
                title: L10n.Navigation.apiServer,
                message: L10n.Placeholders.apiServerMessage
            )
        }
    }

    @ViewBuilder
    private var detailColumn: some View {
        // Show detail based on selection state
        switch navigationState.selectedDestination {
        case .artists:
            if let album = navigationState.selectedAlbum {
                AlbumDetailView(album: album)
            } else if let artist = navigationState.selectedArtist {
                ArtistDetailView(artist: artist)
            } else {
                emptyDetailView(
                    icon: "music.mic",
                    message: L10n.Placeholders.selectArtistMessage
                )
            }

        case .albums:
            if let album = navigationState.selectedAlbum {
                AlbumDetailView(album: album)
            } else {
                emptyDetailView(
                    icon: "square.stack",
                    message: L10n.Placeholders.albumDetailMessage
                )
            }

        case .tracks, .playlists:
            emptyDetailView(
                icon: "music.note.list",
                message: L10n.Common.selectItem
            )

        case .nowPlaying:
            NowPlayingView(services: services)

        case .cdRipping, .importFiles, .preferences, .apiServer:
            // For placeholder views, show them in the detail column
            contentColumn
        }
    }

    private func emptyDetailView(icon: String, message: LocalizedStringKey) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 100)
    }
}

#Preview("Populated") {
    PreviewFactory.makeContentView(state: .populated)
}

#Preview("Empty") {
    PreviewFactory.makeContentView(state: .empty)
}
