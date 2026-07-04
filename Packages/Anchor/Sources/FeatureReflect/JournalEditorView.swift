import SwiftUI
import AnchorCore
import AnchorDesign

/// Free journaling with autosave. No minimum length, no forced prompts; a
/// gentle optional prompt is offered but never imposed.
struct JournalEditorView: View {
    @Environment(\.anchorTheme) private var theme
    let viewModel: ReflectViewModel

    @State private var text = ""
    @State private var saveTask: Task<Void, Never>?
    @State private var loadedFromModel = false

    private let prompt = "If you'd like a starting point: what took the most energy today?"

    var body: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                AnchorSectionLabel("Journal")
                Text(prompt)
                    .anchorFont(.caption)
                    .foregroundStyle(theme.textSecondary.color)
                TextEditor(text: $text)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(Spacing.xs)
                    .background(theme.surface.color)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
                    .anchorFont(.body)
                    .foregroundStyle(theme.textPrimary.color)
            }
        }
        .onAppear {
            if !loadedFromModel {
                text = viewModel.todaysJournalText
                loadedFromModel = true
            }
        }
        .onChange(of: text) { _, newValue in
            scheduleSave(newValue)
        }
    }

    /// Debounced autosave: save one second after typing settles.
    private func scheduleSave(_ value: String) {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            await viewModel.saveJournal(text: value)
        }
    }
}
