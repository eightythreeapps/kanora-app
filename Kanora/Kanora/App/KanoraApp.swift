//
//  KanoraApp.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import SwiftUI
import CoreData

@main
struct KanoraApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        // Seed test data in debug mode
        #if DEBUG
        seedTestDataIfNeeded()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .designSystem()
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                // Replace default "New" command
            }

            CommandMenu(L10n.MenuCommands.library) {
                Button(L10n.MenuCommands.artists) {
                    NotificationCenter.default.post(name: .navigateToArtists, object: nil)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button(L10n.MenuCommands.albums) {
                    NotificationCenter.default.post(name: .navigateToAlbums, object: nil)
                }
                .keyboardShortcut("2", modifiers: .command)

                Button(L10n.MenuCommands.tracks) {
                    NotificationCenter.default.post(name: .navigateToTracks, object: nil)
                }
                .keyboardShortcut("3", modifiers: .command)

                Button(L10n.MenuCommands.playlists) {
                    NotificationCenter.default.post(name: .navigateToPlaylists, object: nil)
                }
                .keyboardShortcut("4", modifiers: .command)

                Divider()

                Button(L10n.MenuCommands.importFiles) {
                    NotificationCenter.default.post(name: .navigateToImport, object: nil)
                }
                .keyboardShortcut("i", modifiers: .command)
            }

            CommandMenu(L10n.MenuCommands.playback) {
                Button(L10n.MenuCommands.playPause) {
                    NotificationCenter.default.post(name: .togglePlayPause, object: nil)
                }
                .keyboardShortcut(.space, modifiers: [])

                Button(L10n.MenuCommands.nextTrack) {
                    NotificationCenter.default.post(name: .skipToNext, object: nil)
                }
                .keyboardShortcut(.rightArrow, modifiers: .command)

                Button(L10n.MenuCommands.previousTrack) {
                    NotificationCenter.default.post(name: .skipToPrevious, object: nil)
                }
                .keyboardShortcut(.leftArrow, modifiers: .command)

                Divider()

                Button(L10n.MenuCommands.increaseVolume) {
                    NotificationCenter.default.post(name: .volumeUp, object: nil)
                }
                .keyboardShortcut(.upArrow, modifiers: .command)

                Button(L10n.MenuCommands.decreaseVolume) {
                    NotificationCenter.default.post(name: .volumeDown, object: nil)
                }
                .keyboardShortcut(.downArrow, modifiers: .command)
            }
        }
    }

    // MARK: - Private Methods

    private func seedTestDataIfNeeded() {
        let context = persistenceController.container.viewContext

        // Check if data already exists
        let userRequest = User.fetchRequest()
        userRequest.predicate = NSPredicate(format: "username == %@", "TestUser")

        do {
            let existingUsers = try context.fetch(userRequest)
            if existingUsers.isEmpty {
                // No test data exists, seed it
                try TestDataSeeder.seedOasisDiscography(in: context)
            }
        } catch {
            // Log error but don't crash the app
            print("Error checking or seeding test data: \(error)")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToArtists = Notification.Name("navigateToArtists")
    static let navigateToAlbums = Notification.Name("navigateToAlbums")
    static let navigateToTracks = Notification.Name("navigateToTracks")
    static let navigateToPlaylists = Notification.Name("navigateToPlaylists")
    static let navigateToImport = Notification.Name("navigateToImport")
    static let togglePlayPause = Notification.Name("togglePlayPause")
    static let skipToNext = Notification.Name("skipToNext")
    static let skipToPrevious = Notification.Name("skipToPrevious")
    static let volumeUp = Notification.Name("volumeUp")
    static let volumeDown = Notification.Name("volumeDown")
}
