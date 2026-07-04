import SwiftUI
import AnchorCore
import AnchorDesign

/// The list of personal strategies, with a shuffle to suggest one.
struct CopingListView: View {
    @Environment(\.anchorTheme) private var theme
    let viewModel: CopingViewModel
    @Binding var suggestion: CopingStrategy?
    let onEdit: (CopingStrategy) -> Void
    let onAdd: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                suggestCard
                if viewModel.strategies.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.strategies) { strategy in
                        strategyCard(strategy)
                    }
                }
            }
            .padding(Spacing.md)
        }
        .background(theme.background.color)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add a strategy")
            }
        }
    }

    private var suggestCard: some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if let suggestion {
                    AnchorSectionLabel("A suggestion")
                    Text(suggestion.title)
                        .anchorFont(.title)
                        .foregroundStyle(theme.textPrimary.color)
                    if let note = suggestion.note, !note.isEmpty {
                        Text(note)
                            .anchorFont(.body)
                            .foregroundStyle(theme.textSecondary.color)
                    }
                }
                Button {
                    suggestion = viewModel.suggestOne()
                } label: {
                    Label(suggestion == nil ? "Suggest one" : "Suggest another", systemImage: "shuffle")
                        .anchorFont(.body)
                        .foregroundStyle(theme.accentText.color)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(theme.accent.color)
                        .clipShape(Capsule())
                }
                .disabled(viewModel.strategies.isEmpty)
            }
        }
    }

    private func strategyCard(_ strategy: CopingStrategy) -> some View {
        AnchorCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(strategy.title)
                        .anchorFont(.body)
                        .foregroundStyle(theme.textPrimary.color)
                    Spacer(minLength: 0)
                    if let category = strategy.category, !category.isEmpty {
                        Text(category)
                            .anchorFont(.caption)
                            .foregroundStyle(theme.textSecondary.color)
                    }
                }
                if let note = strategy.note, !note.isEmpty {
                    Text(note)
                        .anchorFont(.caption)
                        .foregroundStyle(theme.textSecondary.color)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { onEdit(strategy) }
        }
    }

    private var emptyState: some View {
        AnchorCard {
            Text("Your strategies live here. Add anything that helps you feel steadier.")
                .anchorFont(.body)
                .foregroundStyle(theme.textSecondary.color)
        }
    }
}
