import SwiftUI
import FeatureToday
import FeatureTimeline
import FeatureGoals
import FeatureReflect
import FeatureSettings

/// Fixed four-tab shell. The tab order never changes and navigation never
/// rearranges itself; Settings is always behind the gear, never a tab.
struct RootTabView: View {
    let dependencies: AppDependencies

    var body: some View {
        TabView {
            tab(
                TodayRootView(
                    dayPlans: dependencies.store,
                    energy: dependencies.store,
                    wins: dependencies.store,
                    preferences: dependencies.store,
                    dateProvider: dependencies.dateProvider
                ),
                title: "Today",
                symbol: "sun.max"
            )
            tab(
                DayRootView(
                    dayPlans: dependencies.store,
                    templates: dependencies.store,
                    wins: dependencies.store,
                    preferences: dependencies.store,
                    dateProvider: dependencies.dateProvider
                ),
                title: "Day",
                symbol: "calendar.day.timeline.left"
            )
            tab(GoalsRootView(), title: "Goals", symbol: "flag")
            tab(ReflectRootView(), title: "Reflect", symbol: "book.closed")
        }
    }

    private func tab(_ content: some View, title: String, symbol: String) -> some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            SettingsRootView()
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel("Settings")
                    }
                }
        }
        .tabItem {
            Label(title, systemImage: symbol)
        }
    }
}
