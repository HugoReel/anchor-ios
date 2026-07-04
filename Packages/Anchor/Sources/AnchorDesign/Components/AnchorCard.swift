import SwiftUI

/// A calm surface container. One level only — nested cards are never used.
/// Reads the current theme from the environment.
public struct AnchorCard<Content: View>: View {
    @Environment(\.anchorTheme) private var theme
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(theme.surfaceRaised.color)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

/// A quiet section heading: an eyebrow label followed by its content. Used
/// sparingly, only where the label encodes something true about the section.
public struct AnchorSectionLabel: View {
    @Environment(\.anchorTheme) private var theme
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .anchorFont(.caption)
            .foregroundStyle(theme.textSecondary.color)
            .accessibilityAddTraits(.isHeader)
    }
}
