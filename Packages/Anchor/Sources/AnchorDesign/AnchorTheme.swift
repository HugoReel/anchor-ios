import AnchorCore
import SwiftUI

/// The four user-selectable themes. Sensory accessibility features, not
/// cosmetics: the choice persists in preferences and applies everywhere.
public enum ThemeChoice: String, CaseIterable, Codable, Sendable {
    case calm
    case cool
    case warm
    case lowLight

    public var displayName: String {
        switch self {
        case .calm: "Calm"
        case .cool: "Cool"
        case .warm: "Warm"
        case .lowLight: "Low-light"
        }
    }
}

/// A named text/background pair the automated WCAG audit must verify.
public struct ContrastPair: Sendable {
    public let name: String
    public let foreground: RGBAColor
    public let background: RGBAColor
    public let minimum: Double

    public init(name: String, foreground: RGBAColor, background: RGBAColor, minimum: Double) {
        self.name = name
        self.foreground = foreground
        self.background = background
        self.minimum = minimum
    }
}

/// Semantic colour roles for one theme. All values are declared in the
/// four theme files and verified by `ContrastAuditTests`.
public struct AnchorTheme: Sendable, Hashable {
    public let choice: ThemeChoice
    public let isDark: Bool
    public let background: RGBAColor
    public let surface: RGBAColor
    public let surfaceRaised: RGBAColor
    public let textPrimary: RGBAColor
    public let textSecondary: RGBAColor
    public let accent: RGBAColor
    public let accentText: RGBAColor
    /// Soft highlight for the current block and transition notices.
    /// Deliberately gentle — never red, never alarming.
    public let gentle: RGBAColor

    public init(
        choice: ThemeChoice,
        isDark: Bool,
        background: RGBAColor,
        surface: RGBAColor,
        surfaceRaised: RGBAColor,
        textPrimary: RGBAColor,
        textSecondary: RGBAColor,
        accent: RGBAColor,
        accentText: RGBAColor,
        gentle: RGBAColor
    ) {
        self.choice = choice
        self.isDark = isDark
        self.background = background
        self.surface = surface
        self.surfaceRaised = surfaceRaised
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.accent = accent
        self.accentText = accentText
        self.gentle = gentle
    }

    public static func theme(for choice: ThemeChoice) -> AnchorTheme {
        switch choice {
        case .calm: .calm
        case .cool: .cool
        case .warm: .warm
        case .lowLight: .lowLight
        }
    }

    /// Every text/background pair the WCAG AA audit checks for this theme.
    public var contrastAuditPairs: [ContrastPair] {
        var pairs: [ContrastPair] = [
            ContrastPair(name: "textPrimary on background", foreground: textPrimary, background: background, minimum: 4.5),
            ContrastPair(name: "textPrimary on surface", foreground: textPrimary, background: surface, minimum: 4.5),
            ContrastPair(name: "textPrimary on surfaceRaised", foreground: textPrimary, background: surfaceRaised, minimum: 4.5),
            ContrastPair(name: "textSecondary on background", foreground: textSecondary, background: background, minimum: 4.5),
            ContrastPair(name: "textSecondary on surface", foreground: textSecondary, background: surface, minimum: 4.5),
            ContrastPair(name: "accentText on accent", foreground: accentText, background: accent, minimum: 4.5),
            ContrastPair(name: "textPrimary on gentle", foreground: textPrimary, background: gentle, minimum: 4.5),
            ContrastPair(name: "accent on background (ui component)", foreground: accent, background: background, minimum: 3.0)
        ]
        for category in BlockCategory.allCases {
            pairs.append(
                ContrastPair(
                    name: "textPrimary on \(category.rawValue) chip",
                    foreground: textPrimary,
                    background: CategoryPalette.chipBackground(for: category, in: self),
                    minimum: 4.5
                )
            )
        }
        return pairs
    }
}

private struct AnchorThemeKey: EnvironmentKey {
    static let defaultValue = AnchorTheme.calm
}

extension EnvironmentValues {
    public var anchorTheme: AnchorTheme {
        get { self[AnchorThemeKey.self] }
        set { self[AnchorThemeKey.self] = newValue }
    }
}
