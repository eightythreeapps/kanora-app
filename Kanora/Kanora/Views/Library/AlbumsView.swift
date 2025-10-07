//
//  AlbumsView.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import SwiftUI
import CoreData

struct AlbumsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var navigationState: NavigationState

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

    let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(L10n.Library.searchAlbums, text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
#if os(macOS)
            .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
#else
            .background(Color(uiColor: .secondarySystemBackground).opacity(0.5))
#endif
            .cornerRadius(8)
            .padding()

            // Albums grid
            if filteredAlbums.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "square.stack")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? L10n.Library.albumsEmpty : L10n.Library.noResults)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    if searchText.isEmpty {
                        Text(L10n.Library.albumsEmptyMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredAlbums) { album in
                            Button(action: {
                                navigationState.selectAlbum(album)
                            }) {
                                AlbumGridItem(album: album)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle(L10n.Library.albumsTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Text(L10n.Library.albumCount(filteredAlbums.count))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            // Auto-select first album if none selected
            if navigationState.selectedAlbum == nil, let first = filteredAlbums.first {
                navigationState.selectAlbum(first)
            }
        }
    }
}

struct AlbumGridItem: View {
    let album: Album

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Album art placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.2))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(album.title ?? String(localized: "library.unknown_album"))
                    .font(.headline)
                    .lineLimit(2)
                    .frame(minHeight: 44, maxHeight: 44, alignment: .top)
                    .foregroundColor(.primary)

                Text(album.artist?.name ?? String(localized: "library.unknown_artist"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if album.year > 0 {
                    Text("\(album.year)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct AlbumDetailView: View {
    let album: Album

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
            HStack(alignment: .top, spacing: 24) {
                // Album artwork
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .shadow(radius: 10, y: 5)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                    }

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(album.title ?? String(localized: "library.unknown_album"))
                            .font(.title.bold())

                        Text(album.artist?.name ?? String(localized: "library.unknown_artist"))
                            .font(.title3)
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            if album.year > 0 {
                                Text("\(album.year)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            if tracks.count > 0 {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text(L10n.Library.trackCount(tracks.count))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            if album.totalDuration > 0 {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text(album.durationFormatted)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Play All button
                    if !tracks.isEmpty {
                        Button(action: {
                            // TODO: Play all tracks
                        }) {
                            Label(L10n.Actions.play, systemImage: "play.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Color.accentColor)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)

            Divider()

            // Track listing
            if tracks.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(L10n.Library.tracksEmpty)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(tracks) { track in
                        TrackRowView(track: track)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(album.title ?? String(localized: "library.unknown_album"))
    }
}

struct TrackRowView: View {
    let track: Track

    var body: some View {
        HStack(spacing: 12) {
            // Track number
            Text("\(track.trackNumber)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .monospacedDigit()

            VStack(alignment: .leading, spacing: 4) {
                Text(track.title ?? String(localized: "library.unknown_track"))
                    .font(.body)

                if let format = track.format {
                    HStack(spacing: 4) {
                        Text(format)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if track.bitrate > 0 {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text("\(track.bitrate) kbps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Spacer()

            // Duration
            Text(track.durationFormatted)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .monospacedDigit()

            // Play button (appears on hover)
            Button(action: {
                // TODO: Play this track
            }) {
                Image(systemName: "play.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .opacity(0.7)
        }
        .padding(.vertical, 4)
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
