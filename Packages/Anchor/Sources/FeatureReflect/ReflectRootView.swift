import SwiftUI
import AnchorCore
import AnchorDesign

/// Entry point for the Reflect tab.
public struct ReflectRootView: View {
    @State private var viewModel: ReflectViewModel

    @MainActor
    public init(
        reflections: any ReflectionRepository,
        wins: any WinRepository,
        preferences: any PreferencesRepository,
        dateProvider: any DateProviding
    ) {
        _viewModel = State(
            initialValue: ReflectViewModel(
                reflections: reflections,
                wins: wins,
                preferences: preferences,
                dateProvider: dateProvider
            )
        )
    }

    public var body: some View {
        ReflectContentView(viewModel: viewModel)
            .task { await viewModel.load() }
    }
}
