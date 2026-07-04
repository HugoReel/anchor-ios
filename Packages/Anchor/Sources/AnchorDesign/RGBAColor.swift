import Foundation
import SwiftUI

/// Design-token colour stored as raw sRGB components so contrast math can
/// run in unit tests without rendering anything.
public struct RGBAColor: Sendable, Hashable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Creates a colour from `0xRRGGBB`.
    public init(_ hex: UInt32, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            alpha: alpha
        )
    }

    public var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    /// WCAG 2.1 relative luminance.
    public var relativeLuminance: Double {
        func linearised(_ component: Double) -> Double {
            component <= 0.04045 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearised(red) + 0.7152 * linearised(green) + 0.0722 * linearised(blue)
    }

    /// WCAG 2.1 contrast ratio, 1…21.
    public func contrastRatio(with other: RGBAColor) -> Double {
        let lighter = max(relativeLuminance, other.relativeLuminance)
        let darker = min(relativeLuminance, other.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }
}
