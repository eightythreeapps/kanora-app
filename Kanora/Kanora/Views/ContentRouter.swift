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
        Group {
            // Check for artist/album selection first
            if destination == .artists, let album = navigationState.selectedAlbum {
                AlbumDetailView(album: album)
            } else if destination == .artists, let artist = navigationState.selectedArtist {
                ArtistDetailView(artist: artist)
            } else {
                // Default destination routing
                switch destination {
                case .artists:
                    emptySelection(icon: "music.mic", message: L10n.Placeholders.selectArtistMessage)
                case .albums:
                    AlbumsView()
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
        }
    }

    private func emptySelection(icon: String, message: LocalizedStringKey) -> some View {
        VStack(spacing: theme.spacing.lg) {
            Image(systemName: icon)
                .font(theme.typography.displaySmall)
                .foregroundColor(theme.colors.textSecondary)
            Text(message)
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
