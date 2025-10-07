//
//  DefaultTheme.swift
//  Kanora
//
//  Created by Ben Reed on 07/10/2025.
//

import SwiftUI

// MARK: - Default Theme Implementation

/// The default theme for Kanora app
/// Wraps ModernTheme for light mode
public struct DefaultTheme: Theme {
    private let modernTheme = ModernTheme(colorScheme: .light)

    public var name: String { "Kanora Default" }
    public var id: String { "kanora.default" }
    public var colors: ColorTokens { modernTheme.colors }
    public var typography: TypographyTokens { modernTheme.typography }
    public var spacing: SpacingTokens { modernTheme.spacing }
    public var effects: EffectTokens { modernTheme.effects }
    public var layout: LayoutTokens { modernTheme.layout }
    public var gradientBackground: GradientBackground { modernTheme.gradientBackground }

    public init() {}
}

// MARK: - Dark Theme Variant

/// Dark theme variant of the default theme
/// Wraps ModernTheme for dark mode
public struct DarkTheme: Theme {
    private let modernTheme = ModernTheme(colorScheme: .dark)

    public var name: String { "Kanora Dark" }
    public var id: String { "kanora.dark" }
    public var colors: ColorTokens { modernTheme.colors }
    public var typography: TypographyTokens { modernTheme.typography }
    public var spacing: SpacingTokens { modernTheme.spacing }
    public var effects: EffectTokens { modernTheme.effects }
    public var layout: LayoutTokens { modernTheme.layout }
    public var gradientBackground: GradientBackground { modernTheme.gradientBackground }

    public init() {}
}
