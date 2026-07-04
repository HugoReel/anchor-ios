import SwiftUI
import AnchorCore
import AnchorDesign

/// Entry point for the Goals tab.
public struct GoalsRootView: View {
    @State private var viewModel: GoalsViewModel
    @State private var editingGoal: Goal?

    @MainActor
    public init(
        goals: any GoalRepository,
        wins: any WinRepository,
        preferences: any PreferencesRepository,
        dateProvider: any DateProviding
    ) {
        _viewModel = State(
            initialValue: GoalsViewModel(
                goals: goals,
                wins: wins,
                preferences: preferences,
                dateProvider: dateProvider
            )
        )
    }

    public var body: some View {
        GoalsContentView(viewModel: viewModel, onNewGoal: { editingGoal = Goal(title: "") })
            .task { await viewModel.load() }
            .sheet(item: $editingGoal) { goal in
                GoalEditorSheet(goal: goal) { edited in
                    Task { await viewModel.upsertGoal(edited) }
                }
            }
    }
}
