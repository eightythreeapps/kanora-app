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
        let container = createContainer(for: state)
        return ContentView()
            .environment(\.managedObjectContext, container.viewContext)
            .designSystem()
    }

    /// Creates SidebarView with preview data
    static func makeSidebarView(state: PreviewState = .populated) -> some View {
        let container = createContainer(for: state)
        return SidebarView(navigationState: NavigationState())
            .environment(\.managedObjectContext, container.viewContext)
            .frame(width: 200)
            .designSystem()
    }

    // MARK: - Library Views

    /// Creates ArtistsView with preview data
    static func makeArtistsView(state: PreviewState = .populated) -> some View {
        let container = createContainer(for: state)
        return ArtistsView()
            .environment(\.managedObjectContext, container.viewContext)
            .designSystem()
    }

    /// Creates ArtistDetailView with preview data
    static func makeArtistDetailView(state: PreviewState = .populated) -> some View {
        let container = createContainer(for: state)
        let context = container.viewContext

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
            .designSystem()
    }

    /// Creates AlbumsView with preview data
    static func makeAlbumsView(state: PreviewState = .populated) -> some View {
        let container = createContainer(for: state)
        return AlbumsView()
            .environment(\.managedObjectContext, container.viewContext)
            .designSystem()
    }

    /// Creates AlbumDetailView with preview data
    static func makeAlbumDetailView(state: PreviewState = .populated) -> some View {
        let container = createContainer(for: state)
        let context = container.viewContext

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
            .designSystem()
    }

    /// Creates TracksView with preview data
    static func makeTracksView(state: PreviewState = .populated) -> some View {
        let container = createContainer(for: state)
        return TracksView()
            .environment(\.managedObjectContext, container.viewContext)
            .designSystem()
    }

    /// Creates PlaylistsView with preview data
    static func makePlaylistsView(state: PreviewState = .populated) -> some View {
        let container = createContainer(for: state)
        return PlaylistsView()
            .environment(\.managedObjectContext, container.viewContext)
            .designSystem()
    }

    // MARK: - Player Views

    /// Creates PlayerControlsView with preview data
    static func makePlayerControlsView(state: PreviewState = .populated) -> some View {
        let container = createContainer(for: state)
        let persistence = PersistenceController(inMemory: true)
        // Copy over the container we created
        let services = ServiceContainer(persistence: persistence)

        return PlayerControlsView(services: services)
            .environment(\.managedObjectContext, container.viewContext)
            .frame(height: 100)
            .designSystem()
    }

    /// Creates NowPlayingView with preview data
    static func makeNowPlayingView(state: PreviewState = .populated) -> some View {
        let container = createContainer(for: state)
        let persistence = PersistenceController(inMemory: true)
        let services = ServiceContainer(persistence: persistence)

        return NowPlayingView(services: services)
            .environment(\.managedObjectContext, container.viewContext)
            .designSystem()
    }

    // MARK: - Private Helpers

    /// Creates an in-memory Core Data container with test data based on state
    private static func createContainer(for state: PreviewState) -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "Kanora")

        // Configure in-memory store
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions = [description]

        // Load store
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Preview container failed to load: \(error.localizedDescription)")
            }
        }

        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Generate test data based on state
        generateTestData(for: state, in: container.viewContext)

        return container
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
            print("❌ Failed to save preview context: \(error)")
        }
    }

    // MARK: - Settings Views

    /// Creates DevToolsView with preview data
    static func makeDevToolsView(state: PreviewState = .populated) -> some View {
        let container = createContainer(for: state)
        let services = ServiceContainer(persistence: PersistenceController(inMemory: true))
        return DevToolsView(services: services)
            .environment(\.managedObjectContext, container.viewContext)
            .designSystem()
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
