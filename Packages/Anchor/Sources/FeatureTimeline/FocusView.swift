import SwiftUI
import AnchorCore
import AnchorDesign

/// Focus visualisation: only now, next, and how many wait later — the
/// lowest-cognitive-load way to see the day.
struct FocusView: View {
    @Environment(\.anchorTheme) private var theme
    let viewModel: DayViewModel
    let onOpen: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            let summary = viewModel.focusSummary
            if let current = summary.current {
                currentCard(current)
            } else {
                betweenBlocksCard
            }
            if let next = summary.next {
                nextRow(next)
            }
            if summary.laterCount > 0 {
                Text(summary.laterCount == 1 ? "1 more later." : "\(summary.laterCount) more later.")
                    .anchorFont(.caption)
                    .foregroundStyle(theme.textSecondary.color)
                    .padding(.leading, Spacing.xs)
            }
        }
    }

    private func currentCard(_ block: TimeBlock) -> some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                AnchorSectionLabel(viewModel.presentation.invitational ? "You could be here" : "Now")
                CategoryChip(block.category)
                Text(block.title)
                    .anchorFont(.display)
                    .foregroundStyle(theme.textPrimary.color)
                Button {
                    Task { await viewModel.toggleDone(blockID: block.id) }
                } label: {
                    Text(viewModel.presentation.invitational ? "Done with this" : "Mark done")
                        .anchorFont(.body)
                        .foregroundStyle(theme.accentText.color)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(theme.accent.color)
                        .clipShape(Capsule())
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onOpen(block.id) }
    }

    private var betweenBlocksCard: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Between things right now.")
                    .anchorFont(.title)
                    .foregroundStyle(theme.textPrimary.color)
                Text("Take the space you need.")
                    .anchorFont(.body)
                    .foregroundStyle(theme.textSecondary.color)
            }
        }
    }

    private func nextRow(_ block: TimeBlock) -> some View {
        AnchorCard {
            HStack(spacing: Spacing.sm) {
                AnchorSectionLabel(viewModel.presentation.invitational ? "Then maybe" : "Next")
                CategoryChip(block.category)
                Text(block.title)
                    .anchorFont(.body)
                    .foregroundStyle(theme.textPrimary.color)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onOpen(block.id) }
    }
}
