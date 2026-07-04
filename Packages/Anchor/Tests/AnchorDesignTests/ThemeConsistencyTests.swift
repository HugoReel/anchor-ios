import Testing
import AnchorCore
@testable import AnchorDesign

private struct HSV {
    let hue: Double
    let saturation: Double
}

private func hsv(of color: RGBAColor) -> HSV {
    let maxComponent = max(color.red, color.green, color.blue)
    let minComponent = min(color.red, color.green, color.blue)
    let delta = maxComponent - minComponent
    var hue = 0.0
    if delta > 0 {
        if maxComponent == color.red {
            hue = 60 * ((color.green - color.blue) / delta).truncatingRemainder(dividingBy: 6)
        } else if maxComponent == color.green {
            hue = 60 * ((color.blue - color.red) / delta + 2)
        } else {
            hue = 60 * ((color.red - color.green) / delta + 4)
        }
    }
    if hue < 0 { hue += 360 }
    let saturation = maxComponent == 0 ? 0 : delta / maxComponent
    return HSV(hue: hue, saturation: saturation)
}

private func hueDistance(_ a: Double, _ b: Double) -> Double {
    let direct = abs(a - b)
    return min(direct, 360 - direct)
}

private let allThemes = ThemeChoice.allCases.map(AnchorTheme.theme(for:))

/// Category colours must stay recognisable across all four themes.
@Test(arguments: BlockCategory.allCases)
func categoryHueConsistentAcrossThemes(category: BlockCategory) {
    let hues = allThemes.map { hsv(of: CategoryPalette.chipBackground(for: category, in: $0)).hue }
    for first in hues {
        for second in hues {
            #expect(
                hueDistance(first, second) <= 40,
                "\(category.rawValue) hue drifts across themes: \(hues)"
            )
        }
    }
}

/// Rest is a first-class category and must read as its own colour.
@Test(arguments: ThemeChoice.allCases)
func restIsDistinctFromOtherCategories(choice: ThemeChoice) {
    let theme = AnchorTheme.theme(for: choice)
    let restHue = hsv(of: CategoryPalette.chipBackground(for: .rest, in: theme)).hue
    for category in BlockCategory.allCases where category != .rest {
        let otherHue = hsv(of: CategoryPalette.chipBackground(for: category, in: theme)).hue
        #expect(
            hueDistance(restHue, otherHue) >= 25,
            "\(choice.rawValue): rest reads too close to \(category.rawValue)"
        )
    }
}

/// "Never red, never alarming": no saturated red-band colour anywhere in
/// any theme's roles or category chips.
@Test(arguments: ThemeChoice.allCases)
func noAlarmRedAnywhere(choice: ThemeChoice) {
    let theme = AnchorTheme.theme(for: choice)
    var colors: [(String, RGBAColor)] = [
        ("background", theme.background),
        ("surface", theme.surface),
        ("surfaceRaised", theme.surfaceRaised),
        ("textPrimary", theme.textPrimary),
        ("textSecondary", theme.textSecondary),
        ("accent", theme.accent),
        ("accentText", theme.accentText),
        ("gentle", theme.gentle)
    ]
    for category in BlockCategory.allCases {
        colors.append((category.rawValue, CategoryPalette.chipBackground(for: category, in: theme)))
    }
    for (name, color) in colors {
        let value = hsv(of: color)
        let inRedBand = (value.hue >= 345 || value.hue <= 15) && value.saturation > 0.5
        #expect(!inRedBand, "\(choice.rawValue): \(name) is a saturated red")
    }
}
