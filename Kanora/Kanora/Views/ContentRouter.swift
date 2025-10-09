//
//  ContentRouter.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import SwiftUI

/// Routes navigation destinations to appropriate views
struct ContentRouter: View {
    let destination: NavigationDestination
    @Environment(\.serviceContainer) private var services
    @ObservedObject var navigationState: NavigationState
    @ThemeAccess private var theme

    init(destination: NavigationDestination, navigationState: NavigationState) {
        self.destination = destination
        self.navigationState = navigationState
    }

    var body: some View {
        routedView(for: destination)
    }

    @ViewBuilder
    private func routedView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .artists:
            artistsDestination()
        case .albums:
            albumsDestination()
        case .tracks:
            TracksView()
        case .playlists:
            PlaylistsView()
        case .nowPlaying:
            NowPlayingView()
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

    @ViewBuilder
    private func artistsDestination() -> some View {
        if let album = navigationState.selectedAlbum {
            AlbumDetailView(album: album)
        } else if let artist = navigationState.selectedArtist {
            ArtistDetailView(artist: artist)
        } else {
            artistsRootView()
        }
    }

    @ViewBuilder
    private func albumsDestination() -> some View {
        if let album = navigationState.selectedAlbum, destination == .albums {
            AlbumDetailView(album: album)
        } else {
            albumsRootView()
        }
    }

    @ViewBuilder
    private func artistsRootView() -> some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            ArtistsView()
                .navigationDestination(for: Artist.self) { artist in
                    ArtistDetailView(artist: artist)
                }
                .navigationDestination(for: Album.self) { album in
                    AlbumDetailView(album: album)
                }
        } else {
            ArtistsView()
        }
    }

    @ViewBuilder
    private func albumsRootView() -> some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            AlbumsView()
                .navigationDestination(for: Album.self) { album in
                    AlbumDetailView(album: album)
                }
        } else {
            AlbumsView()
        }
    }
}

/// Placeholder view for unimplemented features
struct PlaceholderView: View {
    let icon: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    @ThemeAccess private var theme

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            Image(systemName: icon)
                .font(theme.typography.displaySmall)
                .foregroundColor(theme.colors.textSecondary)
            Text(title)
                .font(theme.typography.titleLarge)
                .foregroundColor(theme.colors.textPrimary)
            Text(message)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(title)
    }
}

#Preview("Artists") {
    let dependencies = PreviewFactory.makePreviewDependencies()
    let navigationState = NavigationState()
    return NavigationView {
        ContentRouter(destination: .artists, navigationState: navigationState)
    }
    .environment(\.managedObjectContext, dependencies.services.persistence.viewContext)
    .environment(\.serviceContainer, dependencies.services)
    .environmentObject(navigationState)
    .environmentObject(dependencies.playerViewModel)
    .designSystem()
}

#Preview("Placeholder") {
    let dependencies = PreviewFactory.makePreviewDependencies()
    let navigationState = NavigationState()
    return NavigationView {
        ContentRouter(destination: .cdRipping, navigationState: navigationState)
    }
    .environment(\.managedObjectContext, dependencies.services.persistence.viewContext)
    .environment(\.serviceContainer, dependencies.services)
    .environmentObject(navigationState)
    .environmentObject(dependencies.playerViewModel)
    .designSystem()
}
