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
    @StateObject private var navigationState = NavigationState()
    private let services = ServiceContainer.shared

    var body: some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            NavigationSplitView {
                SidebarView(navigationState: navigationState)
                    .navigationDestination(for: NavigationDestination.self) { destination in
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
            } detail: {
                VStack(spacing: 0) {
                    ContentRouter(destination: navigationState.selectedDestination)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Divider()

                    PlayerControlsView(services: services)
                }
            }
            .environment(\.managedObjectContext, viewContext)
        } else {
            NavigationView {
                SidebarView(navigationState: navigationState)
                VStack(spacing: 0) {
                    ContentRouter(destination: navigationState.selectedDestination)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Divider()

                    PlayerControlsView(services: services)
                }
            }
            .environment(\.managedObjectContext, viewContext)
            
        }
    }
}

#Preview("Populated") {
    PreviewFactory.makeContentView(state: .populated)
}

#Preview("Empty") {
    PreviewFactory.makeContentView(state: .empty)
}
