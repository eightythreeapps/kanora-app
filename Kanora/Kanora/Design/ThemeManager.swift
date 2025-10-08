//
//  ThemeManager.swift
//  Kanora
//
//  Created by Ben Reed on 07/10/2025.
//

import SwiftUI
import Combine

// MARK: - Theme Manager

/// Central theme management system
/// Handles theme switching, persistence, and provides theme access throughout the app
@MainActor
public class ThemeManager: ObservableObject {
    // MARK: - Properties

    @Published public private(set) var currentTheme: any Theme
    @Published public private(set) var availableThemes: [any Theme] = []

    private let logger = AppLogger.designSystem

    private let userDefaults = UserDefaults.standard
    private let themeKey = "SelectedThemeID"

    // MARK: - Initialization

    public init(defaultTheme: any Theme, availableThemes: [any Theme] = []) {
        // Initialize available themes first
        let themes = availableThemes.isEmpty ? [defaultTheme] : availableThemes
        self.availableThemes = themes

        // Load saved theme or use default
        let savedThemeID = userDefaults.string(forKey: themeKey)

        // Find the saved theme or use default
        if let savedThemeID = savedThemeID,
           let savedTheme = themes.first(where: { $0.id == savedThemeID }) {
            self.currentTheme = savedTheme
        } else {
            self.currentTheme = defaultTheme
        }
    }

    // MARK: - Public Methods

    /// Switch to a new theme
    public func setTheme(_ theme: any Theme) {
        currentTheme = theme
        userDefaults.set(theme.id, forKey: themeKey)
    }

    /// Switch to theme by ID
    public func setTheme(withID themeID: String) {
        guard let theme = availableThemes.first(where: { $0.id == themeID }) else {
            logger.warning("⚠️ Theme with ID '\(themeID)' not found")
            return
        }
        setTheme(theme)
    }

    /// Register a new theme
    public func registerTheme(_ theme: any Theme) {
        availableThemes.removeAll { $0.id == theme.id }
        availableThemes.append(theme)
    }

    /// Register multiple themes
    public func registerThemes(_ themes: [any Theme]) {
        for theme in themes {
            registerTheme(theme)
        }
    }

    /// Get theme by ID
    public func theme(withID id: String) -> (any Theme)? {
        return availableThemes.first { $0.id == id }
    }

    /// Check if a theme is currently active
    public func isActive(_ theme: any Theme) -> Bool {
        return currentTheme.id == theme.id
    }

    /// Reset to the first available theme (usually the default)
    public func resetToDefault() {
        guard let defaultTheme = availableThemes.first else { return }
        setTheme(defaultTheme)
    }
}

// MARK: - Theme Environment

/// Environment key for accessing the current theme
private struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: any Theme = DefaultTheme()
}

/// Environment key for accessing the theme manager
private struct ThemeManagerEnvironmentKey: EnvironmentKey {
    static let defaultValue: ThemeManager? = nil
}

// MARK: - Environment Extensions

extension EnvironmentValues {
    /// Access the current theme from the environment
    public var theme: any Theme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }

    /// Access the theme manager from the environment
    public var themeManager: ThemeManager? {
        get { self[ThemeManagerEnvironmentKey.self] }
        set { self[ThemeManagerEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply a theme to the view hierarchy
    public func theme(_ theme: any Theme) -> some View {
        environment(\.theme, theme)
    }

    /// Apply theme manager to the view hierarchy with automatic color scheme adaptation
    public func themeManager(_ themeManager: ThemeManager) -> some View {
        ColorSchemeAwareThemeView(themeManager: themeManager, content: self)
    }

    /// Apply themed styling to a view
    public func themedStyle<S: ViewModifier>(_ styling: @escaping (any Theme) -> S) -> some View {
        modifier(ThemedStyleModifier(styling: styling))
    }
}

// MARK: - Themed Style Modifier

private struct ThemedStyleModifier<S: ViewModifier>: ViewModifier {
    @Environment(\.theme) private var theme
    let styling: (any Theme) -> S

    func body(content: Content) -> some View {
        content.modifier(styling(theme))
    }
}

// MARK: - Theme Access Helpers

/// Property wrapper for accessing theme from environment
@propertyWrapper
public struct ThemeAccess: DynamicProperty {
    @Environment(\.theme) private var theme

    public var wrappedValue: any Theme {
        theme
    }

    public init() {}
}

/// Property wrapper for accessing theme manager from environment
@propertyWrapper
public struct ThemeManagerAccess: DynamicProperty {
    @Environment(\.themeManager) private var themeManager

    public var wrappedValue: ThemeManager? {
        themeManager
    }

    public init() {}
}

// MARK: - Themed View Protocol

/// Protocol for views that can be styled with themes
public protocol ThemedView: View {
    associatedtype ThemedBody: View

    /// The themed body of the view
    @ViewBuilder func themedBody(theme: any Theme) -> ThemedBody
}

extension ThemedView {
    public var body: some View {
        ThemedViewWrapper(themedView: self)
    }
}

/// Wrapper for themed views
private struct ThemedViewWrapper<T: ThemedView>: View {
    @Environment(\.theme) private var theme
    let themedView: T

    var body: some View {
        themedView.themedBody(theme: theme)
    }
}

// MARK: - Color Scheme Aware Theme View

/// View wrapper that automatically adapts theme to system color scheme
private struct ColorSchemeAwareThemeView<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var themeManager: ThemeManager
    let content: Content

    init(themeManager: ThemeManager, content: Content) {
        self.themeManager = themeManager
        self.content = content
    }

    private var adaptedTheme: any Theme {
        // If current theme is ModernTheme, adapt it to color scheme
        if themeManager.currentTheme.id == "kanora.modern" {
            return ModernTheme(colorScheme: colorScheme)
        }
        return themeManager.currentTheme
    }

    var body: some View {
        content
            .environment(\.themeManager, themeManager)
            .environment(\.theme, adaptedTheme)
    }
}
