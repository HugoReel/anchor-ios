import SwiftUI
import AnchorDesign

/// Third-party licences. Anchor ships no runtime dependencies; the only
/// bundled asset is the Lexend typeface, used under the SIL Open Font License.
struct LicencesView: View {
    @Environment(\.anchorTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Lexend")
                    .anchorFont(.title)
                    .foregroundStyle(theme.textPrimary.color)
                Text("Copyright The Lexend Project Authors.")
                    .anchorFont(.body)
                    .foregroundStyle(theme.textSecondary.color)
                Text(oflSummary)
                    .anchorFont(.caption)
                    .foregroundStyle(theme.textSecondary.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
        }
        .background(theme.background.color)
        .navigationTitle("Licences")
    }

    private var oflSummary: String {
        """
        This font is licensed under the SIL Open Font License, Version 1.1. \
        The font and its derivatives may be used, studied, modified and \
        redistributed freely as long as they are not sold on their own. The \
        fonts, including any derivative works, can be bundled, embedded and \
        redistributed provided the terms of this licence are met. The full \
        licence text is included with the app in OFL.txt.
        """
    }
}
