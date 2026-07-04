import SwiftUI
import AnchorCore
import AnchorDesign

/// Ribbon visualisation: the day as a horizontal row of cards.
struct RibbonView: View {
    @Environment(\.anchorTheme) private var theme
    let viewModel: DayViewModel
    let onOpen: (UUID) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                ForEach(viewModel.blocks) { block in
                    ribbonCard(block)
                }
            }
            .padding(.vertical, Spacing.xs)
        }
    }

    private func ribbonCard(_ block: TimeBlock) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                CategoryChip(block.category)
                Spacer(minLength: 0)
                Button {
                    Task { await viewModel.toggleDone(blockID: block.id) }
                } label: {
                    Image(systemName: block.state == .done ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(block.state == .done ? theme.accent.color : theme.textSecondary.color)
                }
                .accessibilityLabel(block.state == .done ? "Done" : "Mark done")
            }
            Text(block.title)
                .anchorFont(.body)
                .foregroundStyle(theme.textPrimary.color)
                .lineLimit(2)
            if viewModel.presentation.showsTimes, let start = block.startTime {
                Text(BlockTimeText.short(start))
                    .anchorFont(.caption)
                    .foregroundStyle(theme.textSecondary.color)
            }
        }
        .padding(Spacing.md)
        .frame(width: 180, alignment: .leading)
        .background(theme.surfaceRaised.color)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { onOpen(block.id) }
    }
}
