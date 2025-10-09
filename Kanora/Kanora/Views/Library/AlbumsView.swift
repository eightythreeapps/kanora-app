//
//  AlbumsView.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import SwiftUI
import Foundation
import CoreData

struct AlbumsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var navigationState: NavigationState
    @ThemeAccess private var theme

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Album.artist?.sortName, ascending: true),
            NSSortDescriptor(keyPath: \Album.title, ascending: true)
        ],
        animation: .default
    )
    private var albums: FetchedResults<Album>

    @State private var searchText = ""

    var filteredAlbums: [Album] {
        if searchText.isEmpty {
            return Array(albums)
        }
        return albums.filter { album in
            album.title?.localizedCaseInsensitiveContains(searchText) ?? false ||
            album.artist?.name?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    private var columns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: 150, maximum: 200),
                spacing: theme.spacing.md
            )
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            LibrarySearchBar(
                placeholder: L10n.Library.searchAlbums,
                text: $searchText,
                accessibilityLabel: L10n.Library.searchAlbums,
                textFieldIdentifier: "albums-search-field",
                clearButtonIdentifier: "albums-search-clear"
            )

            // Albums grid
            if filteredAlbums.isEmpty {
                Spacer()
                VStack(spacing: theme.spacing.sm) {
                    Image(systemName: "square.stack")
                        .font(theme.typography.headlineMedium)
                        .foregroundStyle(theme.colors.textSecondary)
                    Text(searchText.isEmpty ? L10n.Library.albumsEmpty : L10n.Library.noResults)
                        .font(theme.typography.titleSmall)
                        .foregroundStyle(theme.colors.textSecondary)
                    if searchText.isEmpty {
                        Text(L10n.Library.albumsEmptyMessage)
                            .font(theme.typography.bodySmall)
                            .foregroundStyle(theme.colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: theme.spacing.md) {
                        ForEach(filteredAlbums) { album in
                            if #available(iOS 16.0, macOS 13.0, *) {
                                NavigationLink(value: album) {
                                    AlbumGridItem(album: album)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button(action: {
                                    navigationState.selectAlbum(album)
                                }) {
                                    AlbumGridItem(album: album)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(theme.spacing.md)
                    .padding(.bottom, theme.spacing.xxxxl * 2)
                }
            }
        }
        .navigationTitle(L10n.Library.albumsTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Text(L10n.Library.albumCount(filteredAlbums.count))
                    .font(theme.typography.bodySmall)
                    .foregroundStyle(theme.colors.textSecondary)
            }
        }
    }
}

struct AlbumGridItem: View {
    let album: Album
    @ThemeAccess private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            // Album artwork
            Group {
                if let artworkImage = album.artworkImage {
                    #if os(macOS)
                    Image(nsImage: artworkImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    #else
                    Image(uiImage: artworkImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    #endif
                } else {
                    RoundedRectangle(cornerRadius: theme.effects.radiusSM)
                        .fill(theme.colors.surfaceSecondary)
                        .overlay {
                            Image(systemName: "music.note")
                                .font(theme.typography.headlineSmall)
                                .foregroundStyle(theme.colors.textSecondary)
                        }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .cornerRadius(theme.effects.radiusSM)
            .clipped()

            VStack(alignment: .leading, spacing: theme.spacing.xxxs) {
                Text(album.title ?? String(localized: "library.unknown_album"))
                    .font(theme.typography.titleSmall)
                    .lineLimit(2)
                    .frame(minHeight: 44, maxHeight: 44, alignment: .top)
                    .foregroundStyle(theme.colors.textPrimary)

                Text(album.artist?.name ?? String(localized: "library.unknown_artist"))
                    .font(theme.typography.bodySmall)
                    .foregroundStyle(theme.colors.textSecondary)
                    .lineLimit(1)

                if album.year > 0 {
                    Text("\(album.year)")
                        .font(theme.typography.labelSmall)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
        }
    }
}

struct AlbumDetailView: View {
    let album: Album
    @EnvironmentObject private var playerViewModel: PlayerViewModel
    private let logger = AppLogger.libraryView
    @ThemeAccess private var theme

    private var tracks: [Track] {
        guard let tracksSet = album.tracks as? Set<Track> else { return [] }
        return tracksSet.sorted { track1, track2 in
            // Sort by disc number, then track number
            if track1.discNumber != track2.discNumber {
                return track1.discNumber < track2.discNumber
            }
            return track1.trackNumber < track2.trackNumber
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Album header
            HStack(alignment: .top, spacing: theme.spacing.xl) {
                // Album artwork
                Group {
                    if let artworkImage = album.artworkImage {
                        #if os(macOS)
                        Image(nsImage: artworkImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        #else
                        Image(uiImage: artworkImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        #endif
                    } else {
                        RoundedRectangle(cornerRadius: theme.effects.radiusMD)
                            .fill(theme.colors.surfaceSecondary)
                            .overlay {
                                Image(systemName: "music.note")
                                    .font(theme.typography.headlineMedium)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                    }
                }
                .frame(width: 200, height: 200)
                .cornerRadius(theme.effects.radiusMD)
                .shadow(radius: 10, y: 5)

                VStack(alignment: .leading, spacing: theme.spacing.lg) {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text(album.title ?? String(localized: "library.unknown_album"))
                            .font(theme.typography.headlineLarge)
                            .fontWeight(.bold)

                        Text(album.artist?.name ?? String(localized: "library.unknown_artist"))
                            .font(theme.typography.titleSmall)
                            .foregroundStyle(theme.colors.textSecondary)

                        HStack(spacing: theme.spacing.sm) {
                            if album.year > 0 {
                                Text("\(album.year)")
                                    .font(theme.typography.bodySmall)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }

                            if tracks.count > 0 {
                                Text("•")
                                    .foregroundStyle(theme.colors.textSecondary)
                                Text(L10n.Library.trackCount(tracks.count))
                                    .font(theme.typography.bodySmall)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }

                            if album.totalDuration > 0 {
                                Text("•")
                                    .foregroundStyle(theme.colors.textSecondary)
                                Text(album.durationFormatted)
                                    .font(theme.typography.bodySmall)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                        }
                    }

                    // Play All button
                    if !tracks.isEmpty {
                        Button(action: {
                            logger.debug("▶️ Play All button pressed for album: \(album.title ?? "Unknown")")
                            playAlbum()
                        }) {
                            Label(L10n.Actions.play, systemImage: "play.fill")
                                .font(theme.typography.titleSmall)
                                .foregroundStyle(theme.colors.onAccent)
                                .padding(.horizontal, theme.spacing.xxl)
                                .padding(.vertical, theme.spacing.sm)
                                .background(theme.colors.accent)
                                .cornerRadius(theme.effects.radiusSM)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, theme.spacing.xl)
            .padding(.vertical, theme.spacing.xl)

            Divider()

            // Track listing
            if tracks.isEmpty {
                Spacer()
                VStack(spacing: theme.spacing.sm) {
                    Image(systemName: "music.note.list")
                        .font(theme.typography.headlineMedium)
                        .foregroundStyle(theme.colors.textSecondary)
                    Text(L10n.Library.tracksEmpty)
                        .font(theme.typography.titleSmall)
                        .foregroundStyle(theme.colors.textSecondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(tracks) { track in
                        TrackRowView(track: track)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) {
                                logger.debug("🖱️ Double-click on track: \(track.title ?? "Unknown")")
                                playTrack(track)
                            }
                            .onTapGesture(count: 1) {
                                logger.debug("👆 Single-click on track: \(track.title ?? "Unknown")")
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(album.title ?? String(localized: "library.unknown_album"))
    }

    // MARK: - Playback Methods

    private func playAlbum() {
        guard !tracks.isEmpty else {
            logger.error("❌ No tracks to play")
            return
        }
        logger.info("🎵 Playing album with \(tracks.count) tracks")
        let queue = makeViewData(from: tracks)
        playerViewModel.play(tracks: queue, startIndex: 0)
    }

    private func playTrack(_ track: Track) {
        guard let index = tracks.firstIndex(of: track) else {
            logger.error("❌ Track not found in album")
            return
        }
        logger.info("🎵 Playing track at index \(index): \(track.title ?? "Unknown")")
        let queue = makeViewData(from: tracks)
        playerViewModel.play(tracks: queue, startIndex: index)
    }

    private func makeViewData(from tracks: [Track]) -> [TrackViewData] {
        tracks.compactMap { track in
            if track.id == nil {
                track.id = UUID()
            }
            return TrackViewData(track: track)
        }
    }
}

struct TrackRowView: View {
    let track: Track
    @EnvironmentObject private var playerViewModel: PlayerViewModel
    @ThemeAccess private var theme

    private var isCurrentTrack: Bool {
        guard let trackID = track.id else { return false }
        return playerViewModel.currentTrack?.id == trackID
    }

    private var isPlaying: Bool {
        isCurrentTrack && playerViewModel.isPlaying
    }

    private var formattedBitrate: String? {
        guard track.bitrate > 0 else { return nil }

        let measurement = Measurement(value: Double(track.bitrate), unit: UnitInformationStorage.kilobits)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .short
        formatter.numberFormatter.maximumFractionDigits = 0

        let formattedValue = formatter.string(from: measurement)
        return L10n.Library.bitratePerSecondText(formattedValue)
    }

    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            // Track number or playing indicator
            if isPlaying {
                Image(systemName: "speaker.wave.2.fill")
                    .font(theme.typography.bodySmall)
                    .foregroundStyle(theme.colors.accent)
            } else if isCurrentTrack {
                Image(systemName: "pause.fill")
                    .font(theme.typography.labelSmall)
                    .foregroundStyle(theme.colors.accent)
            } else {
                Text("\(track.trackNumber)")
                    .font(theme.typography.bodySmall)
                    .foregroundStyle(theme.colors.textSecondary)
                    .monospacedDigit()
            }

            VStack(alignment: .leading, spacing: theme.spacing.xxxs) {
                Text(track.title ?? String(localized: "library.unknown_track"))
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(isCurrentTrack ? theme.colors.accent : theme.colors.textPrimary)

                if let format = track.format {
                    HStack(spacing: theme.spacing.xxxs) {
                        Text(format)
                            .font(theme.typography.labelSmall)
                            .foregroundStyle(theme.colors.textSecondary)

                        if let bitrateText = formattedBitrate {
                            Text("•")
                                .foregroundStyle(theme.colors.textSecondary)
                            Text(bitrateText)
                                .font(theme.typography.labelSmall)
                                .foregroundStyle(theme.colors.textSecondary)
                        }
                    }
                }
            }

            Spacer()

            // Duration
            Text(track.durationFormatted)
                .font(theme.typography.bodySmall)
                .foregroundStyle(theme.colors.textSecondary)
                .monospacedDigit()

            // Play button (appears on hover)
            Button(action: {
                // TODO: Play this track
            }) {
                Image(systemName: "play.fill")
                    .font(theme.typography.labelSmall)
            }
            .buttonStyle(.plain)
            .opacity(0.7)
        }
        .padding(.vertical, theme.spacing.xxxs)
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: {}) {
                Label(L10n.Player.playNext, systemImage: "text.line.first.and.arrowtriangle.forward")
            }
            Button(action: {}) {
                Label(L10n.Player.addToQueue, systemImage: "text.badge.plus")
            }
            Divider()
            Button(action: {}) {
                Label(L10n.Actions.add, systemImage: "plus")
            }
        }
    }
}

#Preview("Albums - Populated") {
    let navigationState = NavigationState()
    return NavigationView {
        PreviewFactory.makeAlbumsView(state: .populated)
    }
    .environmentObject(navigationState)
}

#Preview("Albums - Empty") {
    let navigationState = NavigationState()
    return NavigationView {
        PreviewFactory.makeAlbumsView(state: .empty)
    }
    .environmentObject(navigationState)
}

#Preview("Album Detail") {
    let navigationState = NavigationState()
    return NavigationView {
        PreviewFactory.makeAlbumDetailView(state: .populated)
    }
    .environmentObject(navigationState)
}
