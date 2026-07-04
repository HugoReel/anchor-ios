import SwiftUI

/// Lexend roles mapped to Dynamic Type. Two weights are enough: SemiBold
/// for display/title, Regular for body/caption. Body never drops below
/// 17 pt at the default content size.
public enum AnchorFont {
    case display
    case title
    case body
    case caption
    case mono

    public var font: Font {
        switch self {
        case .display: .custom("Lexend-SemiBold", size: 28, relativeTo: .title)
        case .title: .custom("Lexend-SemiBold", size: 22, relativeTo: .title2)
        case .body: .custom("Lexend-Regular", size: 17, relativeTo: .body)
        case .caption: .custom("Lexend-Regular", size: 13, relativeTo: .caption)
        case .mono: .system(.body, design: .monospaced)
        }
    }
}

extension View {
    public func anchorFont(_ role: AnchorFont) -> some View {
        font(role.font)
    }
}
