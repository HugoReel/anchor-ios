import SwiftUI
import AnchorCore
import AnchorDesign
import FeatureToday
import FeatureTimeline
import FeatureGoals
import FeatureReflect
import FeatureCoping
import FeatureSettings

/// Fixed four-tab shell. The tab order never changes and navigation never
/// rearranges itself; Settings is always behind the gear, never a tab. The
/// coping bank is always one anchor tap away from every tab.
struct RootTabView: View {
    let dependencies: AppDependencies

    @State private var showCoping = false
    @State private var chrome: AppChromeModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _chrome = State(initialValue: AppChromeModel(preferences: dependencies.store))
    }

    var body: some View {
        TabView {
            tab(
                TodayRootView(
                    dayPlans: dependencies.store,
                    energy: dependencies.store,
                    wins: dependencies.store,
                    preferences: dependencies.store,
                    dateProvider: dependencies.dateProvider,
                    notifications: dependencies.notifications
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
            tab(
                GoalsRootView(
                    goals: dependencies.store,
                    wins: dependencies.store,
                    preferences: dependencies.store,
                    dateProvider: dependencies.dateProvider
                ),
                title: "Goals",
                symbol: "flag"
            )
            tab(
                ReflectRootView(
                    reflections: dependencies.store,
                    wins: dependencies.store,
                    preferences: dependencies.store,
                    dateProvider: dependencies.dateProvider
                ),
                title: "Reflect",
                symbol: "book.closed"
            )
        }
        .sheet(isPresented: $showCoping) {
            CopingRootView(
                coping: dependencies.store,
                preferences: dependencies.store,
                dateProvider: dependencies.dateProvider
            )
        }
        .environment(\.anchorTheme, chrome.theme)
        .task { await chrome.reload() }
    }

    private var settingsDestination: some View {
        SettingsRootView(
            preferences: dependencies.store,
            exporter: makeExporter(),
            wiper: dependencies.store,
            dateProvider: dependencies.dateProvider,
            notifications: dependencies.notifications,
            onPreferencesChanged: { Task { await chrome.reload() } }
        )
    }

    private func makeExporter() -> DataExporter {
        DataExporter(
            dayPlans: dependencies.store,
            templates: dependencies.store,
            goals: dependencies.store,
            reflections: dependencies.store,
            energy: dependencies.store,
            wins: dependencies.store,
            coping: dependencies.store,
            preferences: dependencies.store
        )
    }

    private func tab(_ content: some View, title: String, symbol: String) -> some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showCoping = true
                        } label: {
                            Image(systemName: "lifepreserver")
                        }
                        .accessibilityLabel("Coping bank")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            settingsDestination
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
