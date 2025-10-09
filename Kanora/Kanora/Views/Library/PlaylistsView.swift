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
    @ThemeAccess private var theme

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Playlist.name, ascending: true)],
        animation: .default
    )
    private var playlists: FetchedResults<Playlist>

    var body: some View {
        VStack {
            if playlists.isEmpty {
                Spacer()
                VStack(spacing: theme.spacing.sm) {
                    Image(systemName: "music.note.list")
                        .font(theme.typography.headlineMedium)
                        .foregroundStyle(theme.colors.textSecondary)
                    Text(L10n.Library.playlistsEmpty)
                        .font(theme.typography.titleSmall)
                        .foregroundStyle(theme.colors.textSecondary)
                    Text(L10n.Library.playlistsEmptyMessage)
                        .font(theme.typography.bodySmall)
                        .foregroundStyle(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(playlists) { playlist in
                            NavigationLink {
                                PlaylistDetailView(playlist: playlist)
                            } label: {
                                PlaylistRowView(playlist: playlist)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, theme.spacing.xxxxl * 2)
                }
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
    @ThemeAccess private var theme

    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            RoundedRectangle(cornerRadius: theme.effects.radiusXS)
                .fill(theme.colors.accent.opacity(0.2))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(systemName: "music.note.list")
                        .font(theme.typography.titleSmall)
                        .foregroundStyle(theme.colors.accent)
                }

            VStack(alignment: .leading, spacing: theme.spacing.xxxs) {
                Text(playlist.name ?? String(localized: "library.playlists.new"))
                    .font(theme.typography.titleSmall)
                    .foregroundStyle(theme.colors.textPrimary)

                Text(L10n.Library.trackCount(playlist.trackCount))
                    .font(theme.typography.labelSmall)
                    .foregroundStyle(theme.colors.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.xs)
    }
}

struct PlaylistDetailView: View {
    let playlist: Playlist
    @ThemeAccess private var theme

    var body: some View {
        VStack {
            Text(playlist.name ?? String(localized: "library.playlists.new"))
                .font(theme.typography.headlineLarge)
                .foregroundStyle(theme.colors.textPrimary)
            Text(L10n.Placeholders.playlistDetailMessage)
                .font(theme.typography.bodySmall)
                .foregroundStyle(theme.colors.textSecondary)
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
