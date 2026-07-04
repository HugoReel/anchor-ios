import SwiftUI

/// A gentle ring showing how much of the day is done (0…1). Descriptive,
/// never a target to hit — there is no "behind" state.
public struct DayProgressRing: View {
    @Environment(\.anchorTheme) private var theme
    private let progress: Double
    private let label: String

    public init(progress: Double, label: String) {
        self.progress = min(max(progress, 0), 1)
        self.label = label
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(theme.gentle.color, lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(theme.accent.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(label)
                .anchorFont(.caption)
                .foregroundStyle(theme.textSecondary.color)
        }
        .frame(width: 64, height: 64)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Day progress")
        .accessibilityValue(label)
    }
}
