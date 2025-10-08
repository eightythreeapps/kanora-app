//
//  L10n.swift
//  Kanora
//
//  Created by Ben Reed on 07/10/2025.
//

import Foundation
import SwiftUI

/// Centralized localization keys for the Kanora app.
/// All user-facing strings should be accessed through this enum to ensure consistency
/// and make localization management easier.
///
/// Usage:
/// ```swift
/// Text(L10n.Player.play)
/// Button(L10n.Actions.save) { ... }
/// ```
enum L10n {

    // MARK: - Helpers

    private static func localizedString(forKey key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // MARK: - Actions

    /// Common action strings used throughout the app
    enum Actions {
        static let play = LocalizedStringKey("actions.play")
        static let pause = LocalizedStringKey("actions.pause")
        static let stop = LocalizedStringKey("actions.stop")
        static let skip = LocalizedStringKey("actions.skip")
        static let previous = LocalizedStringKey("actions.previous")
        static let next = LocalizedStringKey("actions.next")
        static let shuffle = LocalizedStringKey("actions.shuffle")
        static let repeatAction = LocalizedStringKey("actions.repeat")
        static let add = LocalizedStringKey("actions.add")
        static let remove = LocalizedStringKey("actions.remove")
        static let delete = LocalizedStringKey("actions.delete")
        static let edit = LocalizedStringKey("actions.edit")
        static let save = LocalizedStringKey("actions.save")
        static let cancel = LocalizedStringKey("actions.cancel")
        static let done = LocalizedStringKey("actions.done")
        static let close = LocalizedStringKey("actions.close")
        static let search = LocalizedStringKey("actions.search")
        static let filter = LocalizedStringKey("actions.filter")
        static let sort = LocalizedStringKey("actions.sort")
        static let refresh = LocalizedStringKey("actions.refresh")
        static let clear = LocalizedStringKey("actions.clear")
        static let select = LocalizedStringKey("actions.select")
        static let selectAll = LocalizedStringKey("actions.select_all")
        static let deselectAll = LocalizedStringKey("actions.deselect_all")
        static let importAction = LocalizedStringKey("actions.import")
        static let export = LocalizedStringKey("actions.export")
        static let share = LocalizedStringKey("actions.share")
        static let copy = LocalizedStringKey("actions.copy")
        static let paste = LocalizedStringKey("actions.paste")
        static let duplicate = LocalizedStringKey("actions.duplicate")
    }

    // MARK: - Navigation

    /// Navigation-related strings for sidebar and menu items
    enum Navigation {
        // Main sections
        static let library = LocalizedStringKey("navigation.library")
        static let media = LocalizedStringKey("navigation.media")
        static let settings = LocalizedStringKey("navigation.settings")

        // Library items
        static let artists = LocalizedStringKey("navigation.artists")
        static let albums = LocalizedStringKey("navigation.albums")
        static let tracks = LocalizedStringKey("navigation.tracks")
        static let playlists = LocalizedStringKey("navigation.playlists")
        static let genres = LocalizedStringKey("navigation.genres")

        // Media items
        static let cdRipping = LocalizedStringKey("navigation.cd_ripping")
        static let importFiles = LocalizedStringKey("navigation.import_files")

        // Settings items
        static let preferences = LocalizedStringKey("navigation.preferences")
        static let apiServer = LocalizedStringKey("navigation.api_server")
        static let about = LocalizedStringKey("navigation.about")

        // Development items
        static let development = LocalizedStringKey("navigation.development")
        static let devTools = LocalizedStringKey("navigation.dev_tools")
    }

    // MARK: - Player

    /// Player-related strings
    enum Player {
        static let nowPlaying = LocalizedStringKey("player.now_playing")
        static let upNext = LocalizedStringKey("player.up_next")
        static let queue = LocalizedStringKey("player.queue")
        static let volume = LocalizedStringKey("player.volume")
        static let mute = LocalizedStringKey("player.mute")
        static let unmute = LocalizedStringKey("player.unmute")
        static let shuffleOn = LocalizedStringKey("player.shuffle_on")
        static let shuffleOff = LocalizedStringKey("player.shuffle_off")
        static let repeatOff = LocalizedStringKey("player.repeat_off")
        static let repeatAll = LocalizedStringKey("player.repeat_all")
        static let repeatOne = LocalizedStringKey("player.repeat_one")
        static let addToQueue = LocalizedStringKey("player.add_to_queue")
        static let playNext = LocalizedStringKey("player.play_next")
        static let clearQueue = LocalizedStringKey("player.clear_queue")
        static let noTrackPlaying = LocalizedStringKey("player.no_track_playing")
        static let selectTrackToPlay = LocalizedStringKey("player.select_track_to_play")
        static let queuePlaceholderArtist = LocalizedStringKey("player.queue.placeholder_artist")
        static let queuePlaceholderTitle: (Int) -> LocalizedStringKey = { index in
            LocalizedStringKey("player.queue.placeholder_title \(index)")
        }

        static func queuePlaceholderArtistName() -> String {
            L10n.localizedString(forKey: "player.queue.placeholder_artist")
        }

        static func queuePlaceholderTitleName(_ index: Int) -> String {
            String(localized: "player.queue.placeholder_title \(index)")
        }
    }

    // MARK: - Library

    /// Library view strings
    enum Library {
        // Artists
        static let artistsTitle = LocalizedStringKey("library.artists.title")
        static let artistsEmpty = LocalizedStringKey("library.artists.empty")
        static let artistsEmptyMessage = LocalizedStringKey("library.artists.empty_message")
        static let artistCount: (Int) -> LocalizedStringKey = { count in
            LocalizedStringKey("library.artists.count \(count)")
        }

        // Albums
        static let albumsTitle = LocalizedStringKey("library.albums.title")
        static let albumsEmpty = LocalizedStringKey("library.albums.empty")
        static let albumsEmptyMessage = LocalizedStringKey("library.albums.empty_message")
        static let albumCount: (Int) -> LocalizedStringKey = { count in
            LocalizedStringKey("library.albums.count \(count)")
        }

        // Tracks
        static let tracksTitle = LocalizedStringKey("library.tracks.title")
        static let tracksEmpty = LocalizedStringKey("library.tracks.empty")
        static let tracksEmptyMessage = LocalizedStringKey("library.tracks.empty_message")
        static let trackCount: (Int) -> LocalizedStringKey = { count in
            LocalizedStringKey("library.tracks.count \(count)")
        }

        // Playlists
        static let playlistsTitle = LocalizedStringKey("library.playlists.title")
        static let playlistsEmpty = LocalizedStringKey("library.playlists.empty")
        static let playlistsEmptyMessage = LocalizedStringKey("library.playlists.empty_message")
        static let playlistCount: (Int) -> LocalizedStringKey = { count in
            LocalizedStringKey("library.playlists.count \(count)")
        }
        static let createPlaylist = LocalizedStringKey("library.playlists.create")
        static let newPlaylist = LocalizedStringKey("library.playlists.new")

        // Search
        static let searchArtists = LocalizedStringKey("library.search.artists")
        static let searchAlbums = LocalizedStringKey("library.search.albums")
        static let searchTracks = LocalizedStringKey("library.search.tracks")
        static let searchPlaylists = LocalizedStringKey("library.search.playlists")
        static let noResults = LocalizedStringKey("library.search.no_results")

        // Common
        static let unknownLibrary = LocalizedStringKey("library.unknown")
        static let unknownArtist = LocalizedStringKey("library.unknown_artist")
        static let unknownAlbum = LocalizedStringKey("library.unknown_album")
        static let unknownTrack = LocalizedStringKey("library.unknown_track")
        static let duration = LocalizedStringKey("library.duration")

        static var unknownLibraryName: String {
            L10n.localizedString(forKey: "library.unknown")
        }

        static var unknownArtistName: String {
            L10n.localizedString(forKey: "library.unknown_artist")
        }

        static var unknownAlbumName: String {
            L10n.localizedString(forKey: "library.unknown_album")
        }

        static var unknownTrackName: String {
            L10n.localizedString(forKey: "library.unknown_track")
        }
    }

    // MARK: - Forms

    /// Form-related strings
    enum Forms {
        static let required = LocalizedStringKey("forms.required")
        static let optional = LocalizedStringKey("forms.optional")
        static let name = LocalizedStringKey("forms.name")
        static let title = LocalizedStringKey("forms.title")
        static let description = LocalizedStringKey("forms.description")
        static let artist = LocalizedStringKey("forms.artist")
        static let album = LocalizedStringKey("forms.album")
        static let genre = LocalizedStringKey("forms.genre")
        static let year = LocalizedStringKey("forms.year")
        static let trackNumber = LocalizedStringKey("forms.track_number")
        static let discNumber = LocalizedStringKey("forms.disc_number")
        static let artwork = LocalizedStringKey("forms.artwork")
    }

    // MARK: - Errors

    /// Error messages
    enum Errors {
        static let generic = LocalizedStringKey("errors.generic")
        static let networkError = LocalizedStringKey("errors.network")
        static let fileNotFound = LocalizedStringKey("errors.file_not_found")
        static let importFailed = LocalizedStringKey("errors.import_failed")
        static let playbackFailed = LocalizedStringKey("errors.playback_failed")
        static let saveFailed = LocalizedStringKey("errors.save_failed")
        static let deleteFailed = LocalizedStringKey("errors.delete_failed")
        static let loadFailed = LocalizedStringKey("errors.load_failed")
        static let invalidFormat = LocalizedStringKey("errors.invalid_format")
        static let permissionDenied = LocalizedStringKey("errors.permission_denied")
        static let noUserFound = LocalizedStringKey("errors.no_user_found")
        static let noLibrarySelected = LocalizedStringKey("errors.no_library_selected")
        static let failedToLoadLibraries = LocalizedStringKey("errors.failed_to_load_libraries")
        static let libraryNotFound = LocalizedStringKey("errors.library_not_found")
        static let invalidPath = LocalizedStringKey("errors.invalid_path")

        static var noUserFoundMessage: String {
            L10n.localizedString(forKey: "errors.no_user_found")
        }

        static var noLibrarySelectedMessage: String {
            L10n.localizedString(forKey: "errors.no_library_selected")
        }

        static var failedToLoadLibrariesMessage: String {
            L10n.localizedString(forKey: "errors.failed_to_load_libraries")
        }

        static var libraryNotFoundMessage: String {
            L10n.localizedString(forKey: "errors.library_not_found")
        }

        static var invalidPathMessage: String {
            L10n.localizedString(forKey: "errors.invalid_path")
        }

        static var invalidFormatMessage: String {
            L10n.localizedString(forKey: "errors.invalid_format")
        }
    }

    // MARK: - Preferences

    /// Preferences/Settings strings
    enum Preferences {
        static let title = LocalizedStringKey("preferences.title")
        static let general = LocalizedStringKey("preferences.general")
        static let playback = LocalizedStringKey("preferences.playback")
        static let library = LocalizedStringKey("preferences.library")
        static let network = LocalizedStringKey("preferences.network")
        static let advanced = LocalizedStringKey("preferences.advanced")

        // General
        static let appearance = LocalizedStringKey("preferences.appearance")
        static let theme = LocalizedStringKey("preferences.theme")
        static let language = LocalizedStringKey("preferences.language")

        // Playback
        static let audioQuality = LocalizedStringKey("preferences.audio_quality")
        static let crossfade = LocalizedStringKey("preferences.crossfade")
        static let gaplessPlayback = LocalizedStringKey("preferences.gapless_playback")
        static let replayGain = LocalizedStringKey("preferences.replay_gain")

        // Library
        static let musicFolder = LocalizedStringKey("preferences.music_folder")
        static let organizeFiles = LocalizedStringKey("preferences.organize_files")
        static let importSettings = LocalizedStringKey("preferences.import_settings")
    }

    // MARK: - Import

    /// Import/CD Ripping strings
    enum Import {
        // File import
        static let selectFiles = LocalizedStringKey("import.select_files")
        static let selectFolder = LocalizedStringKey("import.select_folder")
        static let importing = LocalizedStringKey("import.importing")
        static let importComplete: (Int) -> LocalizedStringKey = { count in
            LocalizedStringKey("import.complete \(count)")
        }
        static let filesImported: (Int) -> LocalizedStringKey = { count in
            LocalizedStringKey("import.files_imported \(count)")
        }
        static let filesSelected: (Int) -> LocalizedStringKey = { count in
            LocalizedStringKey("import.files_selected \(count)")
        }
        static let invalidFilesSkipped: (Int) -> LocalizedStringKey = { count in
            LocalizedStringKey("import.invalid_files_skipped \(count)")
        }
        static let noLibrarySelected = LocalizedStringKey("import.no_library_selected")
        static let dropFilesHere = LocalizedStringKey("import.drop_files_here")
        static let selectLibrary = LocalizedStringKey("import.select_library")
        static let startImport = LocalizedStringKey("import.start_import")
        static let clearSelection = LocalizedStringKey("import.clear_selection")
        static let chooseMethod = LocalizedStringKey("import.choose_method")
        static let supportedFormats = LocalizedStringKey("import.supported_formats")
        static let selectFilesPrompt = LocalizedStringKey("import.select_files_prompt")
        static let noFilesSelected = LocalizedStringKey("import.no_files_selected")
        static let noDirectorySelected = LocalizedStringKey("import.no_directory_selected")
        static let libraryPointSuccess: (String) -> LocalizedStringKey = { name in
            LocalizedStringKey("import.library_point_success \(name)")
        }
        static let progressFraction: (Int, Int) -> LocalizedStringKey = { processed, total in
            LocalizedStringKey("import.progress_fraction \(processed) \(total)")
        }

        // Status messages
        static let preparing = LocalizedStringKey("import.preparing")
        static let importingFiles = LocalizedStringKey("import.importing_files")
        static let importingFile: (String) -> LocalizedStringKey = { file in
            LocalizedStringKey("import.importing_file \(file)")
        }
        static let extractingMetadata = LocalizedStringKey("import.extracting_metadata")
        static let copyingFiles = LocalizedStringKey("import.copying_files")

        enum Mode {
            static let addToKanoraTitle = LocalizedStringKey("import.mode.add_to_kanora.title")
            static let addToKanoraDescription = LocalizedStringKey("import.mode.add_to_kanora.description")
            static let pointAtDirectoryTitle = LocalizedStringKey("import.mode.point_at_directory.title")
            static let pointAtDirectoryDescription = LocalizedStringKey("import.mode.point_at_directory.description")

            static func displayNameString(for mode: ImportMode) -> String {
                switch mode {
                case .addToKanora:
                    return L10n.localizedString(forKey: "import.mode.add_to_kanora.title")
                case .pointAtDirectory:
                    return L10n.localizedString(forKey: "import.mode.point_at_directory.title")
                }
            }

            static func descriptionString(for mode: ImportMode) -> String {
                switch mode {
                case .addToKanora:
                    return L10n.localizedString(forKey: "import.mode.add_to_kanora.description")
                case .pointAtDirectory:
                    return L10n.localizedString(forKey: "import.mode.point_at_directory.description")
                }
            }
        }

        static func selectFilesPromptText() -> String {
            L10n.localizedString(forKey: "import.select_files_prompt")
        }

        static func filesSelectedText(_ count: Int) -> String {
            String(localized: "import.files_selected \(count)")
        }

        static func filesImportedText(_ count: Int) -> String {
            String(localized: "import.files_imported \(count)")
        }

        static func invalidFilesSkippedText(_ count: Int) -> String {
            String(localized: "import.invalid_files_skipped \(count)")
        }

        static func noFilesSelectedText() -> String {
            L10n.localizedString(forKey: "import.no_files_selected")
        }

        static func noDirectorySelectedText() -> String {
            L10n.localizedString(forKey: "import.no_directory_selected")
        }

        static func importingFileText(_ file: String) -> String {
            String(localized: "import.importing_file \(file)")
        }

        static func importingFilesText() -> String {
            L10n.localizedString(forKey: "import.importing_files")
        }

        static func preparingText() -> String {
            L10n.localizedString(forKey: "import.preparing")
        }

        static func extractingMetadataText() -> String {
            L10n.localizedString(forKey: "import.extracting_metadata")
        }

        static func copyingFilesText() -> String {
            L10n.localizedString(forKey: "import.copying_files")
        }

        static func libraryPointSuccessText(_ name: String) -> String {
            String(localized: "import.library_point_success \(name)")
        }

        static func progressFractionText(processed: Int, total: Int) -> String {
            String(localized: "import.progress_fraction \(processed) \(total)")
        }

        // CD Ripping
        static let cdRipping = LocalizedStringKey("import.cd_ripping")
        static let insertCD = LocalizedStringKey("import.insert_cd")
        static let detectingCD = LocalizedStringKey("import.detecting_cd")
        static let lookupMetadata = LocalizedStringKey("import.lookup_metadata")
        static let startRipping = LocalizedStringKey("import.start_ripping")
        static let rippingInProgress = LocalizedStringKey("import.ripping_in_progress")
        static let ripComplete = LocalizedStringKey("import.rip_complete")
    }

    // MARK: - Dialogs

    /// Dialog and alert strings
    enum Dialogs {
        static let confirm = LocalizedStringKey("dialogs.confirm")
        static let warning = LocalizedStringKey("dialogs.warning")
        static let info = LocalizedStringKey("dialogs.info")
        static let deleteConfirm = LocalizedStringKey("dialogs.delete_confirm")
        static let deleteMessage: (String) -> LocalizedStringKey = { item in
            LocalizedStringKey("dialogs.delete_message \(item)")
        }
        static let unsavedChanges = LocalizedStringKey("dialogs.unsaved_changes")
        static let unsavedChangesMessage = LocalizedStringKey("dialogs.unsaved_changes_message")
    }

    // MARK: - Time

    /// Time-related strings
    enum Time {
        static let seconds = LocalizedStringKey("time.seconds")
        static let minutes = LocalizedStringKey("time.minutes")
        static let hours = LocalizedStringKey("time.hours")
        static let days = LocalizedStringKey("time.days")

        static func duration(hours: Int, minutes: Int, seconds: Int) -> String {
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%d:%02d", minutes, seconds)
            }
        }
    }

    // MARK: - About

    /// About section strings
    enum About {
        static let version = LocalizedStringKey("about.version")
        static let build = LocalizedStringKey("about.build")
        static let copyright = LocalizedStringKey("about.copyright")
        static let acknowledgments = LocalizedStringKey("about.acknowledgments")
        static let website = LocalizedStringKey("about.website")
        static let support = LocalizedStringKey("about.support")
    }

    // MARK: - Placeholders

    /// Placeholder messages for unimplemented features
    enum Placeholders {
        static let comingSoon = LocalizedStringKey("placeholders.coming_soon")
        static let cdRippingMessage = LocalizedStringKey("placeholders.cd_ripping_message")
        static let importFilesMessage = LocalizedStringKey("placeholders.import_files_message")
        static let preferencesMessage = LocalizedStringKey("placeholders.preferences_message")
        static let apiServerMessage = LocalizedStringKey("placeholders.api_server_message")
        static let artistDetailMessage = LocalizedStringKey("placeholders.artist_detail_message")
        static let albumDetailMessage = LocalizedStringKey("placeholders.album_detail_message")
        static let playlistDetailMessage = LocalizedStringKey("placeholders.playlist_detail_message")
        static let selectArtistMessage = LocalizedStringKey("placeholders.select_artist_message")
    }

    // MARK: - Common

    /// Common UI strings
    enum Common {
        static let appName = LocalizedStringKey("common.app_name")
        static let selectItem = LocalizedStringKey("common.select_item")
    }

    // MARK: - Table Columns

    /// Table column headers
    enum TableColumns {
        static let number = LocalizedStringKey("table.column.number")
        static let title = LocalizedStringKey("table.column.title")
        static let artist = LocalizedStringKey("table.column.artist")
        static let album = LocalizedStringKey("table.column.album")
        static let duration = LocalizedStringKey("table.column.duration")
    }

    // MARK: - Menu Commands

    /// Menu command labels
    enum MenuCommands {
        static let library = LocalizedStringKey("menu.library")
        static let playback = LocalizedStringKey("menu.playback")
        static let artists = LocalizedStringKey("menu.artists")
        static let albums = LocalizedStringKey("menu.albums")
        static let tracks = LocalizedStringKey("menu.tracks")
        static let playlists = LocalizedStringKey("menu.playlists")
        static let importFiles = LocalizedStringKey("menu.import_files")
        static let playPause = LocalizedStringKey("menu.play_pause")
        static let nextTrack = LocalizedStringKey("menu.next_track")
        static let previousTrack = LocalizedStringKey("menu.previous_track")
        static let increaseVolume = LocalizedStringKey("menu.increase_volume")
        static let decreaseVolume = LocalizedStringKey("menu.decrease_volume")
    }

    // MARK: - Development

    /// Development tools strings
    enum Development {
        static let title = LocalizedStringKey("development.title")
        static let clearAllData = LocalizedStringKey("development.clear_all_data")
        static let clearAllDataDescription = LocalizedStringKey("development.clear_all_data_description")
        static let clearDataConfirm = LocalizedStringKey("development.clear_data_confirm")
        static let clearDataWarning = LocalizedStringKey("development.clear_data_warning")
        static let dataCleared = LocalizedStringKey("development.data_cleared")
        static let clearDataFailed = LocalizedStringKey("development.clear_data_failed")
    }
}
