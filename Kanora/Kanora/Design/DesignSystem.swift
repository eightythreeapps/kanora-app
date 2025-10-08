//
//  DesignSystem.swift
//  Kanora
//
//  Created by Ben Reed on 07/10/2025.
//

import SwiftUI

// MARK: - Design System Integration

/// Main design system class that provides easy access to theming functionality
/// This is the primary interface for integrating the design system into your app
@MainActor
public class DesignSystem {

    // MARK: - Shared Instance
    public static let shared = DesignSystem()

    private let logger = AppLogger.designSystem

    // MARK: - Theme Manager
    public let themeManager: ThemeManager

    // MARK: - Available Themes
    public static let availableThemes: [any Theme] = [
        ModernTheme(),  // Auto-adapts to light/dark mode
        DefaultTheme(),
        DarkTheme()
    ]

    // MARK: - Initialization
    private init() {
        self.themeManager = ThemeManager(
            defaultTheme: ModernTheme(),
            availableThemes: Self.availableThemes
        )
    }

    // MARK: - Setup Methods

    /// Setup the design system with the app
    public func setup() {
        logger.info("🎨 Design System initialized with \(Self.availableThemes.count) themes")
    }

    /// Setup design system with custom themes
    public func setup(withAdditionalThemes additionalThemes: [any Theme]) {
        themeManager.registerThemes(additionalThemes)
        logger.info("🎨 Design System initialized with \(themeManager.availableThemes.count) themes")
    }
}

// MARK: - App Integration Helpers

extension View {

    /// Apply the design system to your app's root view
    public func designSystem() -> some View {
        self
            .themeManager(DesignSystem.shared.themeManager)
            .onAppear {
                DesignSystem.shared.setup()
            }
    }

    /// Apply the design system with additional themes
    public func designSystem(withAdditionalThemes additionalThemes: [any Theme]) -> some View {
        self
            .themeManager(DesignSystem.shared.themeManager)
            .onAppear {
                DesignSystem.shared.setup(withAdditionalThemes: additionalThemes)
            }
    }
}
