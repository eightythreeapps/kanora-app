//
//  TracksView.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import SwiftUI
import CoreData

#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct TracksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var navigationState: NavigationState

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Track.album?.artist?.sortName, ascending: true),
            NSSortDescriptor(keyPath: \Track.album?.title, ascending: true),
            NSSortDescriptor(keyPath: \Track.trackNumber, ascending: true)
        ],
        animation: .default
    )
    private var tracks: FetchedResults<Track>

    @State private var searchText = ""
    @State private var selectedTrackID: Track.ID?
    @State private var lastTappedTrackID: Track.ID?
    @State private var lastTapTime = Date()

    @Environment(\.serviceContainer) private var services
    private let services = ServiceContainer.shared
    private let logger = AppLogger.libraryView

#if os(iOS)
    @Environment(\.horizontalSizeClass) private var hSizeClass
#endif

    var filteredTracks: [Track] {
        if searchText.isEmpty {
            return Array(tracks)
        }
        return tracks.filter { track in
            track.title?.localizedCaseInsensitiveContains(searchText) ?? false ||
            track.album?.title?.localizedCaseInsensitiveContains(searchText) ?? false ||
            track.album?.artist?.name?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    @ViewBuilder
    private var tracksContent: some View {
    #if os(iOS)
        if hSizeClass == .compact {
            List(filteredTracks) { track in
                TrackRowCompact(track: track)
            }
            .listStyle(.plain)
        } else {
            tracksTable
        }
    #else
        tracksTable
    #endif
    }

    @ViewBuilder
    private var tracksTable: some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            Table(filteredTracks, selection: $selectedTrackID) {
                TableColumn(L10n.TableColumns.number) { track in
                    if track.trackNumber > 0 {
                        Text("\(track.trackNumber)")
                            .foregroundColor(.secondary)
                    }
                }
                .width(40)

                TableColumn(L10n.TableColumns.title) { track in
                    Text(track.title ?? String(localized: "library.unknown_track"))
                }
                .width(min: 200)

                TableColumn(L10n.TableColumns.artist) { track in
                    Text(track.album?.artist?.name ?? String(localized: "library.unknown_artist"))
                        .foregroundColor(.secondary)
                }
                .width(min: 150)

                TableColumn(L10n.TableColumns.album) { track in
                    Text(track.album?.title ?? String(localized: "library.unknown_album"))
                        .foregroundColor(.secondary)
                }
                .width(min: 150)

                TableColumn(L10n.TableColumns.duration) { track in
                    Text(track.durationFormatted)
                        .foregroundColor(.secondary)
                }
                .width(80)
            }
            .onChange(of: selectedTrackID) { newValue in
                logger.debug("📊 Selection changed to: \(String(describing: newValue))")
                logger.debug("⏰ Last tap time: \(Date().timeIntervalSince(lastTapTime))s ago")
                logger.debug("🎯 Last tapped ID: \(String(describing: lastTappedTrackID))")

                // Track double-click timing
                if let trackID = newValue,
                   let track = filteredTracks.first(where: { $0.id == trackID }) {
                    logger.info("✅ Found track: \(track.title ?? "Unknown")")

                    if trackID == lastTappedTrackID,
                       Date().timeIntervalSince(lastTapTime) < 0.5 {
                        // Double-click detected
                        logger.debug("🖱️ Double-click detected on: \(track.title ?? "Unknown")")
                        playTrack(track)
                        lastTappedTrackID = nil
                    } else {
                        // Single click
                        logger.debug("👆 Single click on: \(track.title ?? "Unknown")")
                        lastTappedTrackID = trackID
                        lastTapTime = Date()
                    }
                } else if newValue != nil {
                    logger.error("❌ Track not found in filtered list")
                }
            }
        } else {
            // iOS 15 / macOS 12 fallback: use compact row
            List(filteredTracks) { track in
                TrackRowCompact(track: track)
                    .onTapGesture(count: 2) {
                        playTrack(track)
                    }
            }
            .listStyle(.plain)
        }
    }

    private func playTrack(_ track: Track) {
        logger.info("🎵 Playing track: \(track.title ?? "Unknown")")
        // Set queue to all filtered tracks, starting at the selected track
        if let index = filteredTracks.firstIndex(of: track) {
            services.audioPlayerService.setQueue(tracks: filteredTracks, startIndex: index)
        }
        // Play the track
        try? services.audioPlayerService.play(track: track)
    }

    private struct TrackRowCompact: View {
        let track: Track

        var body: some View {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                if track.trackNumber > 0 {
                    Text("\(track.trackNumber)")
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title ?? String(localized: "library.unknown_track"))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text("\(track.album?.artist?.name ?? String(localized: "library.unknown_artist")) • \(track.album?.title ?? String(localized: "library.unknown_album"))")
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer(minLength: 8)

                Text(track.durationFormatted)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            .contentShape(Rectangle())
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
#if os(macOS)
            LibrarySearchBar(
                placeholder: L10n.Library.searchTracks,
                text: $searchText,
                accessibilityLabel: L10n.Library.searchTracks,
                textFieldIdentifier: "tracks-search-field",
                clearButtonIdentifier: "tracks-search-clear"
            )
#endif

            // Tracks list
            if filteredTracks.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? L10n.Library.tracksEmpty : L10n.Library.noResults)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    if searchText.isEmpty {
                        Text(L10n.Library.tracksEmptyMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                Spacer()
            } else {
                ZStack(alignment: .bottom) {
                    tracksContent
                    // Add spacer for floating player
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 100)
                        .allowsHitTesting(false)
                }
            }
        }
        .navigationTitle(L10n.Library.tracksTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Text(L10n.Library.trackCount(filteredTracks.count))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
#if os(iOS)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: L10n.Library.searchTracks)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

#Preview("Populated") {
    NavigationView {
        PreviewFactory.makeTracksView(state: .populated)
    }
}

#Preview("Empty") {
    NavigationView {
        PreviewFactory.makeTracksView(state: .empty)
    }
}
