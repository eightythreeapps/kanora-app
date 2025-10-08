//
//  LibrarySearchBar.swift
//  Kanora
//
//  Created by OpenAI on 17/03/2024.
//

import SwiftUI

/// A reusable search bar styled using the design system theme.
struct LibrarySearchBar: View {
    @ThemeAccess private var theme

    private let placeholder: LocalizedStringKey
    private let accessibilityLabel: LocalizedStringKey?
    @Binding private var text: String
    private let textFieldIdentifier: String?
    private let clearButtonIdentifier: String?

    init(
        placeholder: LocalizedStringKey,
        text: Binding<String>,
        accessibilityLabel: LocalizedStringKey? = nil,
        textFieldIdentifier: String? = nil,
        clearButtonIdentifier: String? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.accessibilityLabel = accessibilityLabel
        self.textFieldIdentifier = textFieldIdentifier
        self.clearButtonIdentifier = clearButtonIdentifier
    }

    var body: some View {
        HStack(spacing: theme.spacing.iconSpacing) {
            Image(systemName: "magnifyingglass")
                .font(theme.typography.bodyMedium)
                .foregroundStyle(theme.colors.textSecondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(theme.typography.bodyMedium)
                .foregroundStyle(theme.colors.textPrimary)
                .accessibilityLabel(Text(accessibilityLabel ?? placeholder))
                .applyAccessibilityIdentifier(textFieldIdentifier)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(theme.colors.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(L10n.Actions.clear))
                .applyAccessibilityIdentifier(clearButtonIdentifier)
            }
        }
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.xs)
        .background(theme.colors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: theme.effects.radiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: theme.effects.radiusMD)
                .stroke(theme.colors.borderSecondary, lineWidth: 1)
        )
        .padding(.horizontal, theme.spacing.contentPadding)
        .padding(.vertical, theme.spacing.sm)
    }
}

private extension View {
    @ViewBuilder
    func applyAccessibilityIdentifier(_ identifier: String?) -> some View {
        if let identifier {
            accessibilityIdentifier(identifier)
        } else {
            self
        }
    }
}

#Preview("Empty") {
    LibrarySearchBar(
        placeholder: L10n.Library.searchArtists,
        text: .constant("")
    )
    .theme(ModernTheme())
}

#Preview("With Text") {
    LibrarySearchBar(
        placeholder: L10n.Library.searchArtists,
        text: .constant("Tame Impala"),
        accessibilityLabel: L10n.Library.searchArtists,
        textFieldIdentifier: "library-search-field",
        clearButtonIdentifier: "library-search-clear"
    )
    .theme(ModernTheme(colorScheme: .dark))
}
