//
//  PlayerControlsView.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

struct PlayerControlsView: View {
    @ThemeAccess private var theme
    @EnvironmentObject private var viewModel: PlayerViewModel

    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            // Now playing info
            HStack(spacing: theme.spacing.sm) {
                // Album art placeholder
                RoundedRectangle(cornerRadius: theme.effects.radiusSM)
                    .fill(theme.colors.surfaceSecondary.opacity(0.9))
                    .frame(width: 50, height: 50)
                    .overlay {
                        if viewModel.currentTrack != nil {
                            Image(systemName: "music.note")
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                }
                .frame(width: 50, height: 50)
                .cornerRadius(4)

                if let track = viewModel.currentTrack {
                    VStack(alignment: .leading, spacing: theme.spacing.xxxs) {
                        Text(track.title ?? String(localized: "library.unknown_track"))
                            .font(theme.typography.titleSmall)
                            .foregroundColor(theme.colors.textPrimary)
                            .lineLimit(1)
                        Text(track.album?.artist?.name ?? String(localized: "library.unknown_artist"))
                            .themedSecondaryText()
                            .lineLimit(1)
                    }
                } else {
                    Text(L10n.Player.noTrackPlaying)
                        .themedSecondaryText()
                }
            }
            .frame(minWidth: 150, idealWidth: 250, maxWidth: 300)

            Spacer()

            // Playback controls
            VStack(spacing: theme.spacing.xs) {
                HStack(spacing: theme.spacing.lg) {
                    Button(action: viewModel.skipToPrevious) {
                        Image(systemName: "backward.fill")
                            .font(theme.typography.titleSmall)
                            .foregroundColor(theme.colors.textPrimary)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.currentTrack == nil)

                    Button(action: viewModel.togglePlayPause) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(theme.typography.headlineMedium)
                            .foregroundColor(theme.colors.accent)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.currentTrack == nil)

                    Button(action: viewModel.skipToNext) {
                        Image(systemName: "forward.fill")
                            .font(theme.typography.titleSmall)
                            .foregroundColor(theme.colors.textPrimary)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.currentTrack == nil)
                }

                // Progress bar
                HStack(spacing: theme.spacing.xs) {
                    Text(viewModel.currentTimeFormatted)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                        .monospacedDigit()

                    Slider(value: $viewModel.currentTime, in: 0...viewModel.duration) { editing in
                        if !editing {
                            viewModel.seek(to: viewModel.currentTime)
                        }
                    }
                    .frame(minWidth: 150, idealWidth: 300, maxWidth: 400)
                    .disabled(viewModel.currentTrack == nil)
                    .tint(theme.colors.accent)

                    Text(viewModel.durationFormatted)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                        .monospacedDigit()
                }
            }

            Spacer()

            // Volume control
            HStack(spacing: theme.spacing.sm) {
                Button(action: viewModel.toggleMute) {
                    Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(theme.colors.textSecondary)
                }
                .buttonStyle(.plain)

                Slider(value: $viewModel.volume, in: 0...1)
                    .frame(minWidth: 60, idealWidth: 100, maxWidth: 120)
                    .tint(theme.colors.accent)
            }
            .frame(minWidth: 100, idealWidth: 150, maxWidth: 200)
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .frame(minHeight: 80, idealHeight: 80, maxHeight: 100)
    }
}

#Preview("Populated") {
    PreviewFactory.makePlayerControlsView(state: .populated)
        .designSystem()
}

#Preview("Empty") {
    PreviewFactory.makePlayerControlsView(state: .empty)
        .designSystem()
}

