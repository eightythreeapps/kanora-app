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
        // Ensure default user and library exist
        ensureDefaultData()
    }

    private func ensureDefaultData() {
        let context = persistenceController.container.viewContext

        // Check if any users exist
        let userRequest = User.fetchRequest()
        userRequest.fetchLimit = 1

        do {
            let existingUsers = try context.fetch(userRequest)
            if existingUsers.isEmpty {
                // No users exist, create default user and library
                try persistenceController.createDefaultUserAndLibrary()
            }
        } catch {
            AppLogger.appLifecycle.warning("⚠️ Error checking/creating default data: \(error)")
        }
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
