import Foundation
import Testing
import AnchorCore
import AnchorDesign
@testable import FeatureOnboarding

@MainActor
private func makeViewModel(
    preferences: InMemoryPreferencesRepository = InMemoryPreferencesRepository()
) -> OnboardingViewModel {
    let provider = FixedDateProvider(
        now: Date(timeIntervalSince1970: 1_700_000_000),
        calendar: Calendar(identifier: .gregorian)
    )
    return OnboardingViewModel(preferences: preferences, dateProvider: provider)
}

@MainActor
@Test func skipCompletesOnboardingWithDefaults() async {
    let prefs = InMemoryPreferencesRepository()
    let viewModel = makeViewModel(preferences: prefs)
    await viewModel.load()

    await viewModel.skip()

    #expect(viewModel.isComplete)
    let saved = try? await prefs.load()
    #expect(saved?.onboardingComplete == true)
    #expect(saved?.themeRawValue == "calm")
}

@MainActor
@Test func answersPersistToPreferences() async {
    let prefs = InMemoryPreferencesRepository()
    let viewModel = makeViewModel(preferences: prefs)
    await viewModel.load()

    viewModel.theme = .warm
    viewModel.showWins = false
    viewModel.wakeStartMinutes = 6 * 60
    await viewModel.complete()

    let saved = try? await prefs.load()
    #expect(saved?.themeRawValue == "warm")
    #expect(saved?.showWins == false)
    #expect(saved?.wakeStartMinutes == 6 * 60)
    #expect(saved?.onboardingComplete == true)
}

@MainActor
@Test func neverShownAgainOnceComplete() async {
    let prefs = InMemoryPreferencesRepository()
    let first = makeViewModel(preferences: prefs)
    await first.load()
    await first.complete()

    // A fresh view model over the same store sees onboarding already done.
    let second = makeViewModel(preferences: prefs)
    await second.load()
    #expect(second.isComplete)
}
