//
//  ModernTheme.swift
//  Kanora
//
//  Created by Ben Reed on 07/10/2025.
//

import SwiftUI

// MARK: - Modern Theme Implementation

/// Modern theme for Kanora app
/// Automatically adapts to light/dark mode
public struct ModernTheme: Theme {

    // MARK: - Identity
    public let name: String = "Modern"
    public let id: String = "kanora.modern"

    // MARK: - Design Tokens
    public let colors: ColorTokens
    public let typography: TypographyTokens
    public let spacing: SpacingTokens
    public let effects: EffectTokens
    public let layout: LayoutTokens
    public let gradientBackground: GradientBackground

    // MARK: - Color Scheme
    private let colorScheme: ColorScheme?

    // MARK: - Initialization
    public init(colorScheme: ColorScheme? = nil) {
        self.colorScheme = colorScheme
        self.colors = Self.createModernColorTokens(for: colorScheme ?? .light)
        self.typography = Self.createTypographyTokens()
        self.spacing = SpacingTokens()
        self.effects = EffectTokens()
        self.layout = LayoutTokens()

        self.gradientBackground = GradientBackground(
            colors: colorScheme == .dark ? [
                Color(red: 0.04, green: 0.08, blue: 0.12),
                Color(red: 0.08, green: 0.12, blue: 0.16)
            ] : [
                Color(red: 0.96, green: 0.97, blue: 0.98),
                Color.white
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Modern Color Tokens Creation
    private static func createModernColorTokens(for colorScheme: ColorScheme) -> ColorTokens {
        var builder = ColorTokensBuilder()

        if colorScheme == .dark {
            // Dark Mode Colors
            builder.primary = Color.blue.opacity(0.9)
            builder.primaryVariant = Color.blue.opacity(0.7)
            builder.onPrimary = .black
            builder.secondary = Color.purple.opacity(0.9)
            builder.secondaryVariant = Color.purple.opacity(0.7)
            builder.onSecondary = .black
            builder.accent = Color.teal.opacity(0.9)
            builder.accentVariant = Color.teal.opacity(0.7)
            builder.onAccent = .black
            builder.background = Color(red: 0.04, green: 0.08, blue: 0.12)
            builder.backgroundSecondary = Color(red: 0.08, green: 0.12, blue: 0.16)
            builder.backgroundTertiary = Color(red: 0.12, green: 0.16, blue: 0.20)
            builder.surface = Color(red: 0.08, green: 0.12, blue: 0.16)
            builder.surfaceSecondary = Color(red: 0.12, green: 0.16, blue: 0.20)
            builder.onBackground = .white
            builder.onSurface = .white
            builder.textPrimary = .white
            builder.textSecondary = Color.white.opacity(0.7)
            builder.textTertiary = Color.white.opacity(0.5)
            builder.success = Color.green.opacity(0.9)
            builder.successVariant = Color.green.opacity(0.7)
            builder.onSuccess = .black
            builder.warning = Color.orange.opacity(0.9)
            builder.warningVariant = Color.orange.opacity(0.7)
            builder.onWarning = .black
            builder.error = Color.red.opacity(0.9)
            builder.errorVariant = Color.red.opacity(0.7)
            builder.onError = .black
            builder.info = Color.blue.opacity(0.9)
            builder.infoVariant = Color.blue.opacity(0.7)
            builder.onInfo = .black
            builder.interactive = Color.teal.opacity(0.9)
            builder.interactiveHover = Color.teal.opacity(0.7)
            builder.interactivePressed = Color.teal.opacity(0.5)
            builder.interactiveDisabled = Color.white.opacity(0.3)
            builder.border = Color.white.opacity(0.15)
            builder.borderSecondary = Color.white.opacity(0.1)
            builder.borderTertiary = Color.white.opacity(0.05)
            builder.overlay = Color.white.opacity(0.15)
            builder.overlaySecondary = Color.white.opacity(0.08)
            builder.scrim = Color.black.opacity(0.6)
        } else {
            // Light Mode Colors
            builder.primary = .blue
            builder.primaryVariant = Color.blue.opacity(0.8)
            builder.onPrimary = .white
            builder.secondary = .purple
            builder.secondaryVariant = Color.purple.opacity(0.8)
            builder.onSecondary = .white
            builder.accent = .teal
            builder.accentVariant = Color.teal.opacity(0.8)
            builder.onAccent = .white
            builder.background = .white
            builder.backgroundSecondary = Color(red: 0.96, green: 0.97, blue: 0.98)
            builder.backgroundTertiary = Color(red: 0.93, green: 0.94, blue: 0.95)
            builder.surface = .white
            builder.surfaceSecondary = Color(red: 0.96, green: 0.97, blue: 0.98)
            builder.onBackground = .black
            builder.onSurface = .black
            builder.textPrimary = .black
            builder.textSecondary = Color.black.opacity(0.7)
            builder.textTertiary = Color.black.opacity(0.5)
            builder.success = .green
            builder.successVariant = Color.green.opacity(0.8)
            builder.onSuccess = .white
            builder.warning = .orange
            builder.warningVariant = Color.orange.opacity(0.8)
            builder.onWarning = .white
            builder.error = .red
            builder.errorVariant = Color.red.opacity(0.8)
            builder.onError = .white
            builder.info = .blue
            builder.infoVariant = Color.blue.opacity(0.8)
            builder.onInfo = .white
            builder.interactive = .teal
            builder.interactiveHover = Color.teal.opacity(0.8)
            builder.interactivePressed = Color.teal.opacity(0.6)
            builder.interactiveDisabled = .gray
            builder.border = Color.gray.opacity(0.3)
            builder.borderSecondary = Color.gray.opacity(0.2)
            builder.borderTertiary = Color.gray.opacity(0.1)
            builder.overlay = Color.black.opacity(0.25)
            builder.overlaySecondary = Color.black.opacity(0.10)
            builder.scrim = Color.black.opacity(0.4)
        }

        return builder.build()
    }

    // MARK: - Typography Tokens Creation
    private static func createTypographyTokens() -> TypographyTokens {
        TypographyTokens(
            displayLarge: Typography.Display.large,
            displayMedium: Typography.Display.medium,
            displaySmall: Typography.Display.small,
            headlineLarge: Typography.Headline.large,
            headlineMedium: Typography.Headline.medium,
            headlineSmall: Typography.Headline.small,
            titleLarge: Typography.Title.large,
            titleMedium: Typography.Title.medium,
            titleSmall: Typography.Title.small,
            bodyLarge: Typography.Body.large,
            bodyMedium: Typography.Body.medium,
            bodySmall: Typography.Body.small,
            labelLarge: Typography.Label.large,
            labelMedium: Typography.Label.medium,
            labelSmall: Typography.Label.small,
            caption: Typography.Caption.regular,
            captionEmphasis: Typography.Caption.emphasis
        )
    }
}
