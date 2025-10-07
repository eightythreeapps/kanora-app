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

    var body: some View {
        switch destination {
        case .artists:
            ArtistsView()
        case .albums:
            AlbumsView()
        case .tracks:
            TracksView()
        case .playlists:
            PlaylistsView()
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
    NavigationView {
        ContentRouter(destination: .artists)
    }
}

#Preview("Placeholder") {
    NavigationView {
        ContentRouter(destination: .cdRipping)
    }
}
