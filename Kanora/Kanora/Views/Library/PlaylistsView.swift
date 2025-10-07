//
//  PlaylistsView.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import SwiftUI
import CoreData

struct PlaylistsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Playlist.name, ascending: true)],
        animation: .default
    )
    private var playlists: FetchedResults<Playlist>

    var body: some View {
        VStack {
            if playlists.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(L10n.Library.playlistsEmpty)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(L10n.Library.playlistsEmptyMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                List(playlists) { playlist in
                    NavigationLink {
                        PlaylistDetailView(playlist: playlist)
                    } label: {
                        PlaylistRowView(playlist: playlist)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(L10n.Library.playlistsTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: createPlaylist) {
                    Label(L10n.Library.newPlaylist, systemImage: "plus")
                }
            }
        }
    }

    private func createPlaylist() {
        // TODO: Show create playlist sheet
    }
}

struct PlaylistRowView: View {
    let playlist: Playlist

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "music.note.list")
                        .foregroundColor(.accentColor)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name ?? String(localized: "library.playlists.new"))
                    .font(.headline)

                Text(L10n.Library.trackCount(playlist.trackCount))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct PlaylistDetailView: View {
    let playlist: Playlist

    var body: some View {
        VStack {
            Text(playlist.name ?? String(localized: "library.playlists.new"))
                .font(.largeTitle)
            Text(L10n.Placeholders.playlistDetailMessage)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(playlist.name ?? String(localized: "navigation.playlists"))
    }
}

#Preview("Populated") {
    NavigationView {
        PreviewFactory.makePlaylistsView(state: .populated)
    }
}

#Preview("Empty") {
    NavigationView {
        PreviewFactory.makePlaylistsView(state: .empty)
    }
}
