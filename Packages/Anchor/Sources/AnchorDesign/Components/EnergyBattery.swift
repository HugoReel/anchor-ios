import SwiftUI

/// A 1–5 battery. Read-only here; the interactive picker in Reflect reuses
/// the same five-segment shape so the metaphor stays consistent.
public struct EnergyBattery: View {
    @Environment(\.anchorTheme) private var theme
    private let level: Int

    public init(level: Int) {
        self.level = min(max(level, 0), 5)
    }

    public var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(1...5, id: \.self) { segment in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(segment <= level ? theme.accent.color : theme.gentle.color)
                    .frame(width: 14, height: 22)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Energy")
        .accessibilityValue("\(level) of 5")
    }
}
