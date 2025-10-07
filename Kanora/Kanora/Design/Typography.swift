//
//  Typography.swift
//  Kanora
//
//  Created by Ben Reed on 07/10/2025.
//

import SwiftUI

// MARK: - Typography System

/// Comprehensive typography system for consistent text styling
/// Provides a complete type scale with semantic naming and responsive sizing
public struct Typography {

    // MARK: - Font Weights
    public enum Weight {
        case ultraLight
        case thin
        case light
        case regular
        case medium
        case semibold
        case bold
        case heavy
        case black

        var fontWeight: Font.Weight {
            switch self {
            case .ultraLight: return .ultraLight
            case .thin: return .thin
            case .light: return .light
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            case .heavy: return .heavy
            case .black: return .black
            }
        }
    }

    // MARK: - Font Families
    public enum Family {
        case system
        case rounded
        case monospaced
        case serif
        case custom(String)

        func font(size: CGFloat, weight: Weight) -> Font {
            switch self {
            case .system:
                return .system(size: size, weight: weight.fontWeight)
            case .rounded:
                return .system(size: size, weight: weight.fontWeight, design: .rounded)
            case .monospaced:
                return .system(size: size, weight: weight.fontWeight, design: .monospaced)
            case .serif:
                return .system(size: size, weight: weight.fontWeight, design: .serif)
            case .custom(let name):
                return .custom(name, size: size)
            }
        }
    }

    // MARK: - Type Scale (Material Design 3 based)
    public enum Scale: CGFloat, CaseIterable {
        case xs = 10
        case sm = 12
        case base = 14
        case md = 16
        case lg = 18
        case xl = 20
        case xl2 = 22
        case xl3 = 24
        case xl4 = 28
        case xl5 = 32
        case xl6 = 36
        case xl7 = 42
        case xl8 = 48
        case xl9 = 56

        /// Get the next larger size
        var larger: Scale {
            let allCases = Scale.allCases
            guard let currentIndex = allCases.firstIndex(of: self),
                  currentIndex < allCases.count - 1 else {
                return self
            }
            return allCases[currentIndex + 1]
        }

        /// Get the next smaller size
        var smaller: Scale {
            let allCases = Scale.allCases
            guard let currentIndex = allCases.firstIndex(of: self),
                  currentIndex > 0 else {
                return self
            }
            return allCases[currentIndex - 1]
        }
    }

    // MARK: - Helper Method
    public static func font(_ scale: Scale, weight: Weight = .regular, family: Family = .system) -> Font {
        family.font(size: scale.rawValue, weight: weight)
    }

    // MARK: - Semantic Type Scale (Material Design 3)

    /// Display fonts - Large, prominent text
    public struct Display {
        public static let large = Typography.font(.xl9, weight: .bold)     // 56pt
        public static let medium = Typography.font(.xl8, weight: .bold)    // 48pt
        public static let small = Typography.font(.xl7, weight: .bold)     // 42pt
    }

    /// Headline fonts - Titles and headings
    public struct Headline {
        public static let large = Typography.font(.xl6, weight: .semibold)    // 36pt
        public static let medium = Typography.font(.xl5, weight: .semibold)   // 32pt
        public static let small = Typography.font(.xl4, weight: .semibold)    // 28pt
    }

    /// Title fonts - Section titles
    public struct Title {
        public static let large = Typography.font(.xl3, weight: .medium)   // 24pt
        public static let medium = Typography.font(.xl2, weight: .medium)  // 22pt
        public static let small = Typography.font(.xl, weight: .medium)    // 20pt
    }

    /// Body fonts - Main content
    public struct Body {
        public static let large = Typography.font(.lg, weight: .regular)   // 18pt
        public static let medium = Typography.font(.md, weight: .regular)  // 16pt
        public static let small = Typography.font(.base, weight: .regular) // 14pt
    }

    /// Label fonts - UI elements
    public struct Label {
        public static let large = Typography.font(.base, weight: .medium)  // 14pt
        public static let medium = Typography.font(.sm, weight: .medium)   // 12pt
        public static let small = Typography.font(.xs, weight: .medium)    // 10pt
    }

    /// Caption fonts - Supporting text
    public struct Caption {
        public static let regular = Typography.font(.sm, weight: .regular)    // 12pt
        public static let emphasis = Typography.font(.sm, weight: .semibold) // 12pt
    }
}
