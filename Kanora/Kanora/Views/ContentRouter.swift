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
    let services: ServiceContainer
    @ObservedObject var navigationState: NavigationState

    init(destination: NavigationDestination, services: ServiceContainer, navigationState: NavigationState) {
        self.destination = destination
        self.services = services
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
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Placeholder view for unimplemented features
struct PlaceholderView: View {
    let icon: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text(title)
                .font(.title)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(title)
    }
}

#Preview("Artists") {
    let persistence = PersistenceController.preview
    let services = ServiceContainer(persistence: persistence)
    let navigationState = NavigationState()
    let playerViewModel = PlayerViewModel(
        context: services.persistence.viewContext,
        services: services
    )
    return NavigationView {
        ContentRouter(destination: .artists, services: services, navigationState: navigationState)
    }
    .environment(\.managedObjectContext, services.persistence.viewContext)
    .environmentObject(navigationState)
    .environmentObject(playerViewModel)
}

#Preview("Placeholder") {
    let persistence = PersistenceController.preview
    let services = ServiceContainer(persistence: persistence)
    let navigationState = NavigationState()
    let playerViewModel = PlayerViewModel(
        context: services.persistence.viewContext,
        services: services
    )
    return NavigationView {
        ContentRouter(destination: .cdRipping, services: services, navigationState: navigationState)
    }
    .environment(\.managedObjectContext, services.persistence.viewContext)
    .environmentObject(navigationState)
    .environmentObject(playerViewModel)
}
