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
            detail: {
                contentColumn
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
            ImportFilesView(services: services)
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
        case .devTools:
            DevToolsView(services: services)
        }
    }

    private var fallbackLayout: some View {
        HStack(spacing: 0) {
            SidebarView(navigationState: navigationState, navigationMode: .split)

            Divider()

            contentColumn
        }
        .environment(\.managedObjectContext, viewContext)
        .environmentObject(navigationState)
    }

    // MARK: - Column Views

    @ViewBuilder
    private var contentColumn: some View {
        switch navigationState.selectedDestination {
        case .artists:
            if #available(iOS 16.0, macOS 13.0, *) {
                NavigationStack {
                    ArtistsView()
                        .navigationDestination(for: Artist.self) { artist in
                            ArtistDetailView(artist: artist)
                                .navigationDestination(for: Album.self) { album in
                                    AlbumDetailView(album: album)
                                }
                        }
                }
            } else {
                ArtistsView()
            }
        case .albums:
            if #available(iOS 16.0, macOS 13.0, *) {
                NavigationStack {
                    AlbumsView()
                        .navigationDestination(for: Album.self) { album in
                            AlbumDetailView(album: album)
                        }
                }
            } else {
                AlbumsView()
            }
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
            ImportFilesView(services: services)
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
        case .devTools:
            DevToolsView(services: services)
        }
    }
}

#Preview("Populated") {
    PreviewFactory.makeContentView(state: .populated)
}

#Preview("Empty") {
    PreviewFactory.makeContentView(state: .empty)
}
