import SwiftUI
import AnchorCore
import AnchorDesign

/// Add or edit a block. Edits a local copy; nothing changes until Save.
struct BlockEditorSheet: View {
    @Environment(\.anchorTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    private let original: TimeBlock
    private let onSave: (TimeBlock) -> Void

    @State private var title: String
    @State private var category: BlockCategory
    @State private var isTimed: Bool
    @State private var start: Date
    @State private var durationMinutes: Int
    @State private var isFlexible: Bool
    @State private var notes: String
    @State private var steps: [BlockStep]
    @State private var newStepTitle = ""

    @MainActor
    init(block: TimeBlock, defaultStart: Date, onSave: @escaping (TimeBlock) -> Void) {
        self.original = block
        self.onSave = onSave
        _title = State(initialValue: block.title)
        _category = State(initialValue: block.category)
        _isTimed = State(initialValue: block.startTime != nil)
        _start = State(initialValue: block.startTime ?? defaultStart)
        _durationMinutes = State(initialValue: block.durationMinutes ?? 30)
        _isFlexible = State(initialValue: block.isFlexible)
        _notes = State(initialValue: block.notes ?? "")
        _steps = State(initialValue: block.steps.sorted { $0.orderIndex < $1.orderIndex })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What is this block?", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(BlockCategory.allCases, id: \.self) { choice in
                            Text(choice.displayName).tag(choice)
                        }
                    }
                }

                Section {
                    Toggle("Give it a time", isOn: $isTimed)
                    if isTimed {
                        DatePicker("Starts", selection: $start, displayedComponents: .hourAndMinute)
                        Stepper(value: $durationMinutes, in: 5...480, step: 5) {
                            Text("For \(durationMinutes) minutes")
                        }
                    }
                    Toggle("Flexible — okay to move", isOn: $isFlexible)
                }

                Section("Steps (optional)") {
                    ForEach($steps) { $step in
                        TextField("Step", text: $step.title)
                    }
                    .onDelete { offsets in
                        steps.remove(atOffsets: offsets)
                    }
                    HStack {
                        TextField("Add a step", text: $newStepTitle)
                        Button("Add") { addStep() }
                            .disabled(newStepTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section("Notes (optional)") {
                    TextField("Anything useful to remember", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(original.title.isEmpty ? "New block" : "Edit block")
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
        }
        .tint(theme.accent.color)
    }

    private func addStep() {
        let trimmed = newStepTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        steps.append(BlockStep(title: trimmed, orderIndex: steps.count))
        newStepTitle = ""
    }

    private func save() {
        var block = original
        block.title = title.trimmingCharacters(in: .whitespaces)
        block.category = category
        block.startTime = isTimed ? start : nil
        block.durationMinutes = isTimed ? durationMinutes : nil
        block.isFlexible = isFlexible
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        block.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        block.steps = steps
            .filter { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }
            .enumerated()
            .map { index, step in
                var ordered = step
                ordered.orderIndex = index
                return ordered
            }
        onSave(block)
        dismiss()
    }
}
