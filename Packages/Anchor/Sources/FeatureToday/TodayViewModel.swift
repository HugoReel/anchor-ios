import Foundation
import Observation
import AnchorCore

/// Drives the Today dashboard. Owns presentation state derived from the
/// day's plan, preferences and the injected clock; holds no view code and
/// reads the clock only through `DateProviding`.
@MainActor
@Observable
public final class TodayViewModel {
    public private(set) var presentation: DayPresentation
    public private(set) var currentBlock: TimeBlock?
    public private(set) var nextBlock: TimeBlock?
    public private(set) var dayProgress: Double = 0
    /// Progress within the current block, 0…1. Nil whenever timers are
    /// hidden (sequence mode, Low-Demand) or there is no current timed block.
    public private(set) var blockProgress: Double?
    public private(set) var showEnergyPrompt: Bool = false
    public private(set) var winsSummaries: [WinsSummary] = []
    public private(set) var showReflectionNudge: Bool = false
    public private(set) var loadFailed: Bool = false

    private let dayPlans: any DayPlanRepository
    private let energy: any EnergyRepository
    private let wins: any WinRepository
    private let preferences: any PreferencesRepository
    private let dateProvider: any DateProviding

    public init(
        dayPlans: any DayPlanRepository,
        energy: any EnergyRepository,
        wins: any WinRepository,
        preferences: any PreferencesRepository,
        dateProvider: any DateProviding
    ) {
        self.dayPlans = dayPlans
        self.energy = energy
        self.wins = wins
        self.preferences = preferences
        self.dateProvider = dateProvider
        self.presentation = .standard(mode: .clock, preferences: UserPreferences())
    }

    public func load() async {
        loadFailed = false
        let now = dateProvider.now
        let calendar = dateProvider.calendar
        let today = DayDate(date: now, calendar: calendar)
        do {
            let prefs = try await preferences.load()
            let plan = try await dayPlans.plan(for: today) ?? DayPlan(date: today)
            presentation = .standard(mode: plan.mode, preferences: prefs)

            currentBlock = ScheduleMath.currentBlock(in: plan, at: now, calendar: calendar)
            nextBlock = ScheduleMath.nextBlock(in: plan, at: now, calendar: calendar)
            dayProgress = ScheduleMath.dayProgress(of: plan, at: now, calendar: calendar)

            if presentation.showsTimers, let current = currentBlock {
                blockProgress = ScheduleMath.progress(of: current, in: plan, at: now, calendar: calendar)
            } else {
                blockProgress = nil
            }

            showEnergyPrompt = try await energy.checkIn(for: today) == nil

            if presentation.showsWins {
                let events = try await wins.allEvents()
                winsSummaries = WinsEngine.summaries(events: events, reference: today, calendar: calendar)
            } else {
                winsSummaries = []
            }

            showReflectionNudge = !presentation.invitational
                && prefs.reflectionNudgeDismissedDayKey != today.numericKey
        } catch {
            loadFailed = true
        }
    }

    public func dismissNudge() async {
        showReflectionNudge = false
        let today = DayDate(date: dateProvider.now, calendar: dateProvider.calendar)
        do {
            var prefs = try await preferences.load()
            prefs.reflectionNudgeDismissedDayKey = today.numericKey
            prefs.modifiedAt = dateProvider.now
            try await preferences.save(prefs)
        } catch {
            loadFailed = true
        }
    }
}
