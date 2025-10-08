//
//  FloatingMiniPlayer.swift
//  Kanora
//
//  Created by Claude on 07/10/2025.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct FloatingMiniPlayer: View {
    @EnvironmentObject private var viewModel: PlayerViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ThemeAccess private var theme

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                compactPlayer
            } else {
                regularPlayer
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    // MARK: - Compact Player (Phone)

    private var compactPlayer: some View {
        VStack(spacing: 0) {
            VStack(spacing: theme.spacing.xs) {
                if viewModel.currentTrack != nil {
                    Slider(
                        value: $viewModel.currentTime,
                        in: 0...max(viewModel.duration, 1)
                    ) { editing in
                        if !editing {
                            viewModel.seek(to: viewModel.currentTime)
                        }
                    }
                    .disabled(viewModel.currentTrack == nil)
                    .tint(theme.colors.accent)
                    .padding(.horizontal, theme.spacing.md)
                }

                HStack(spacing: theme.spacing.sm) {
                    albumArtwork(size: 50, cornerRadius: theme.effects.radiusSM)

                    if let track = viewModel.currentTrack {
                        VStack(alignment: .leading, spacing: theme.spacing.xxxs) {
                            Text(track.title)
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.colors.textPrimary)
                                .lineLimit(1)

                            Text(track.artistName)
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.colors.textSecondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text(L10n.Player.noTrackPlaying)
                            .themedSecondaryText()
                            .lineLimit(1)
                    }

                    Spacer()

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
                }
                .padding(.horizontal, theme.spacing.md)
            }
            .padding(.vertical, theme.spacing.sm)
            .background(theme.effects.materialThin)
        }
    }

    // MARK: - Regular Player (iPad/Mac)

    private var regularPlayer: some View {
        VStack(spacing: 0) {
            HStack(spacing: theme.spacing.md) {
                albumArtwork(size: 60, cornerRadius: theme.effects.radiusMD)

                if let track = viewModel.currentTrack {
                    VStack(alignment: .leading, spacing: theme.spacing.xxxs) {
                        Text(track.title)
                            .font(theme.typography.titleSmall)
                            .foregroundColor(theme.colors.textPrimary)
                            .lineLimit(1)

                        Text(track.artistName)
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                            .lineLimit(1)
                    }
                } else {
                    VStack(alignment: .leading, spacing: theme.spacing.xxxs) {
                        Text(L10n.Player.noTrackPlaying)
                            .font(theme.typography.titleSmall)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }

                Spacer()

                HStack(spacing: theme.spacing.md) {
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

                Spacer()

                if viewModel.currentTrack != nil {
                    VStack(spacing: theme.spacing.xs) {
                        HStack(spacing: theme.spacing.xs) {
                            Text(viewModel.currentTimeFormatted)
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                                .monospacedDigit()

                            Slider(
                                value: $viewModel.currentTime,
                                in: 0...max(viewModel.duration, 1)
                            ) { editing in
                                if !editing {
                                    viewModel.seek(to: viewModel.currentTime)
                                }
                            }
                            .disabled(viewModel.currentTrack == nil)
                            .tint(theme.colors.accent)

                            Text(viewModel.durationFormatted)
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                                .monospacedDigit()
                        }
                    }
                    .frame(maxWidth: 240)
                }

                HStack(spacing: theme.spacing.xs) {
                    Button(action: viewModel.toggleMute) {
                        Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .buttonStyle(.plain)

                    Slider(value: $viewModel.volume, in: 0...1)
                        .tint(theme.colors.accent)
                }
                .frame(maxWidth: 200)
            }
            .padding(theme.spacing.md)
            .background(theme.effects.materialThin)
        }
    }

    @ViewBuilder
    private func albumArtwork(size: CGFloat, cornerRadius: CGFloat) -> some View {
        Group {
            if let artworkImage = viewModel.currentTrack?.artworkImage {
                #if os(macOS)
                Image(nsImage: artworkImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                #else
                Image(uiImage: artworkImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                #endif
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(theme.colors.surfaceSecondary.opacity(0.9))
                    .overlay {
                        Image(systemName: "music.note")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                    }
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(cornerRadius)
        .clipped()
    }
}

#Preview("Populated - Compact") {
    let dependencies = PreviewFactory.makePreviewDependencies()
    return FloatingMiniPlayer()
        .environment(\.horizontalSizeClass, .compact)
        .environment(\.managedObjectContext, dependencies.services.persistence.viewContext)
        .environment(\.serviceContainer, dependencies.services)
        .environmentObject(dependencies.playerViewModel)
        .designSystem()
}

#Preview("Populated - Regular") {
    let dependencies = PreviewFactory.makePreviewDependencies()
    return FloatingMiniPlayer()
        .environment(\.horizontalSizeClass, .regular)
        .environment(\.managedObjectContext, dependencies.services.persistence.viewContext)
        .environment(\.serviceContainer, dependencies.services)
        .environmentObject(dependencies.playerViewModel)
        .designSystem()
}
