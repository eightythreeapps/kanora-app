//
//  FloatingMiniPlayer.swift
//  Kanora
//
//  Created by Claude on 07/10/2025.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

struct FloatingMiniPlayer: View {
    @StateObject private var viewModel: PlayerViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isExpanded = false

    init(services: ServiceContainer) {
        // Use shared PlayerViewModel instance
        _viewModel = StateObject(wrappedValue: PlayerViewModel.shared(
            context: services.persistence.viewContext,
            services: services
        ))
    }

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
            VStack(spacing: 8) {
                // Progress bar
                if viewModel.currentTrack != nil {
                    Slider(
                        value: $viewModel.currentTime,
                        in: 0...max(viewModel.duration, 1)
                    ) { editing in
                        if !editing {
                            viewModel.seek(to: viewModel.currentTime)
                        }
                    }
                    .accentColor(.primary)
                    .padding(.horizontal)
                }

                // Controls
                HStack(spacing: 12) {
                    // Album art
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
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.2))
                                .overlay {
                                    Image(systemName: "music.note")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                        }
                    }
                    .frame(width: 50, height: 50)
                    .cornerRadius(4)

                    // Track info
                    if let track = viewModel.currentTrack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            Text(track.artistName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text(L10n.Player.noTrackPlaying)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Playback controls
                    HStack(spacing: 20) {
                        Button(action: viewModel.skipToPrevious) {
                            Image(systemName: "backward.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.currentTrack == nil)

                        Button(action: viewModel.togglePlayPause) {
                            Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.largeTitle)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.currentTrack == nil)

                        Button(action: viewModel.skipToNext) {
                            Image(systemName: "forward.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.currentTrack == nil)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
#if os(macOS)
            .background(.ultraThinMaterial)
#else
            .background(.ultraThinMaterial)
#endif
        }
    }

    // MARK: - Regular Player (iPad/Mac)

    private var regularPlayer: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Album art
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
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.2))
                            .overlay {
                                Image(systemName: "music.note")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                    }
                }
                .frame(width: 60, height: 60)
                .cornerRadius(6)

                // Track info
                if let track = viewModel.currentTrack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.title)
                            .font(.headline)
                            .lineLimit(1)
                        Text(track.artistName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.Player.noTrackPlaying)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Playback controls
                HStack(spacing: 16) {
                    Button(action: viewModel.skipToPrevious) {
                        Image(systemName: "backward.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.currentTrack == nil)

                    Button(action: viewModel.togglePlayPause) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 36))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.currentTrack == nil)

                    Button(action: viewModel.skipToNext) {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.currentTrack == nil)
                }

                Spacer()

                // Progress and time
                if viewModel.currentTrack != nil {
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Text(viewModel.currentTimeFormatted)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()

                            Slider(
                                value: $viewModel.currentTime,
                                in: 0...max(viewModel.duration, 1)
                            ) { editing in
                                if !editing {
                                    viewModel.seek(to: viewModel.currentTime)
                                }
                            }

                            Text(viewModel.durationFormatted)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                    }
                }

                // Volume control
                HStack(spacing: 12) {
                    Button(action: viewModel.toggleMute) {
                        Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    }
                    .buttonStyle(.plain)
                    
                    Slider(value: $viewModel.volume, in: 0...1)
                }
                .frame(maxWidth: 200)
            }
            .padding()
#if os(macOS)
            .background(.ultraThinMaterial)
#else
            .background(.ultraThinMaterial)
#endif
        }
    }
}

#Preview("Populated - Compact") {
    FloatingMiniPlayer(services: ServiceContainer.preview)
        .environment(\.horizontalSizeClass, .compact)
}

#Preview("Populated - Regular") {
    FloatingMiniPlayer(services: ServiceContainer.preview)
        .environment(\.horizontalSizeClass, .regular)
}
