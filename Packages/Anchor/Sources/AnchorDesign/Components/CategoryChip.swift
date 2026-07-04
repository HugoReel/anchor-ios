import SwiftUI
import AnchorCore

/// A small, calm pill naming a block's category in its theme colour.
public struct CategoryChip: View {
    @Environment(\.anchorTheme) private var theme
    private let category: BlockCategory

    public init(_ category: BlockCategory) {
        self.category = category
    }

    public var body: some View {
        Text(category.displayName)
            .anchorFont(.caption)
            .foregroundStyle(theme.textPrimary.color)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(CategoryPalette.chipBackground(for: category, in: theme).color)
            .clipShape(Capsule())
            .accessibilityLabel("\(category.displayName) block")
    }
}
