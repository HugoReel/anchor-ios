import Testing
@testable import AnchorDesign

/// Automated WCAG AA audit: every declared text/background pair in every
/// theme must meet its minimum ratio. Failing this test blocks the build —
/// palette changes must keep contrast, not promise it.
@Test(arguments: ThemeChoice.allCases)
func allAuditPairsMeetWCAG(choice: ThemeChoice) {
    let theme = AnchorTheme.theme(for: choice)
    for pair in theme.contrastAuditPairs {
        let ratio = pair.foreground.contrastRatio(with: pair.background)
        #expect(
            ratio >= pair.minimum,
            "\(choice.rawValue): \(pair.name) is \(ratio), needs \(pair.minimum)"
        )
    }
}

@Test func blackOnWhiteRatioIsTwentyOne() {
    let white = RGBAColor(0xFFFFFF)
    let black = RGBAColor(0x000000)
    #expect(abs(white.contrastRatio(with: black) - 21.0) < 0.01)
}

@Test func contrastRatioIsSymmetric() {
    let a = RGBAColor(0x3E6B57)
    let b = RGBAColor(0xF2F5F1)
    #expect(abs(a.contrastRatio(with: b) - b.contrastRatio(with: a)) < 0.0001)
}
