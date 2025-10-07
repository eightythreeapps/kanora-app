//
//  ArtistsView.swift
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

struct ArtistsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var navigationState: NavigationState

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Artist.sortName, ascending: true)],
        animation: .default
    )
    private var artists: FetchedResults<Artist>

    @State private var searchText = ""

    var filteredArtists: [Artist] {
        if searchText.isEmpty {
            return Array(artists)
        }
        return artists.filter { artist in
            artist.name?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(L10n.Library.searchArtists, text: $searchText)
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

            // Artists list
            if filteredArtists.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "music.mic")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? L10n.Library.artistsEmpty : L10n.Library.noResults)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    if searchText.isEmpty {
                        Text(L10n.Library.artistsEmptyMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredArtists) { artist in
                            Button(action: {
                                navigationState.selectArtist(artist)
                            }) {
                                ArtistRowView(artist: artist)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle(L10n.Library.artistsTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 16) {
                    Text(L10n.Library.artistCount(filteredArtists.count))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            // Auto-select first artist if none selected
            if navigationState.selectedArtist == nil, let first = filteredArtists.first {
                navigationState.selectArtist(first)
            }
        }
    }
}

struct ArtistRowView: View {
    let artist: Artist

    var body: some View {
        HStack(spacing: 12) {
            // Placeholder album art
            Circle()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "music.mic")
                        .font(.title)
                        .foregroundColor(.secondary)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name ?? String(localized: "library.unknown_artist"))
                    .font(.headline)

                HStack(spacing: 4) {
                    Text(L10n.Library.albumCount(artist.albumCount))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(L10n.Library.trackCount(artist.trackCount))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct ArtistDetailView: View {
    let artist: Artist
    @EnvironmentObject private var navigationState: NavigationState

    private var albums: [Album] {
        guard let albumsSet = artist.albums as? Set<Album> else { return [] }
        return albumsSet.sorted { album1, album2 in
            // Sort by year, then by title
            if album1.year != album2.year {
                return album1.year < album2.year
            }
            return (album1.title ?? "") < (album2.title ?? "")
        }
    }

    let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Artist header
            HStack(alignment: .center, spacing: 24) {
                // Large artist icon
                Circle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .overlay {
                        Image(systemName: "music.mic")
                            .font(.system(size: 56))
                            .foregroundColor(.secondary)
                    }

                VStack(alignment: .leading, spacing: 12) {
                    Text(artist.name ?? String(localized: "library.unknown_artist"))
                        .font(.largeTitle.bold())

                    HStack(spacing: 16) {
                        Label(L10n.Library.albumCount(albums.count), systemImage: "square.stack")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Label(L10n.Library.trackCount(artist.trackCount), systemImage: "music.note")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)

            Divider()

            // Albums grid
            if albums.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "square.stack")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(L10n.Library.albumsEmpty)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(albums) { album in
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
        .navigationTitle(artist.name ?? String(localized: "library.unknown_artist"))
    }
}

#Preview("Artists - Populated") {
    let navigationState = NavigationState()
    return NavigationView {
        PreviewFactory.makeArtistsView(state: .populated)
    }
    .environmentObject(navigationState)
}

#Preview("Artists - Empty") {
    let navigationState = NavigationState()
    return NavigationView {
        PreviewFactory.makeArtistsView(state: .empty)
    }
    .environmentObject(navigationState)
}

#Preview("Artist Detail") {
    let navigationState = NavigationState()
    return NavigationView {
        PreviewFactory.makeArtistDetailView(state: .populated)
    }
    .environmentObject(navigationState)
}
