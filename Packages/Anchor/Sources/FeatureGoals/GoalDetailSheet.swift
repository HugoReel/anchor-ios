import SwiftUI
import AnchorCore
import AnchorDesign

/// A goal's steps, with an if–then plan builder on any step.
struct GoalDetailSheet: View {
    @Environment(\.anchorTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let goal: Goal
    let viewModel: GoalsViewModel

    @State private var newStepTitle = ""
    @State private var ifThenStep: GoalStep?

    var body: some View {
        NavigationStack {
            List {
                if let label = viewModel.targetLabel(for: goal) {
                    Section {
                        Text(label)
                            .anchorFont(.body)
                            .foregroundStyle(theme.textSecondary.color)
                    }
                }

                Section("Steps") {
                    ForEach(goal.steps.sorted { $0.orderIndex < $1.orderIndex }) { step in
                        stepRow(step)
                    }
                    HStack {
                        TextField("Add a small step", text: $newStepTitle)
                        Button("Add") { addStep() }
                            .disabled(trimmedNewStep.isEmpty)
                    }
                }

                Section {
                    Button("Archive this goal") {
                        Task { await viewModel.archiveGoal(id: goal.id) }
                        dismiss()
                    }
                    .tint(theme.textSecondary.color)
                }
            }
            .navigationTitle(goal.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(item: $ifThenStep) { step in
                IfThenBuilderSheet(step: step) { plan in
                    Task { await viewModel.addIfThen(goalID: goal.id, stepID: step.id, plan: plan) }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func stepRow(_ step: GoalStep) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Button {
                Task { await viewModel.toggleStep(goalID: goal.id, stepID: step.id) }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: step.isDone ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(step.isDone ? theme.accent.color : theme.textSecondary.color)
                    Text(step.title)
                        .anchorFont(.body)
                        .foregroundStyle(theme.textPrimary.color)
                        .strikethrough(step.isDone, color: theme.textSecondary.color)
                }
            }
            if step.ifThenPlans.isEmpty {
                Button("Add an if–then plan") { ifThenStep = step }
                    .anchorFont(.caption)
                    .tint(theme.accent.color)
            } else {
                ForEach(step.ifThenPlans) { plan in
                    Text(IfThenText.describe(plan, stepTitle: step.title))
                        .anchorFont(.caption)
                        .foregroundStyle(theme.textSecondary.color)
                }
            }
        }
    }

    private var trimmedNewStep: String {
        newStepTitle.trimmingCharacters(in: .whitespaces)
    }

    private func addStep() {
        let title = trimmedNewStep
        guard !title.isEmpty else { return }
        Task { await viewModel.addStep(goalID: goal.id, title: title) }
        newStepTitle = ""
    }
}

/// Renders an if–then plan as a plain-language sentence.
enum IfThenText {
    static func describe(_ plan: IfThenPlan, stepTitle: String) -> String {
        switch plan.triggerKind {
        case .time:
            let minutes = plan.triggerMinutes ?? 0
            return "If it's \(clockString(minutes)), then I will \(stepTitle.lowercased())."
        case .situation:
            let situation = plan.situationText ?? "the moment comes"
            return "If \(situation), then I will \(stepTitle.lowercased())."
        }
    }

    static func clockString(_ minutesOfDay: Int) -> String {
        let hour = (minutesOfDay / 60) % 24
        let minute = minutesOfDay % 60
        return String(format: "%02d:%02d", hour, minute)
    }
}
