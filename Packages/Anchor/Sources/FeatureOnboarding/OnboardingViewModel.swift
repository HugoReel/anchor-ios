import Foundation
import Observation
import AnchorCore
import AnchorDesign

/// Drives the three-question first run: theme, wake window and whether to show
/// gentle wins. Every answer is optional; skipping completes onboarding with
/// the current defaults. Writing `onboardingComplete` ensures it never returns.
@MainActor
@Observable
public final class OnboardingViewModel {
    public var theme: ThemeChoice = .calm
    public var showWins: Bool = true
    public var wakeStartMinutes: Int = 7 * 60
    public var wakeEndMinutes: Int = 22 * 60
    public private(set) var isComplete: Bool = false
    public private(set) var loadFailed: Bool = false

    private let preferences: any PreferencesRepository
    private let dateProvider: any DateProviding

    public init(preferences: any PreferencesRepository, dateProvider: any DateProviding) {
        self.preferences = preferences
        self.dateProvider = dateProvider
    }

    public func load() async {
        guard let prefs = try? await preferences.load() else { return }
        isComplete = prefs.onboardingComplete
        theme = ThemeChoice(rawValue: prefs.themeRawValue) ?? .calm
        showWins = prefs.showWins
        if let start = prefs.wakeStartMinutes { wakeStartMinutes = start }
        if let end = prefs.wakeEndMinutes { wakeEndMinutes = end }
    }

    /// Completes without forcing any answer; whatever is currently set stays.
    public func skip() async { await finish(saveAnswers: false) }

    /// Completes and saves the chosen answers.
    public func complete() async { await finish(saveAnswers: true) }

    private func finish(saveAnswers: Bool) async {
        do {
            var prefs = try await preferences.load()
            if saveAnswers {
                prefs.themeRawValue = theme.rawValue
                prefs.showWins = showWins
                prefs.wakeStartMinutes = wakeStartMinutes
                prefs.wakeEndMinutes = wakeEndMinutes
            }
            prefs.onboardingComplete = true
            prefs.modifiedAt = dateProvider.now
            try await preferences.save(prefs)
            isComplete = true
        } catch {
            loadFailed = true
        }
    }
}
