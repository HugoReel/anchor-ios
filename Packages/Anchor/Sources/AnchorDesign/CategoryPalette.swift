import AnchorCore

/// Category chip colours. Hues stay recognisably consistent across all four
/// themes (verified by `ThemeConsistencyTests`): light themes share one
/// pastel set; Low-light uses darker variants of the same hues.
public enum CategoryPalette {
    public static func chipBackground(for category: BlockCategory, in theme: AnchorTheme) -> RGBAColor {
        theme.isDark ? darkChip(for: category) : lightChip(for: category)
    }

    private static func lightChip(for category: BlockCategory) -> RGBAColor {
        switch category {
        case .focus: RGBAColor(0xDCE3F5)
        case .care: RGBAColor(0xF6DFE4)
        case .home: RGBAColor(0xF2E6CF)
        case .connect: RGBAColor(0xE9DFF2)
        case .out: RGBAColor(0xD7ECEA)
        case .rest: RGBAColor(0xDEEBDD)
        }
    }

    private static func darkChip(for category: BlockCategory) -> RGBAColor {
        switch category {
        case .focus: RGBAColor(0x2E3A57)
        case .care: RGBAColor(0x4A3238)
        case .home: RGBAColor(0x453A26)
        case .connect: RGBAColor(0x3E3350)
        case .out: RGBAColor(0x24413E)
        case .rest: RGBAColor(0x2C4030)
        }
    }
}
