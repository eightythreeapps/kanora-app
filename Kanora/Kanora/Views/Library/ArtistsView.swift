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
                List(filteredArtists) { artist in
                    NavigationLink {
                        ArtistDetailView(artist: artist)
                    } label: {
                        ArtistRowView(artist: artist)
                    }
                }
                .listStyle(.plain)
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
    }
}

struct ArtistRowView: View {
    let artist: Artist

    var body: some View {
        HStack(spacing: 12) {
            // Placeholder album art
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "music.mic")
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
        .padding(.vertical, 4)
    }
}

struct ArtistDetailView: View {
    let artist: Artist

    var body: some View {
        VStack {
            Text(artist.name ?? String(localized: "library.unknown_artist"))
                .font(.largeTitle)
            Text(L10n.Placeholders.artistDetailMessage)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(artist.name ?? String(localized: "library.unknown_artist"))
    }
}

#Preview("Populated") {
    NavigationView {
        PreviewFactory.makeArtistsView(state: .populated)
    }
}

#Preview("Empty") {
    NavigationView {
        PreviewFactory.makeArtistsView(state: .empty)
    }
}
