//
//  ImportFilesView.swift
//  Kanora
//
//  Created by Claude on 07/10/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportFilesView: View {
    @StateObject private var viewModel: ImportViewModel
    private let logger = AppLogger.importView
    @ThemeAccess private var theme

    init(services: ServiceContainer) {
        _viewModel = StateObject(wrappedValue: ImportViewModel(
            context: services.persistence.viewContext,
            services: services
        ))
    }

    var body: some View {
        VStack(spacing: theme.spacing.xl) {
            // Header
            VStack(spacing: theme.spacing.xs) {
                Image(systemName: "square.and.arrow.down")
                    .font(theme.typography.displayMedium)
                    .foregroundColor(theme.colors.accent)

                Text(L10n.Navigation.importFiles)
                    .font(theme.typography.titleLarge)

                Text(viewModel.statusMessage)
                    .themedSecondaryText()
                    .multilineTextAlignment(.center)
            }
            .padding(.top, theme.spacing.xxxl)

            // Library Selector
            if !viewModel.availableLibraries.isEmpty {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(L10n.Import.selectLibrary)
                        .font(theme.typography.titleSmall)
                        .foregroundColor(theme.colors.textPrimary)

                    Picker("", selection: $viewModel.selectedLibrary) {
                        ForEach(viewModel.availableLibraries, id: \.self) { library in
                            Text(library.name.isEmpty ? L10n.Library.unknownLibraryName : library.name)
                                .tag(library as LibraryViewData?)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(theme.colors.accent)
                }
                .padding(.horizontal, theme.spacing.md)
            }

            // Import Mode Selector - Card-based
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.Import.chooseMethod)
                    .font(theme.typography.titleSmall)
                    .foregroundColor(theme.colors.textPrimary)
                    .padding(.horizontal, theme.spacing.md)

                HStack(spacing: theme.spacing.md) {
                    ForEach(ImportMode.allCases, id: \.self) { mode in
                        ImportModeCard(
                            mode: mode,
                            isSelected: viewModel.importMode == mode,
                            action: {
                                viewModel.importMode = mode
                                if mode == .pointAtDirectory {
                                    viewModel.showDirectoryPicker = true
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, theme.spacing.md)
            }

            // Drop Zone or File List
            if viewModel.selectedFiles.isEmpty {
                dropZone
            } else {
                fileList
            }

            // Progress Indicator
            if viewModel.viewState.isLoading {
                progressView
            }

            Spacer()

            // Actions
            actionButtons
        }
        .padding(.bottom, theme.spacing.xxxxl * 2) // Space for floating player
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .fileImporter(
            isPresented: $viewModel.showFilePicker,
            allowedContentTypes: [
                .mp3,
                .mpeg4Audio,
                .wav,
                UTType(filenameExtension: "flac") ?? .audio,
                UTType(filenameExtension: "aac") ?? .audio
            ],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                logger.debug("🔍 File picker returned \(urls.count) files")
                // Start accessing security-scoped resources
                let accessibleURLs = urls.compactMap { url -> URL? in
                    let didStartAccessing = url.startAccessingSecurityScopedResource()
                    logger.debug("🔐 Security access for \(url.lastPathComponent): \(didStartAccessing)")
                    return didStartAccessing ? url : nil
                }
                logger.info("✅ Accessible files: \(accessibleURLs.count)")
                viewModel.selectFiles(accessibleURLs)
            case .failure(let error):
                logger.error("❌ File picker error: \(error.localizedDescription)")
            }
        }
        .fileImporter(
            isPresented: $viewModel.showDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let directoryURL = urls.first {
                    logger.debug("📂 Directory selected: \(directoryURL.path)")
                    _ = directoryURL.startAccessingSecurityScopedResource()
                    viewModel.selectDirectory(directoryURL)
                }
            case .failure(let error):
                logger.error("❌ Directory picker error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Import Mode Card

    struct ImportModeCard: View {
        let mode: ImportMode
        let isSelected: Bool
        let action: () -> Void
        @ThemeAccess private var theme

        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    HStack {
                        Image(systemName: mode.icon)
                            .font(theme.typography.headlineSmall)
                            .foregroundColor(isSelected ? theme.colors.accent : theme.colors.textSecondary)

                        Spacer()

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(theme.colors.accent)
                        }
                    }

                    VStack(alignment: .leading, spacing: theme.spacing.xxxs) {
                        Text(mode.displayName)
                            .font(theme.typography.titleSmall)
                            .foregroundColor(theme.colors.textPrimary)

                        Text(mode.description)
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(theme.spacing.md)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: theme.effects.radiusMD)
                        .fill(
                            isSelected
                                ? theme.colors.accent.opacity(0.12)
                                : theme.colors.surfaceSecondary.opacity(0.8)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.effects.radiusMD)
                        .stroke(isSelected ? theme.colors.accent : theme.colors.borderSecondary, lineWidth: isSelected ? 2 : 1)
                )
                .cornerRadius(theme.effects.radiusMD)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Drop Zone

    private var dropZone: some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: "arrow.down.doc")
                .font(theme.typography.displaySmall)
                .foregroundColor(theme.colors.textSecondary)

            Text(L10n.Import.dropFilesHere)
                .font(theme.typography.titleSmall)
                .foregroundColor(theme.colors.textSecondary)

            Text(L10n.Import.supportedFormats)
                .themedSecondaryText()

            Button(action: {
                viewModel.showFilePicker = true
            }) {
                Label(L10n.Import.selectFiles, systemImage: "folder")
                    .font(theme.typography.titleSmall)
                    .foregroundColor(theme.colors.onAccent)
                    .padding(.horizontal, theme.spacing.xl)
                    .padding(.vertical, theme.spacing.sm)
                    .background(theme.colors.accent)
                    .cornerRadius(theme.effects.radiusSM)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .background(
            RoundedRectangle(cornerRadius: theme.effects.radiusMD)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                .foregroundColor(theme.colors.borderSecondary)
        )
        .padding(.horizontal, theme.spacing.md)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            viewModel.handleDrop(providers: providers)
        }
    }

    // MARK: - File List

    private var fileList: some View {
        VStack(spacing: theme.spacing.xs) {
            HStack {
                Text(L10n.Import.filesSelected(viewModel.selectedFiles.count))
                    .font(theme.typography.titleSmall)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
                Button(action: viewModel.clearFiles) {
                    Text(L10n.Import.clearSelection)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.accent)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.viewState.isLoading)
            }
            .padding(.horizontal, theme.spacing.md)

            ScrollView {
                LazyVStack(spacing: theme.spacing.xxs) {
                    ForEach(Array(viewModel.selectedFiles.enumerated()), id: \.element) { index, url in
                        FileRow(
                            url: url,
                            onRemove: {
                                viewModel.removeFile(at: index)
                            },
                            isEnabled: !viewModel.viewState.isLoading
                        )
                    }
                }
                .padding(.horizontal, theme.spacing.md)
            }
            .frame(maxHeight: 400)
        }
    }

    // MARK: - Progress View

    private var progressView: some View {
        VStack(spacing: theme.spacing.xs) {
            ProgressView(value: viewModel.importProgress)
                .progressViewStyle(.linear)
                .tint(theme.colors.accent)

            if let currentFile = viewModel.currentFile {
                Text(currentFile)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
                    .lineLimit(1)
            }

            Text(L10n.Import.progressFraction(viewModel.filesProcessed, viewModel.totalFiles))
                .themedSecondaryText()
        }
        .padding(theme.spacing.md)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: theme.spacing.md) {
            if !viewModel.selectedFiles.isEmpty && !viewModel.viewState.isLoading {
                Button(action: {
                    viewModel.showFilePicker = true
                }) {
                    Label(L10n.Actions.add, systemImage: "plus")
                        .font(theme.typography.titleSmall)
                        .foregroundColor(theme.colors.accent)
                        .padding(.horizontal, theme.spacing.xl)
                        .padding(.vertical, theme.spacing.sm)
                        .background(theme.colors.accent.opacity(0.12))
                        .cornerRadius(theme.effects.radiusSM)
                }
                .buttonStyle(.plain)
            }

            if viewModel.canImport {
                Button(action: viewModel.startImport) {
                    Label(L10n.Import.startImport, systemImage: "square.and.arrow.down")
                        .font(theme.typography.titleSmall)
                        .foregroundColor(theme.colors.onAccent)
                        .padding(.horizontal, theme.spacing.xxl)
                        .padding(.vertical, theme.spacing.sm)
                        .background(theme.colors.accent)
                        .cornerRadius(theme.effects.radiusSM)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.viewState.isLoading)
            }
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.bottom, theme.spacing.xl)
    }
}

// MARK: - File Row

struct FileRow: View {
    let url: URL
    let onRemove: () -> Void
    let isEnabled: Bool
    @ThemeAccess private var theme

    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            Image(systemName: "music.note")
                .foregroundColor(theme.colors.textSecondary)

            VStack(alignment: .leading, spacing: theme.spacing.xxxs) {
                Text(url.lastPathComponent)
                    .font(theme.typography.bodyMedium)
                    .lineLimit(1)

                Text(url.pathExtension.uppercased())
                    .themedBadge()
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(theme.colors.textSecondary)
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
        }
        .padding(.vertical, theme.spacing.xs)
        .padding(.horizontal, theme.spacing.sm)
        .background(theme.colors.surfaceSecondary.opacity(isEnabled ? 0.9 : 0.5))
        .cornerRadius(theme.effects.radiusSM)
    }
}

// MARK: - Previews

#Preview("Empty") {
    ImportFilesView(services: ServiceContainer.preview)
        .designSystem()
}

#Preview("With Files") {
    ImportFilesView(services: ServiceContainer.preview)
        .designSystem()
}
