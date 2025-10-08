//
//  ThemedModifiers.swift
//  Kanora
//
//  Created by OpenAI on 08/10/2025.
//

import SwiftUI

/// A helper modifier for consistently styled secondary labels.
struct ThemedSecondaryLabel: ViewModifier {
    @ThemeAccess private var theme

    func body(content: Content) -> some View {
        content
            .font(theme.typography.caption)
            .foregroundStyle(theme.colors.textSecondary)
    }
}

/// A helper modifier for the app's primary, filled buttons.
struct ThemedPrimaryButton: ViewModifier {
    @ThemeAccess private var theme

    func body(content: Content) -> some View {
        content
            .font(theme.typography.labelLarge)
            .foregroundStyle(theme.colors.onAccent)
            .padding(.horizontal, theme.spacing.lg)
            .padding(.vertical, theme.spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: theme.effects.radiusMD)
                    .fill(theme.colors.accent)
            )
    }
}

/// A helper modifier for the app's secondary (tinted) buttons.
struct ThemedTintedButton: ViewModifier {
    @ThemeAccess private var theme

    func body(content: Content) -> some View {
        content
            .font(theme.typography.labelLarge)
            .foregroundStyle(theme.colors.accent)
            .padding(.horizontal, theme.spacing.lg)
            .padding(.vertical, theme.spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: theme.effects.radiusMD)
                    .fill(theme.colors.accent.opacity(0.1))
            )
    }
}

extension View {
    /// Applies the themed styling for secondary labels.
    func themedSecondaryLabel() -> some View {
        modifier(ThemedSecondaryLabel())
    }

    /// Applies the themed styling for primary accent buttons.
    func themedPrimaryButton() -> some View {
        modifier(ThemedPrimaryButton())
    }

    /// Applies the themed styling for tinted secondary buttons.
    func themedTintedButton() -> some View {
        modifier(ThemedTintedButton())
    }
}
