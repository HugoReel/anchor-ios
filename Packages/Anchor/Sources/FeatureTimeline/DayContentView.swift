import SwiftUI
import AnchorCore
import AnchorDesign

/// Agenda visualisation of the day: a calm vertical list. Ribbon and Focus
/// visualisations reuse this view model in a later increment.
struct DayContentView: View {
    @Environment(\.anchorTheme) private var theme
    let viewModel: DayViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                controls
                if viewModel.blocks.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.blocks) { block in
                        AgendaRow(
                            block: block,
                            showsTimes: viewModel.presentation.showsTimes,
                            onToggle: { Task { await viewModel.toggleDone(blockID: block.id) } }
                        )
                    }
                }
            }
            .padding(Spacing.md)
        }
        .background(theme.background.color)
    }

    private var controls: some View {
        HStack(spacing: Spacing.sm) {
            Button {
                Task { await viewModel.switchMode() }
            } label: {
                Label(
                    viewModel.plan.mode == .clock ? "Sequence" : "Clock",
                    systemImage: "arrow.triangle.2.circlepath"
                )
                .anchorFont(.caption)
            }
            .tint(theme.accent.color)

            if viewModel.presentation.showsTimes {
                Spacer(minLength: 0)
                Button {
                    Task { await viewModel.shiftDay() }
                } label: {
                    Label("Shift my day", systemImage: "clock.arrow.circlepath")
                        .anchorFont(.caption)
                }
                .tint(theme.accent.color)
            }
        }
    }

    private var emptyState: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Nothing planned yet.")
                    .anchorFont(.title)
                    .foregroundStyle(theme.textPrimary.color)
                Text("Add a block whenever you're ready. There's no rush.")
                    .anchorFont(.body)
                    .foregroundStyle(theme.textSecondary.color)
            }
        }
    }
}

/// One block in the agenda. Tapping the circle marks it done; rest blocks and
/// done blocks are never shown as failing or overdue.
private struct AgendaRow: View {
    @Environment(\.anchorTheme) private var theme
    let block: TimeBlock
    let showsTimes: Bool
    let onToggle: () -> Void

    var body: some View {
        AnchorCard {
            HStack(alignment: .top, spacing: Spacing.md) {
                Button(action: onToggle) {
                    Image(systemName: block.state == .done ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(block.state == .done ? theme.accent.color : theme.textSecondary.color)
                }
                .accessibilityLabel(block.state == .done ? "Done" : "Mark done")

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.sm) {
                        CategoryChip(block.category)
                        if showsTimes, let start = block.startTime {
                            Text(Self.timeFormatter.string(from: start))
                                .anchorFont(.caption)
                                .foregroundStyle(theme.textSecondary.color)
                        }
                    }
                    Text(block.title)
                        .anchorFont(.body)
                        .foregroundStyle(theme.textPrimary.color)
                        .strikethrough(block.state == .done, color: theme.textSecondary.color)
                    if !block.steps.isEmpty {
                        Text(Self.stepsSummary(block.steps))
                            .anchorFont(.caption)
                            .foregroundStyle(theme.textSecondary.color)
                    }
                }
            }
        }
    }

    private static func stepsSummary(_ steps: [BlockStep]) -> String {
        let done = steps.filter(\.isDone).count
        return "\(done) of \(steps.count) steps"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}
