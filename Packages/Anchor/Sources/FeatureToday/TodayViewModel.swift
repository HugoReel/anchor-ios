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
    /// True when wins are visible but paused. The view shows a calm note and
    /// keeps the existing counts rather than rendering an empty or zero strip.
    public private(set) var winsArePaused: Bool = false
    /// Offers to lighten the day after a low energy check-in. Populated only
    /// by `submitEnergy`; never applied without an explicit `applySuggestion`.
    public private(set) var lighteningSuggestions: [LighteningSuggestion] = []
    public private(set) var showReflectionNudge: Bool = false
    public private(set) var loadFailed: Bool = false

    private let dayPlans: any DayPlanRepository
    private let energy: any EnergyRepository
    private let wins: any WinRepository
    private let preferences: any PreferencesRepository
    private let dateProvider: any DateProviding
    private let notifications: NotificationCoordinator?

    public init(
        dayPlans: any DayPlanRepository,
        energy: any EnergyRepository,
        wins: any WinRepository,
        preferences: any PreferencesRepository,
        dateProvider: any DateProviding,
        notifications: NotificationCoordinator? = nil
    ) {
        self.dayPlans = dayPlans
        self.energy = energy
        self.wins = wins
        self.preferences = preferences
        self.dateProvider = dateProvider
        self.notifications = notifications
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

            let existingCheckIn = try await energy.checkIn(for: today)
            showEnergyPrompt = existingCheckIn == nil
                && prefs.energyPromptDismissedDayKey != today.numericKey

            if presentation.showsWins {
                let events = try await wins.allEvents()
                winsSummaries = WinsEngine.summaries(events: events, reference: today, calendar: calendar)
                winsArePaused = prefs.winsPaused
            } else {
                winsSummaries = []
                winsArePaused = false
            }

            showReflectionNudge = !presentation.invitational
                && prefs.reflectionNudgeDismissedDayKey != today.numericKey

            await notifications?.refreshTransitionWarnings(for: plan)
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

    /// Records the day's energy level and, when it is low, offers a few ways
    /// to lighten the day. The offers are never applied automatically.
    public func submitEnergy(level: Int) async {
        let now = dateProvider.now
        let calendar = dateProvider.calendar
        let today = DayDate(date: now, calendar: calendar)
        showEnergyPrompt = false
        do {
            try await energy.upsert(EnergyCheckIn(day: today, level: level, createdAt: now, modifiedAt: now))
            let plan = try await dayPlans.plan(for: today) ?? DayPlan(date: today)
            lighteningSuggestions = EnergyAdvisor.suggestions(for: plan, energyLevel: level)
        } catch {
            loadFailed = true
        }
    }

    /// Dismisses the energy prompt for the rest of the day without recording a
    /// level. It returns fresh the next day.
    public func dismissEnergyPrompt() async {
        showEnergyPrompt = false
        let today = DayDate(date: dateProvider.now, calendar: dateProvider.calendar)
        do {
            var prefs = try await preferences.load()
            prefs.energyPromptDismissedDayKey = today.numericKey
            prefs.modifiedAt = dateProvider.now
            try await preferences.save(prefs)
        } catch {
            loadFailed = true
        }
    }

    /// Applies one lightening offer the user chose. Convert-to-rest keeps the
    /// block on today as rest; postpone moves it to the next day. Other blocks
    /// and other offers are untouched.
    public func applySuggestion(_ suggestion: LighteningSuggestion) async {
        let now = dateProvider.now
        let calendar = dateProvider.calendar
        let today = DayDate(date: now, calendar: calendar)
        do {
            guard var plan = try await dayPlans.plan(for: today),
                  let index = plan.blocks.firstIndex(where: { $0.id == suggestion.blockID }) else {
                lighteningSuggestions.removeAll { $0.blockID == suggestion.blockID }
                return
            }
            switch suggestion.action {
            case .convertToRest:
                plan.blocks[index].category = .rest
                plan.blocks[index].modifiedAt = now
                plan.modifiedAt = now
                try await dayPlans.upsert(plan)
            case .postpone:
                var moved = plan.blocks.remove(at: index)
                plan.modifiedAt = now
                try await dayPlans.upsert(plan)

                let nextDay = today.advanced(by: 1, calendar: calendar)
                var nextPlan = try await dayPlans.plan(for: nextDay) ?? DayPlan(date: nextDay)
                moved.state = .notStarted
                moved.completedAt = nil
                if let start = moved.startTime {
                    moved.startTime = calendar.date(byAdding: .day, value: 1, to: start) ?? start
                }
                moved.orderIndex = (nextPlan.blocks.map(\.orderIndex).max() ?? -1) + 1
                moved.modifiedAt = now
                nextPlan.blocks.append(moved)
                nextPlan.modifiedAt = now
                try await dayPlans.upsert(nextPlan)
            }
            lighteningSuggestions.removeAll { $0.blockID == suggestion.blockID }
            await load()
        } catch {
            loadFailed = true
        }
    }

    /// Turns Low-Demand Mode on or off and persists it, then reloads so the
    /// presentation reflects the change immediately.
    public func setLowDemand(_ enabled: Bool) async {
        do {
            var prefs = try await preferences.load()
            prefs.lowDemandMode = enabled
            prefs.modifiedAt = dateProvider.now
            try await preferences.save(prefs)
        } catch {
            loadFailed = true
        }
        await load()
    }
}
