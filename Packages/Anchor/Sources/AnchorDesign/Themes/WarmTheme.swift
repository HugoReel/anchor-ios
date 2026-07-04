extension AnchorTheme {
    /// Late-afternoon shore: clay-tinted neutrals with deep clay accents.
    /// Warmth is a deliberate user choice here, not a default — see
    /// DECISIONS.md on the warm-neutral trade-off.
    public static let warm = AnchorTheme(
        choice: .warm,
        isDark: false,
        background: RGBAColor(0xF7EFE8),
        surface: RGBAColor(0xFCF7F2),
        surfaceRaised: RGBAColor(0xFFFFFF),
        textPrimary: RGBAColor(0x3A2E26),
        textSecondary: RGBAColor(0x69564A),
        accent: RGBAColor(0x8F5B3D),
        accentText: RGBAColor(0xFBF4EE),
        gentle: RGBAColor(0xF3E4D8)
    )
}
