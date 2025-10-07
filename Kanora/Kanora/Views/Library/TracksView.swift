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
            Table(filteredTracks) {
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
        } else {
            // iOS 15 / macOS 12 fallback: use compact row
            List(filteredTracks) { track in
                TrackRowCompact(track: track)
            }
            .listStyle(.plain)
        }
    }

    private struct TrackRowCompact: View {
        let track: Track

        var body: some View {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                if track.trackNumber > 0 {
                    Text("\(track.trackNumber)")
                        .foregroundColor(.secondary)
                        .frame(width: 24, alignment: .leading)
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
            .padding(.vertical, 2)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
#if os(macOS)
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(L10n.Library.searchTracks, text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
    #if os(macOS)
            .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
    #else
            .background(Color(uiColor: .secondarySystemBackground).opacity(0.5))
    #endif
            .cornerRadius(8)
            .padding()
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
                tracksContent
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
