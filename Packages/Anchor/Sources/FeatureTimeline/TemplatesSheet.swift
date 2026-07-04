import SwiftUI
import AnchorCore
import AnchorDesign

/// Apply a saved day shape, or save today as one.
struct TemplatesSheet: View {
    @Environment(\.anchorTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let templates: [DayTemplate]
    let onApply: (DayTemplate) -> Void
    let onSaveCurrent: (String) -> Void

    @State private var newTemplateName = ""

    var body: some View {
        NavigationStack {
            List {
                if templates.isEmpty {
                    Section {
                        Text("No templates yet. Save a day you like and it will appear here.")
                            .anchorFont(.body)
                            .foregroundStyle(theme.textSecondary.color)
                    }
                } else {
                    Section("Your templates") {
                        ForEach(templates) { template in
                            HStack(spacing: Spacing.sm) {
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text(template.name)
                                        .anchorFont(.body)
                                        .foregroundStyle(theme.textPrimary.color)
                                    Text(blockCountLabel(template))
                                        .anchorFont(.caption)
                                        .foregroundStyle(theme.textSecondary.color)
                                }
                                Spacer(minLength: 0)
                                Button("Apply") {
                                    onApply(template)
                                    dismiss()
                                }
                                .tint(theme.accent.color)
                            }
                        }
                    }
                }

                Section("Save today as a template") {
                    TextField("Template name", text: $newTemplateName)
                    Button("Save") {
                        onSaveCurrent(newTemplateName.trimmingCharacters(in: .whitespaces))
                        newTemplateName = ""
                        dismiss()
                    }
                    .disabled(newTemplateName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .tint(theme.accent.color)
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func blockCountLabel(_ template: DayTemplate) -> String {
        template.blocks.count == 1 ? "1 block" : "\(template.blocks.count) blocks"
    }
}
