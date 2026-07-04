import SwiftUI
import AnchorCore
import AnchorDesign

/// Neutral, descriptive patterns — counts and trends, never judgements.
struct PatternsView: View {
    @Environment(\.anchorTheme) private var theme
    let viewModel: ReflectViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                let patterns = viewModel.patterns
                if patterns.checkInCount == 0 {
                    AnchorCard {
                        Text("Once you've checked in a few times, gentle patterns will show here.")
                            .anchorFont(.body)
                            .foregroundStyle(theme.textSecondary.color)
                    }
                } else {
                    AnchorCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            ForEach(patterns.summaryLines, id: \.self) { line in
                                Text(line)
                                    .anchorFont(.body)
                                    .foregroundStyle(theme.textPrimary.color)
                            }
                        }
                    }
                    if !patterns.topBodySensations.isEmpty {
                        AnchorCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                AnchorSectionLabel("Sensations you've noted")
                                ForEach(patterns.topBodySensations, id: \.label) { sensation in
                                    HStack {
                                        Text(sensation.label)
                                            .anchorFont(.body)
                                            .foregroundStyle(theme.textPrimary.color)
                                        Spacer(minLength: 0)
                                        Text("\(sensation.count)")
                                            .anchorFont(.caption)
                                            .foregroundStyle(theme.textSecondary.color)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(Spacing.md)
        }
        .background(theme.background.color)
        .navigationTitle("Patterns")
        .navigationBarTitleDisplayMode(.inline)
    }
}
