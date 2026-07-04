import SwiftUI
import AnchorCore
import AnchorDesign

/// Entry point for the Day tab. Builds the view model for today from the
/// injected repositories and clock.
public struct DayRootView: View {
    @State private var viewModel: DayViewModel

    @MainActor
    public init(
        dayPlans: any DayPlanRepository,
        templates: any TemplateRepository,
        wins: any WinRepository,
        preferences: any PreferencesRepository,
        dateProvider: any DateProviding
    ) {
        let today = DayDate(date: dateProvider.now, calendar: dateProvider.calendar)
        _viewModel = State(
            initialValue: DayViewModel(
                day: today,
                dayPlans: dayPlans,
                templates: templates,
                wins: wins,
                preferences: preferences,
                dateProvider: dateProvider
            )
        )
    }

    public var body: some View {
        DayContentView(viewModel: viewModel)
            .task { await viewModel.load() }
    }
}
