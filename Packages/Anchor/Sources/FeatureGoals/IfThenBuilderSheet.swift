import SwiftUI
import AnchorCore
import AnchorDesign

/// Build an "If [trigger], then I will [step]" plan. Time triggers surface on
/// Today at the right moment; situation triggers are reminders in words.
struct IfThenBuilderSheet: View {
    @Environment(\.anchorTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let step: GoalStep
    let onSave: (IfThenPlan) -> Void

    @State private var kind: IfThenPlan.TriggerKind = .time
    @State private var triggerTime = Calendar.current.date(from: DateComponents(hour: 9)) ?? Date()
    @State private var situationText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    Picker("Trigger", selection: $kind) {
                        Text("At a time").tag(IfThenPlan.TriggerKind.time)
                        Text("In a situation").tag(IfThenPlan.TriggerKind.situation)
                    }
                    .pickerStyle(.segmented)

                    if kind == .time {
                        DatePicker("Time", selection: $triggerTime, displayedComponents: .hourAndMinute)
                    } else {
                        TextField("For example: after I finish lunch", text: $situationText)
                    }
                }

                Section {
                    Text("Then I will \(step.title.lowercased()).")
                        .anchorFont(.body)
                        .foregroundStyle(theme.textSecondary.color)
                }
            }
            .navigationTitle("If–then plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(kind == .situation && situationText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .tint(theme.accent.color)
        }
    }

    private func save() {
        let plan: IfThenPlan
        switch kind {
        case .time:
            let components = Calendar.current.dateComponents([.hour, .minute], from: triggerTime)
            let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            plan = IfThenPlan(triggerKind: .time, triggerMinutes: minutes)
        case .situation:
            plan = IfThenPlan(
                triggerKind: .situation,
                situationText: situationText.trimmingCharacters(in: .whitespaces)
            )
        }
        onSave(plan)
        dismiss()
    }
}
