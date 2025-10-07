//
//  Theme.swift
//  Kanora
//
//  Created by Ben Reed on 07/10/2025.
//

import SwiftUI

// MARK: - Core Theme Protocol

/// Core theme protocol defining all design tokens for the application
/// This protocol ensures consistent theming across the app and enables easy theme switching
public protocol Theme {
    // MARK: - Identity
    var name: String { get }
    var id: String { get }

    // MARK: - Color System
    var colors: ColorTokens { get }

    // MARK: - Typography System
    var typography: TypographyTokens { get }

    // MARK: - Spacing System
    var spacing: SpacingTokens { get }

    // MARK: - Effects System
    var effects: EffectTokens { get }

    // MARK: - Layout System
    var layout: LayoutTokens { get }

    // MARK: - Background System
    var gradientBackground: GradientBackground { get }
}

// MARK: - Color Tokens

public struct ColorTokensBuilder {
    public var primary: Color = .blue
    public var primaryVariant: Color = .blue
    public var onPrimary: Color = .white
    public var secondary: Color = .purple
    public var secondaryVariant: Color = .purple
    public var onSecondary: Color = .white
    public var accent: Color = .blue
    public var accentVariant: Color = .blue
    public var onAccent: Color = .white
    public var background: Color = .white
    public var backgroundSecondary: Color = .white
    public var backgroundTertiary: Color = .white
    public var surface: Color = .white
    public var surfaceSecondary: Color = .white
    public var onBackground: Color = .black
    public var onSurface: Color = .black
    public var textPrimary: Color = .black
    public var textSecondary: Color = .gray
    public var textTertiary: Color = .gray
    public var success: Color = .green
    public var successVariant: Color = .green
    public var onSuccess: Color = .white
    public var warning: Color = .orange
    public var warningVariant: Color = .orange
    public var onWarning: Color = .white
    public var error: Color = .red
    public var errorVariant: Color = .red
    public var onError: Color = .white
    public var info: Color = .blue
    public var infoVariant: Color = .blue
    public var onInfo: Color = .white
    public var interactive: Color = .blue
    public var interactiveHover: Color = .blue
    public var interactivePressed: Color = .blue
    public var interactiveDisabled: Color = .gray
    public var border: Color = .gray
    public var borderSecondary: Color = .gray
    public var borderTertiary: Color = .gray
    public var overlay: Color = .black
    public var overlaySecondary: Color = .black
    public var scrim: Color = .black

    public init() {}

    public func build() -> ColorTokens {
        ColorTokens(
            primary: primary, primaryVariant: primaryVariant, onPrimary: onPrimary,
            secondary: secondary, secondaryVariant: secondaryVariant, onSecondary: onSecondary,
            accent: accent, accentVariant: accentVariant, onAccent: onAccent,
            background: background, backgroundSecondary: backgroundSecondary, backgroundTertiary: backgroundTertiary,
            surface: surface, surfaceSecondary: surfaceSecondary,
            onBackground: onBackground, onSurface: onSurface,
            textPrimary: textPrimary, textSecondary: textSecondary, textTertiary: textTertiary,
            success: success, successVariant: successVariant, onSuccess: onSuccess,
            warning: warning, warningVariant: warningVariant, onWarning: onWarning,
            error: error, errorVariant: errorVariant, onError: onError,
            info: info, infoVariant: infoVariant, onInfo: onInfo,
            interactive: interactive, interactiveHover: interactiveHover, interactivePressed: interactivePressed, interactiveDisabled: interactiveDisabled,
            border: border, borderSecondary: borderSecondary, borderTertiary: borderTertiary,
            overlay: overlay, overlaySecondary: overlaySecondary, scrim: scrim
        )
    }
}

public struct ColorTokens {
    // MARK: - Primary Colors
    public let primary: Color
    public let primaryVariant: Color
    public let onPrimary: Color

    // MARK: - Secondary Colors
    public let secondary: Color
    public let secondaryVariant: Color
    public let onSecondary: Color

    // MARK: - Accent Colors
    public let accent: Color
    public let accentVariant: Color
    public let onAccent: Color

    // MARK: - Background Colors
    public let background: Color
    public let backgroundSecondary: Color
    public let backgroundTertiary: Color
    public let surface: Color
    public let surfaceSecondary: Color

    // MARK: - Content Colors
    public let onBackground: Color
    public let onSurface: Color
    public let textPrimary: Color
    public let textSecondary: Color
    public let textTertiary: Color

    // MARK: - Semantic Colors
    public let success: Color
    public let successVariant: Color
    public let onSuccess: Color

    public let warning: Color
    public let warningVariant: Color
    public let onWarning: Color

    public let error: Color
    public let errorVariant: Color
    public let onError: Color

    public let info: Color
    public let infoVariant: Color
    public let onInfo: Color

    // MARK: - Interactive Colors
    public let interactive: Color
    public let interactiveHover: Color
    public let interactivePressed: Color
    public let interactiveDisabled: Color

    // MARK: - Border Colors
    public let border: Color
    public let borderSecondary: Color
    public let borderTertiary: Color

    // MARK: - Overlay Colors
    public let overlay: Color
    public let overlaySecondary: Color
    public let scrim: Color

    public init(
        primary: Color,
        primaryVariant: Color,
        onPrimary: Color,
        secondary: Color,
        secondaryVariant: Color,
        onSecondary: Color,
        accent: Color,
        accentVariant: Color,
        onAccent: Color,
        background: Color,
        backgroundSecondary: Color,
        backgroundTertiary: Color,
        surface: Color,
        surfaceSecondary: Color,
        onBackground: Color,
        onSurface: Color,
        textPrimary: Color,
        textSecondary: Color,
        textTertiary: Color,
        success: Color,
        successVariant: Color,
        onSuccess: Color,
        warning: Color,
        warningVariant: Color,
        onWarning: Color,
        error: Color,
        errorVariant: Color,
        onError: Color,
        info: Color,
        infoVariant: Color,
        onInfo: Color,
        interactive: Color,
        interactiveHover: Color,
        interactivePressed: Color,
        interactiveDisabled: Color,
        border: Color,
        borderSecondary: Color,
        borderTertiary: Color,
        overlay: Color,
        overlaySecondary: Color,
        scrim: Color
    ) {
        self.primary = primary
        self.primaryVariant = primaryVariant
        self.onPrimary = onPrimary
        self.secondary = secondary
        self.secondaryVariant = secondaryVariant
        self.onSecondary = onSecondary
        self.accent = accent
        self.accentVariant = accentVariant
        self.onAccent = onAccent
        self.background = background
        self.backgroundSecondary = backgroundSecondary
        self.backgroundTertiary = backgroundTertiary
        self.surface = surface
        self.surfaceSecondary = surfaceSecondary
        self.onBackground = onBackground
        self.onSurface = onSurface
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.textTertiary = textTertiary
        self.success = success
        self.successVariant = successVariant
        self.onSuccess = onSuccess
        self.warning = warning
        self.warningVariant = warningVariant
        self.onWarning = onWarning
        self.error = error
        self.errorVariant = errorVariant
        self.onError = onError
        self.info = info
        self.infoVariant = infoVariant
        self.onInfo = onInfo
        self.interactive = interactive
        self.interactiveHover = interactiveHover
        self.interactivePressed = interactivePressed
        self.interactiveDisabled = interactiveDisabled
        self.border = border
        self.borderSecondary = borderSecondary
        self.borderTertiary = borderTertiary
        self.overlay = overlay
        self.overlaySecondary = overlaySecondary
        self.scrim = scrim
    }
}

// MARK: - Typography Tokens

public struct TypographyTokens {
    // MARK: - Display Fonts
    public let displayLarge: Font
    public let displayMedium: Font
    public let displaySmall: Font

    // MARK: - Headline Fonts
    public let headlineLarge: Font
    public let headlineMedium: Font
    public let headlineSmall: Font

    // MARK: - Title Fonts
    public let titleLarge: Font
    public let titleMedium: Font
    public let titleSmall: Font

    // MARK: - Body Fonts
    public let bodyLarge: Font
    public let bodyMedium: Font
    public let bodySmall: Font

    // MARK: - Label Fonts
    public let labelLarge: Font
    public let labelMedium: Font
    public let labelSmall: Font

    // MARK: - Caption Fonts
    public let caption: Font
    public let captionEmphasis: Font

    public init(
        displayLarge: Font,
        displayMedium: Font,
        displaySmall: Font,
        headlineLarge: Font,
        headlineMedium: Font,
        headlineSmall: Font,
        titleLarge: Font,
        titleMedium: Font,
        titleSmall: Font,
        bodyLarge: Font,
        bodyMedium: Font,
        bodySmall: Font,
        labelLarge: Font,
        labelMedium: Font,
        labelSmall: Font,
        caption: Font,
        captionEmphasis: Font
    ) {
        self.displayLarge = displayLarge
        self.displayMedium = displayMedium
        self.displaySmall = displaySmall
        self.headlineLarge = headlineLarge
        self.headlineMedium = headlineMedium
        self.headlineSmall = headlineSmall
        self.titleLarge = titleLarge
        self.titleMedium = titleMedium
        self.titleSmall = titleSmall
        self.bodyLarge = bodyLarge
        self.bodyMedium = bodyMedium
        self.bodySmall = bodySmall
        self.labelLarge = labelLarge
        self.labelMedium = labelMedium
        self.labelSmall = labelSmall
        self.caption = caption
        self.captionEmphasis = captionEmphasis
    }
}

// MARK: - Spacing Tokens

public struct SpacingTokens {
    // MARK: - Base Spacing Scale (8pt grid)
    public let xxxs: CGFloat    // 2pt
    public let xxs: CGFloat     // 4pt
    public let xs: CGFloat      // 8pt
    public let sm: CGFloat      // 12pt
    public let md: CGFloat      // 16pt
    public let lg: CGFloat      // 20pt
    public let xl: CGFloat      // 24pt
    public let xxl: CGFloat     // 32pt
    public let xxxl: CGFloat    // 40pt
    public let xxxxl: CGFloat   // 48pt

    // MARK: - Semantic Spacing
    public let contentPadding: CGFloat
    public let sectionSpacing: CGFloat
    public let itemSpacing: CGFloat
    public let iconSpacing: CGFloat

    public init(
        xxxs: CGFloat = 2,
        xxs: CGFloat = 4,
        xs: CGFloat = 8,
        sm: CGFloat = 12,
        md: CGFloat = 16,
        lg: CGFloat = 20,
        xl: CGFloat = 24,
        xxl: CGFloat = 32,
        xxxl: CGFloat = 40,
        xxxxl: CGFloat = 48,
        contentPadding: CGFloat = 16,
        sectionSpacing: CGFloat = 20,
        itemSpacing: CGFloat = 12,
        iconSpacing: CGFloat = 8
    ) {
        self.xxxs = xxxs
        self.xxs = xxs
        self.xs = xs
        self.sm = sm
        self.md = md
        self.lg = lg
        self.xl = xl
        self.xxl = xxl
        self.xxxl = xxxl
        self.xxxxl = xxxxl
        self.contentPadding = contentPadding
        self.sectionSpacing = sectionSpacing
        self.itemSpacing = itemSpacing
        self.iconSpacing = iconSpacing
    }
}

// MARK: - Effect Tokens

public struct EffectTokens {
    // MARK: - Corner Radius
    public let radiusXS: CGFloat
    public let radiusSM: CGFloat
    public let radiusMD: CGFloat
    public let radiusLG: CGFloat
    public let radiusXL: CGFloat
    public let radiusXXL: CGFloat

    // MARK: - Shadow Styles
    public let shadowSmall: Shadow
    public let shadowMedium: Shadow
    public let shadowLarge: Shadow
    public let shadowXLarge: Shadow

    // MARK: - Material Styles
    public let materialThin: Material
    public let materialRegular: Material
    public let materialThick: Material
    public let materialUltraThin: Material

    // MARK: - Blur Effects
    public let blurLight: CGFloat
    public let blurMedium: CGFloat
    public let blurHeavy: CGFloat

    public init(
        radiusXS: CGFloat = 4,
        radiusSM: CGFloat = 8,
        radiusMD: CGFloat = 12,
        radiusLG: CGFloat = 16,
        radiusXL: CGFloat = 20,
        radiusXXL: CGFloat = 28,
        shadowSmall: Shadow = Shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1),
        shadowMedium: Shadow = Shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2),
        shadowLarge: Shadow = Shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4),
        shadowXLarge: Shadow = Shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8),
        materialThin: Material = .thin,
        materialRegular: Material = .regular,
        materialThick: Material = .thick,
        materialUltraThin: Material = .ultraThin,
        blurLight: CGFloat = 5,
        blurMedium: CGFloat = 10,
        blurHeavy: CGFloat = 20
    ) {
        self.radiusXS = radiusXS
        self.radiusSM = radiusSM
        self.radiusMD = radiusMD
        self.radiusLG = radiusLG
        self.radiusXL = radiusXL
        self.radiusXXL = radiusXXL
        self.shadowSmall = shadowSmall
        self.shadowMedium = shadowMedium
        self.shadowLarge = shadowLarge
        self.shadowXLarge = shadowXLarge
        self.materialThin = materialThin
        self.materialRegular = materialRegular
        self.materialThick = materialThick
        self.materialUltraThin = materialUltraThin
        self.blurLight = blurLight
        self.blurMedium = blurMedium
        self.blurHeavy = blurHeavy
    }
}

// MARK: - Layout Tokens

public struct LayoutTokens {
    // MARK: - Breakpoints
    public let breakpointCompact: CGFloat
    public let breakpointRegular: CGFloat
    public let breakpointLarge: CGFloat

    // MARK: - Maximum Widths
    public let maxContentWidth: CGFloat
    public let maxDialogWidth: CGFloat
    public let maxCardWidth: CGFloat

    // MARK: - Minimum Sizes
    public let minTappableSize: CGFloat
    public let minButtonHeight: CGFloat
    public let minTextFieldHeight: CGFloat

    public init(
        breakpointCompact: CGFloat = 320,
        breakpointRegular: CGFloat = 768,
        breakpointLarge: CGFloat = 1024,
        maxContentWidth: CGFloat = 1200,
        maxDialogWidth: CGFloat = 560,
        maxCardWidth: CGFloat = 400,
        minTappableSize: CGFloat = 44,
        minButtonHeight: CGFloat = 44,
        minTextFieldHeight: CGFloat = 44
    ) {
        self.breakpointCompact = breakpointCompact
        self.breakpointRegular = breakpointRegular
        self.breakpointLarge = breakpointLarge
        self.maxContentWidth = maxContentWidth
        self.maxDialogWidth = maxDialogWidth
        self.maxCardWidth = maxCardWidth
        self.minTappableSize = minTappableSize
        self.minButtonHeight = minButtonHeight
        self.minTextFieldHeight = minTextFieldHeight
    }
}

// MARK: - Supporting Types

public struct Shadow {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat

    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

public struct GradientBackground {
    public let colors: [Color]
    public let startPoint: UnitPoint
    public let endPoint: UnitPoint

    public init(colors: [Color], startPoint: UnitPoint, endPoint: UnitPoint) {
        self.colors = colors
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
}
