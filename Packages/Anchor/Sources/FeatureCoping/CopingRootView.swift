import SwiftUI
import AnchorCore
import AnchorDesign

/// The coping strategy bank, presented as a sheet reachable in two taps from
/// anywhere via the persistent anchor icon.
public struct CopingRootView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CopingViewModel
    @State private var editing: CopingStrategy?
    @State private var suggestion: CopingStrategy?

    @MainActor
    public init(
        coping: any CopingRepository,
        preferences: any PreferencesRepository,
        dateProvider: any DateProviding
    ) {
        _viewModel = State(
            initialValue: CopingViewModel(
                coping: coping,
                preferences: preferences,
                dateProvider: dateProvider
            )
        )
    }

    public var body: some View {
        NavigationStack {
            CopingListView(
                viewModel: viewModel,
                suggestion: $suggestion,
                onEdit: { editing = $0 },
                onAdd: { editing = CopingStrategy(title: "", orderIndex: 0) }
            )
            .navigationTitle("Coping bank")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await viewModel.load() }
            .sheet(item: $editing) { strategy in
                CopingEditorSheet(strategy: strategy) { edited in
                    Task {
                        if viewModel.strategies.contains(where: { $0.id == edited.id }) {
                            await viewModel.updateStrategy(edited)
                        } else {
                            await viewModel.addStrategy(title: edited.title, note: edited.note, category: edited.category)
                        }
                    }
                }
            }
        }
    }
}
