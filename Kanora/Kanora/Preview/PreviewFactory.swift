//
//  PreviewFactory.swift
//  Kanora
//
//  Created by Ben Reed on 07/10/2025.
//

import CoreData
import SwiftUI

/// Factory for creating SwiftUI previews with proper environment setup.
/// All factory methods create in-memory Core Data containers and inject
/// appropriate test data based on the preview state.
///
/// Usage:
/// ```swift
/// #Preview("Populated State") {
///     PreviewFactory.makeArtistsView(state: .populated)
/// }
///
/// #Preview("Empty State") {
///     PreviewFactory.makeArtistsView(state: .empty)
/// }
/// ```
struct PreviewFactory {

    // MARK: - Main App Views

    /// Creates ContentView with preview data
    static func makeContentView(state: PreviewState = .populated) -> some View {
        let services = makeServices(for: state)
        return ContentView(services: services)
            .environment(\.managedObjectContext, services.persistence.viewContext)
            .designSystem()
    }

    /// Creates SidebarView with preview data
    static func makeSidebarView(state: PreviewState = .populated) -> some View {
        let services = makeServices(for: state)
        let playerViewModel = makePlayerViewModel(for: services)
        return SidebarView(navigationState: NavigationState())
            .environment(\.managedObjectContext, services.persistence.viewContext)
            .environmentObject(playerViewModel)
            .frame(width: 200)
            .designSystem()
    }

    // MARK: - Library Views

    /// Creates ArtistsView with preview data
    static func makeArtistsView(state: PreviewState = .populated) -> some View {
        let services = makeServices(for: state)
        let playerViewModel = makePlayerViewModel(for: services)
        return ArtistsView()
            .environment(\.managedObjectContext, services.persistence.viewContext)
            .environmentObject(playerViewModel)
            .designSystem()
    }

    /// Creates ArtistDetailView with preview data
    static func makeArtistDetailView(state: PreviewState = .populated) -> some View {
        let services = makeServices(for: state)
        let context = services.persistence.viewContext
        let playerViewModel = makePlayerViewModel(for: services)

        // Fetch first artist
        let fetchRequest = Artist.fetchRequest()
        fetchRequest.fetchLimit = 1
        let artist = (try? context.fetch(fetchRequest))?.first ?? Artist(
            name: "Sample Artist",
            library: Library(name: "Sample", path: "/", user: User(username: "test", context: context), context: context),
            context: context
        )

        return ArtistDetailView(artist: artist)
            .environment(\.managedObjectContext, context)
            .environmentObject(playerViewModel)
            .designSystem()
    }

    /// Creates AlbumsView with preview data
    static func makeAlbumsView(state: PreviewState = .populated) -> some View {
        let services = makeServices(for: state)
        let playerViewModel = makePlayerViewModel(for: services)
        return AlbumsView()
            .environment(\.managedObjectContext, services.persistence.viewContext)
            .environmentObject(playerViewModel)
            .designSystem()
    }

    /// Creates AlbumDetailView with preview data
    static func makeAlbumDetailView(state: PreviewState = .populated) -> some View {
        let services = makeServices(for: state)
        let context = services.persistence.viewContext
        let playerViewModel = makePlayerViewModel(for: services)

        // Fetch first album
        let fetchRequest = Album.fetchRequest()
        fetchRequest.fetchLimit = 1
        let album = (try? context.fetch(fetchRequest))?.first ?? Album(
            title: "Sample Album",
            artist: Artist(
                name: "Sample Artist",
                library: Library(name: "Sample", path: "/", user: User(username: "test", context: context), context: context),
                context: context
            ),
            year: 2024,
            context: context
        )

        return AlbumDetailView(album: album)
            .environment(\.managedObjectContext, context)
            .environmentObject(playerViewModel)
            .designSystem()
    }

    /// Creates TracksView with preview data
    static func makeTracksView(state: PreviewState = .populated) -> some View {
        let services = makeServices(for: state)
        let playerViewModel = makePlayerViewModel(for: services)
        return TracksView()
            .environment(\.managedObjectContext, services.persistence.viewContext)
            .environmentObject(playerViewModel)
            .designSystem()
    }

    /// Creates PlaylistsView with preview data
    static func makePlaylistsView(state: PreviewState = .populated) -> some View {
        let services = makeServices(for: state)
        let playerViewModel = makePlayerViewModel(for: services)
        return PlaylistsView()
            .environment(\.managedObjectContext, services.persistence.viewContext)
            .environmentObject(playerViewModel)
            .designSystem()
    }

    // MARK: - Player Views

    /// Creates PlayerControlsView with preview data
    static func makePlayerControlsView(state: PreviewState = .populated) -> some View {
        let services = makeServices(for: state)
        let playerViewModel = makePlayerViewModel(for: services)
        return PlayerControlsView()
            .environment(\.managedObjectContext, services.persistence.viewContext)
            .environmentObject(playerViewModel)
            .frame(height: 100)
            .designSystem()
    }

    /// Creates NowPlayingView with preview data
    static func makeNowPlayingView(state: PreviewState = .populated) -> some View {
        let services = makeServices(for: state)
        let playerViewModel = makePlayerViewModel(for: services)
        return NowPlayingView()
            .environment(\.managedObjectContext, services.persistence.viewContext)
            .environmentObject(playerViewModel)
            .designSystem()
    }

    // MARK: - Settings Views

    /// Creates DevToolsView with preview data
    static func makeDevToolsView(state: PreviewState = .populated) -> some View {
        let services = makeServices(for: state)
        let playerViewModel = makePlayerViewModel(for: services)
        return DevToolsView(services: services)
            .environment(\.managedObjectContext, services.persistence.viewContext)
            .environmentObject(playerViewModel)
            .designSystem()
    }

    /// Provides shared preview dependencies for manual previews
    static func makePreviewDependencies(state: PreviewState = .populated) -> (services: ServiceContainer, playerViewModel: PlayerViewModel) {
        let services = makeServices(for: state)
        let playerViewModel = makePlayerViewModel(for: services)
        return (services, playerViewModel)
    }

    // MARK: - Private Helpers

    private static func makeServices(for state: PreviewState) -> ServiceContainer {
        let persistence = PersistenceController(inMemory: true)
        let services = ServiceContainer(persistence: persistence)
        generateTestData(for: state, in: persistence.viewContext)
        return services
    }

    private static func makePlayerViewModel(for services: ServiceContainer) -> PlayerViewModel {
        PlayerViewModel(
            context: services.persistence.viewContext,
            services: services
        )
    }

    /// Generates test data in the given context based on preview state
    private static func generateTestData(for state: PreviewState, in context: NSManagedObjectContext) {
        // Create data graph using TestDataBuilder
        _ = TestDataBuilder.createDataGraph(for: state, in: context)

        // For populated, loading, and error states, add playlists with tracks
        if state == .populated || state == .loading || state == .error {
            // Fetch some tracks to add to playlists
            let trackFetchRequest = Track.fetchRequest()
            trackFetchRequest.fetchLimit = 10
            let tracks = (try? context.fetch(trackFetchRequest)) ?? []

            // Get playlists
            let playlistFetchRequest = Playlist.fetchRequest()
            let playlists = (try? context.fetch(playlistFetchRequest)) ?? []

            // Add tracks to first playlist if available
            if let firstPlaylist = playlists.first, !tracks.isEmpty {
                for (index, track) in tracks.prefix(5).enumerated() {
                    let item = PlaylistItem(context: context)
                    item.id = UUID()
                    item.position = Int32(index)
                    item.addedAt = Date()
                    item.playlist = firstPlaylist
                    item.track = track
                }
            }
        }

        // Save context
        do {
            try context.save()
        } catch {
            AppLogger.preview.error("❌ Failed to save preview context: \(error)")
        }
    }
}

// MARK: - Preview Helpers

extension PreviewFactory {
    /// Creates a preview with all states for a view
    /// Use this to easily generate multiple preview states
    static func makeStatesPreview<Content: View>(
        _ viewBuilder: @escaping (PreviewState) -> Content
    ) -> some View {
        Group {
            viewBuilder(.empty)
                .previewDisplayName("Empty")

            viewBuilder(.populated)
                .previewDisplayName("Populated")

            viewBuilder(.loading)
                .previewDisplayName("Loading")

            viewBuilder(.error)
                .previewDisplayName("Error")
        }
    }
}
