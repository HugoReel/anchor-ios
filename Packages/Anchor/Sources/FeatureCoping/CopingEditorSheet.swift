import SwiftUI
import AnchorCore
import AnchorDesign

/// Add or edit a coping strategy.
struct CopingEditorSheet: View {
    @Environment(\.anchorTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    private let original: CopingStrategy
    private let onSave: (CopingStrategy) -> Void

    @State private var title: String
    @State private var note: String
    @State private var category: String

    init(strategy: CopingStrategy, onSave: @escaping (CopingStrategy) -> Void) {
        self.original = strategy
        self.onSave = onSave
        _title = State(initialValue: strategy.title)
        _note = State(initialValue: strategy.note ?? "")
        _category = State(initialValue: strategy.category ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What helps?", text: $title)
                    TextField("How to do it (optional)", text: $note, axis: .vertical)
                        .lineLimit(1...4)
                    TextField("Category (optional)", text: $category)
                }
            }
            .navigationTitle(original.title.isEmpty ? "New strategy" : "Edit strategy")
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
        var strategy = original
        strategy.title = title.trimmingCharacters(in: .whitespaces)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        strategy.note = trimmedNote.isEmpty ? nil : trimmedNote
        let trimmedCategory = category.trimmingCharacters(in: .whitespaces)
        strategy.category = trimmedCategory.isEmpty ? nil : trimmedCategory
        onSave(strategy)
        dismiss()
    }
}
