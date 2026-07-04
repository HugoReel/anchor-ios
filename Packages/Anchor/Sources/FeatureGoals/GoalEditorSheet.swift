import SwiftUI
import AnchorCore
import AnchorDesign

/// Create or rename a goal, with an optional target date (never a countdown).
struct GoalEditorSheet: View {
    @Environment(\.anchorTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    private let original: Goal
    private let onSave: (Goal) -> Void

    @State private var title: String
    @State private var note: String
    @State private var hasTarget: Bool
    @State private var targetDate: Date

    @MainActor
    init(goal: Goal, onSave: @escaping (Goal) -> Void) {
        self.original = goal
        self.onSave = onSave
        _title = State(initialValue: goal.title)
        _note = State(initialValue: goal.note ?? "")
        _hasTarget = State(initialValue: goal.targetDate != nil)
        let calendar = Calendar.current
        let base = goal.targetDate?.startDate(calendar: calendar)
            ?? calendar.date(byAdding: .month, value: 1, to: Date())
            ?? Date()
        _targetDate = State(initialValue: base)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What would you like to move towards?", text: $title)
                    TextField("A note, if you'd like", text: $note, axis: .vertical)
                        .lineLimit(1...4)
                }
                Section {
                    Toggle("Set a gentle target date", isOn: $hasTarget)
                    if hasTarget {
                        DatePicker("Aiming for", selection: $targetDate, displayedComponents: .date)
                    }
                } footer: {
                    Text("A target is just a hope, never a deadline. There's no countdown.")
                }
            }
            .navigationTitle(original.title.isEmpty ? "New goal" : "Edit goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .tint(theme.accent.color)
        }
    }

    private func save() {
        var goal = original
        goal.title = title.trimmingCharacters(in: .whitespaces)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        goal.note = trimmedNote.isEmpty ? nil : trimmedNote
        if hasTarget {
            goal.targetDate = DayDate(date: targetDate, calendar: Calendar.current)
        } else {
            goal.targetDate = nil
        }
        onSave(goal)
        dismiss()
    }
}
