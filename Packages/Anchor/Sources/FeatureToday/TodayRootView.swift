import SwiftUI
import AnchorCore
import AnchorDesign

/// Entry point for the Today tab. Builds and owns the view model from the
/// injected repositories, then loads on appear.
public struct TodayRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: TodayViewModel

    @MainActor
    public init(
        dayPlans: any DayPlanRepository,
        energy: any EnergyRepository,
        wins: any WinRepository,
        preferences: any PreferencesRepository,
        dateProvider: any DateProviding,
        notifications: NotificationCoordinator? = nil
    ) {
        _viewModel = State(
            initialValue: TodayViewModel(
                dayPlans: dayPlans,
                energy: energy,
                wins: wins,
                preferences: preferences,
                dateProvider: dateProvider,
                notifications: notifications
            )
        )
    }

    public var body: some View {
        TodayContentView(viewModel: viewModel)
            .task {
                await viewModel.load()
                // Keep the day current if the app stays open past midnight.
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(60))
                    await viewModel.refreshIfDayChanged()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await viewModel.refreshIfDayChanged() }
                }
            }
    }
}
