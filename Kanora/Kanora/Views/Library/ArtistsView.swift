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
    @ThemeAccess private var theme

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
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(theme.colors.textSecondary)

                TextField(L10n.Library.searchArtists, text: $searchText)
                    .textFieldStyle(.plain)
                    .font(theme.typography.bodyMedium)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(theme.spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: theme.effects.radiusMD)
                    .fill(theme.colors.surfaceSecondary.opacity(0.8))
            )
            .padding(.horizontal, theme.spacing.md)
            .padding(.top, theme.spacing.md)

            // Artists grid
            if filteredArtists.isEmpty {
                Spacer()
                VStack(spacing: theme.spacing.sm) {
                    Image(systemName: "music.mic")
                        .font(theme.typography.headlineMedium)
                        .foregroundStyle(theme.colors.textSecondary)
                    Text(searchText.isEmpty ? L10n.Library.artistsEmpty : L10n.Library.noResults)
                        .font(theme.typography.titleSmall)
                        .foregroundStyle(theme.colors.textSecondary)
                    if searchText.isEmpty {
                        Text(L10n.Library.artistsEmptyMessage)
                            .font(theme.typography.bodySmall)
                            .foregroundStyle(theme.colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: theme.spacing.md) {
                        ForEach(filteredArtists) { artist in
                            if #available(iOS 16.0, macOS 13.0, *) {
                                NavigationLink(value: artist) {
                                    ArtistGridItem(artist: artist)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button(action: {
                                    navigationState.selectArtist(artist)
                                }) {
                                    ArtistGridItem(artist: artist)
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
        .navigationTitle(L10n.Library.artistsTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Text(L10n.Library.artistCount(filteredArtists.count))
                    .font(theme.typography.bodySmall)
                    .foregroundStyle(theme.colors.textSecondary)
            }
        }
    }
}

struct ArtistGridItem: View {
    let artist: Artist
    @ThemeAccess private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            // Artist image placeholder
            Circle()
                .fill(theme.colors.surfaceSecondary)
                .overlay {
                    Image(systemName: "music.mic")
                        .font(theme.typography.headlineSmall)
                        .foregroundStyle(theme.colors.textSecondary)
                }
                .aspectRatio(1, contentMode: .fit)
                .clipped()

            VStack(alignment: .leading, spacing: theme.spacing.xxxs) {
                Text(artist.name ?? String(localized: "library.unknown_artist"))
                    .font(theme.typography.titleSmall)
                    .lineLimit(2)
                    .frame(minHeight: 44, maxHeight: 44, alignment: .top)
                    .foregroundStyle(theme.colors.textPrimary)

                HStack(spacing: 4) {
                    Text(L10n.Library.albumCount(artist.albumCount))
                        .themedSecondaryLabel()
                    Text("•")
                        .foregroundStyle(theme.colors.textSecondary)
                    Text(L10n.Library.trackCount(artist.trackCount))
                        .themedSecondaryLabel()
                }
            }
        }
    }
}

struct ArtistDetailView: View {
    let artist: Artist
    @EnvironmentObject private var navigationState: NavigationState
    @ThemeAccess private var theme

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

    private var columns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: 150, maximum: 200),
                spacing: theme.spacing.md
            )
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Artist header
                HStack(alignment: .top, spacing: theme.spacing.xl) {
                    // Large artist image placeholder
                    Circle()
                        .fill(theme.colors.surfaceSecondary)
                        .frame(width: 200, height: 200)
                        .overlay {
                            Image(systemName: "music.mic")
                                .font(theme.typography.displaySmall)
                                .foregroundStyle(theme.colors.textSecondary)
                        }

                    VStack(alignment: .leading, spacing: theme.spacing.lg) {
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text(artist.name ?? String(localized: "library.unknown_artist"))
                                .font(theme.typography.headlineLarge)
                                .fontWeight(.bold)

                            HStack(spacing: theme.spacing.md) {
                                Label(L10n.Library.albumCount(albums.count), systemImage: "square.stack")
                                    .font(theme.typography.bodySmall)
                                    .foregroundStyle(theme.colors.textSecondary)

                                Label(L10n.Library.trackCount(artist.trackCount), systemImage: "music.note")
                                    .font(theme.typography.bodySmall)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                        }

                        // Bio placeholder
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text("Biography")
                                .font(theme.typography.titleSmall)

                            Text("Artist biography will be displayed here. This could include information about the artist's background, musical style, and career highlights.")
                                .font(theme.typography.bodyMedium)
                                .foregroundStyle(theme.colors.textSecondary)
                                .lineLimit(4)
                        }
                    }

                    Spacer()
                }
                .padding(theme.spacing.xl)

                Divider()

                // Albums grid
                if albums.isEmpty {
                    VStack(spacing: theme.spacing.sm) {
                        Image(systemName: "square.stack")
                            .font(theme.typography.headlineMedium)
                            .foregroundStyle(theme.colors.textSecondary)
                        Text(L10n.Library.albumsEmpty)
                            .font(theme.typography.titleSmall)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                    .padding(.vertical, theme.spacing.xxxxl + theme.spacing.lg)
                } else {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text("Albums")
                            .font(theme.typography.titleMedium)
                            .fontWeight(.bold)
                            .padding(.horizontal, theme.spacing.xl)
                            .padding(.top, theme.spacing.xl)

                        LazyVGrid(columns: columns, spacing: theme.spacing.md) {
                            ForEach(albums) { album in
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
                        .padding(.horizontal, theme.spacing.xl)
                        .padding(.bottom, theme.spacing.xxxxl * 2)
                    }
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
