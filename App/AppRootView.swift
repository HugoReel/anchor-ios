import SwiftUI
import FeatureOnboarding

/// Decides between the first-run flow and the main app. Reads
/// `onboardingComplete` once at launch; onboarding sets it and hands control
/// back here without a relaunch.
struct AppRootView: View {
    let dependencies: AppDependencies

    /// nil while the preference is still loading.
    @State private var onboardingComplete: Bool?

    var body: some View {
        Group {
            switch onboardingComplete {
            case .some(true):
                RootTabView(dependencies: dependencies)
            case .some(false):
                OnboardingRootView(
                    preferences: dependencies.store,
                    dateProvider: dependencies.dateProvider,
                    onComplete: { onboardingComplete = true }
                )
            case .none:
                ProgressView()
            }
        }
        .task {
            guard onboardingComplete == nil else { return }
            let prefs = try? await dependencies.store.load()
            onboardingComplete = prefs?.onboardingComplete ?? false
        }
    }
}
