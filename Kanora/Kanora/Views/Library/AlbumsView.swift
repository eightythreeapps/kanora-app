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
                            NavigationLink {
                                AlbumDetailView(album: album)
                            } label: {
                                AlbumGridItem(album: album)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
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

    var body: some View {
        VStack {
            Text(album.title ?? String(localized: "library.unknown_album"))
                .font(.largeTitle)
            Text(album.artist?.name ?? String(localized: "library.unknown_artist"))
                .foregroundColor(.secondary)
            Text(L10n.Placeholders.albumDetailMessage)
                .foregroundColor(.secondary)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(album.title ?? String(localized: "library.unknown_album"))
    }
}

#Preview("Populated") {
    NavigationView {
        PreviewFactory.makeAlbumsView(state: .populated)
    }
}

#Preview("Empty") {
    NavigationView {
        PreviewFactory.makeAlbumsView(state: .empty)
    }
}
