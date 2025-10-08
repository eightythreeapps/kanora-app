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
            VStack(spacing: theme.spacing.sm) {
                Image(systemName: "square.and.arrow.down")
                    .font(theme.typography.displaySmall)
                    .foregroundStyle(theme.colors.accent)

                Text(L10n.Navigation.importFiles)
                    .font(theme.typography.titleLarge)
                    .fontWeight(.bold)

                Text(viewModel.statusMessage)
                    .font(theme.typography.bodySmall)
                    .foregroundStyle(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, theme.spacing.xxxxl)

            // Library Selector
            if !viewModel.availableLibraries.isEmpty {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    Text(L10n.Import.selectLibrary)
                        .font(theme.typography.titleSmall)

                    Picker("", selection: $viewModel.selectedLibraryID) {
                        ForEach(viewModel.availableLibraries) { library in
                            Text(library.name)
                                .tag(library.id as Library.ID?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal, theme.spacing.md)
            }

            // Import Mode Selector - Card-based
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("Choose Import Method")
                    .font(theme.typography.titleSmall)
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
                print("🔍 File picker returned \(urls.count) files")
                // Start accessing security-scoped resources
                let accessibleURLs = urls.compactMap { url -> URL? in
                    let didStartAccessing = url.startAccessingSecurityScopedResource()
                    print("🔐 Security access for \(url.lastPathComponent): \(didStartAccessing)")
                    return didStartAccessing ? url : nil
                }
                print("✅ Accessible files: \(accessibleURLs.count)")
                viewModel.selectFiles(accessibleURLs)
            case .failure(let error):
                print("❌ File picker error: \(error.localizedDescription)")
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
                    print("📂 Directory selected: \(directoryURL.path)")
                    _ = directoryURL.startAccessingSecurityScopedResource()
                    viewModel.selectDirectory(directoryURL)
                }
            case .failure(let error):
                print("❌ Directory picker error: \(error.localizedDescription)")
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
                            .font(theme.typography.titleMedium)
                            .foregroundStyle(isSelected ? theme.colors.accent : theme.colors.textSecondary)

                        Spacer()

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(theme.colors.accent)
                        }
                    }

                    VStack(alignment: .leading, spacing: theme.spacing.xxxs) {
                        Text(mode.displayName)
                            .font(theme.typography.titleSmall)
                            .foregroundStyle(theme.colors.textPrimary)

                        Text(mode.description)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(theme.spacing.md)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: theme.effects.radiusLG)
                        .fill(
                            isSelected
                                ? theme.colors.accent.opacity(0.1)
                                : theme.colors.surfaceSecondary
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.effects.radiusLG)
                        .stroke(
                            isSelected ? theme.colors.accent : Color.clear,
                            lineWidth: 2
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Drop Zone

    private var dropZone: some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: "arrow.down.doc")
                .font(theme.typography.headlineMedium)
                .foregroundStyle(theme.colors.textSecondary)

            Text(L10n.Import.dropFilesHere)
                .font(theme.typography.titleSmall)
                .foregroundStyle(theme.colors.textSecondary)

            Text("Supported formats: MP3, FLAC, M4A, WAV, AAC")
                .themedSecondaryLabel()

            Button(action: {
                viewModel.showFilePicker = true
            }) {
                Label(L10n.Import.selectFiles, systemImage: "folder")
                    .themedPrimaryButton()
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .background(
            RoundedRectangle(cornerRadius: theme.effects.radiusLG)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                .foregroundStyle(theme.colors.borderSecondary)
        )
        .padding(.horizontal, theme.spacing.md)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            viewModel.handleDrop(providers: providers)
        }
    }

    // MARK: - File List

    private var fileList: some View {
        VStack(spacing: theme.spacing.sm) {
            HStack {
                Text("\(viewModel.selectedFiles.count) files selected")
                    .font(theme.typography.titleSmall)
                Spacer()
                Button(action: viewModel.clearFiles) {
                    Text(L10n.Import.clearSelection)
                        .font(theme.typography.bodySmall)
                        .foregroundStyle(theme.colors.accent)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.viewState.isLoading)
            }
            .padding(.horizontal, theme.spacing.md)

            ScrollView {
                LazyVStack(spacing: theme.spacing.xxxs) {
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
        VStack(spacing: 12) {
            ProgressView(value: viewModel.importProgress)
                .progressViewStyle(.linear)

            if let currentFile = viewModel.currentFile {
                Text(currentFile)
                    .themedSecondaryLabel()
                    .lineLimit(1)
            }

            Text("\(viewModel.filesProcessed) / \(viewModel.totalFiles)")
                .themedSecondaryLabel()
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
                        .themedTintedButton()
                }
                .buttonStyle(.plain)
            }

            if viewModel.canImport {
                Button(action: viewModel.startImport) {
                    Label(L10n.Import.startImport, systemImage: "square.and.arrow.down")
                        .themedPrimaryButton()
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
                .foregroundStyle(theme.colors.textSecondary)

            VStack(alignment: .leading, spacing: theme.spacing.xxxs) {
                Text(url.lastPathComponent)
                    .font(theme.typography.bodyMedium)
                    .lineLimit(1)

                Text(url.pathExtension.uppercased())
                    .themedSecondaryLabel()
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
        }
        .padding(.vertical, theme.spacing.xs)
        .padding(.horizontal, theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: theme.effects.radiusMD)
                .fill(theme.colors.surfaceSecondary)
        )
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
