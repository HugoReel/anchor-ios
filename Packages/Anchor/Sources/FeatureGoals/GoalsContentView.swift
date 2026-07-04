import SwiftUI
import AnchorCore
import AnchorDesign

/// The Goals list. Each goal shows a progress bar that only ever fills;
/// no goal is ever shown as behind or failing.
struct GoalsContentView: View {
    @Environment(\.anchorTheme) private var theme
    let viewModel: GoalsViewModel
    let onNewGoal: () -> Void

    @State private var openGoalID: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if viewModel.goals.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.goals) { goal in
                        GoalRow(
                            goal: goal,
                            targetLabel: viewModel.targetLabel(for: goal),
                            onOpen: { openGoalID = goal.id }
                        )
                    }
                }
            }
            .padding(Spacing.md)
        }
        .background(theme.background.color)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onNewGoal) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add a goal")
            }
        }
        .sheet(item: goalBinding) { goal in
            GoalDetailSheet(goal: goal, viewModel: viewModel)
        }
    }

    /// Resolves the open goal live from the view model so the detail sheet
    /// always reflects the latest steps.
    private var goalBinding: Binding<Goal?> {
        Binding(
            get: { viewModel.goals.first { $0.id == openGoalID } },
            set: { openGoalID = $0?.id }
        )
    }

    private var emptyState: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("No goals yet.")
                    .anchorFont(.title)
                    .foregroundStyle(theme.textPrimary.color)
                Text("A goal is just something you'd like to move towards, one small step at a time.")
                    .anchorFont(.body)
                    .foregroundStyle(theme.textSecondary.color)
            }
        }
    }
}

private struct GoalRow: View {
    @Environment(\.anchorTheme) private var theme
    let goal: Goal
    let targetLabel: String?
    let onOpen: () -> Void

    var body: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(goal.title)
                    .anchorFont(.title)
                    .foregroundStyle(theme.textPrimary.color)
                if !goal.steps.isEmpty {
                    ProgressView(value: goal.progress)
                        .tint(theme.accent.color)
                    Text(stepSummary)
                        .anchorFont(.caption)
                        .foregroundStyle(theme.textSecondary.color)
                }
                if let targetLabel {
                    Text(targetLabel)
                        .anchorFont(.caption)
                        .foregroundStyle(theme.textSecondary.color)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onOpen)
        }
    }

    private var stepSummary: String {
        let done = goal.steps.filter(\.isDone).count
        return "\(done) of \(goal.steps.count) steps done"
    }
}
