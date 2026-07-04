import SwiftUI
import AnchorCore
import AnchorDesign

/// Block detail: steps, gentle actions, edit and remove. No countdowns, no
/// overdue styling — a block is simply what it is.
struct BlockDetailSheet: View {
    @Environment(\.anchorTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let block: TimeBlock
    let showsTimes: Bool
    let onToggleStep: (UUID) -> Void
    let onMarkAllSteps: () -> Void
    let onConvertToRest: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var confirmingRemoval = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: Spacing.sm) {
                        CategoryChip(block.category)
                        if showsTimes, let start = block.startTime {
                            Text(BlockTimeText.short(start))
                                .anchorFont(.caption)
                                .foregroundStyle(theme.textSecondary.color)
                        }
                        if block.isFlexible {
                            Text("flexible")
                                .anchorFont(.caption)
                                .foregroundStyle(theme.textSecondary.color)
                        }
                    }
                    if let notes = block.notes, !notes.isEmpty {
                        Text(notes)
                            .anchorFont(.body)
                            .foregroundStyle(theme.textSecondary.color)
                    }
                }

                if !block.steps.isEmpty {
                    Section("Steps") {
                        ForEach(block.steps.sorted { $0.orderIndex < $1.orderIndex }) { step in
                            Button {
                                onToggleStep(step.id)
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
                        }
                        if block.steps.contains(where: { !$0.isDone }) {
                            Button("Mark all done", action: onMarkAllSteps)
                                .tint(theme.accent.color)
                        }
                    }
                }

                Section {
                    if !block.isRest {
                        Button("Turn this into rest", action: onConvertToRest)
                            .tint(theme.accent.color)
                    }
                    Button("Edit", action: onEdit)
                        .tint(theme.accent.color)
                    Button("Remove from today") { confirmingRemoval = true }
                        .tint(theme.textSecondary.color)
                }
            }
            .navigationTitle(block.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .confirmationDialog(
                "Remove \u{201C}\(block.title)\u{201D} from today?",
                isPresented: $confirmingRemoval,
                titleVisibility: .visible
            ) {
                Button("Remove it", action: onDelete)
                Button("Keep it", role: .cancel) {}
            } message: {
                Text("Its steps go with it. You can always add it again.")
            }
        }
        .presentationDetents([.medium, .large])
    }
}
