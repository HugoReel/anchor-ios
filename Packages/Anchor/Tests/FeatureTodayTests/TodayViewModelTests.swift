import Foundation
import Testing
import AnchorCore
@testable import FeatureToday

@MainActor
private enum Fixture {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    static let day = DayDate(year: 2025, month: 6, day: 2)

    static func at(_ hour: Int, _ minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = day.year
        components.month = day.month
        components.day = day.day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }

    static func provider(_ hour: Int, _ minute: Int = 0) -> FixedDateProvider {
        FixedDateProvider(now: at(hour, minute), calendar: calendar)
    }

    static func block(_ title: String, category: BlockCategory = .focus, start: Int, minutes: Int, order: Int) -> TimeBlock {
        TimeBlock(title: title, category: category, startTime: at(start), durationMinutes: minutes, orderIndex: order)
    }

    static func viewModel(
        plan: DayPlan?,
        preferences: UserPreferences = UserPreferences(),
        energyToday: EnergyCheckIn? = nil,
        wins: [WinEvent] = [],
        at hour: Int,
        _ minute: Int = 0
    ) async -> TodayViewModel {
        let plans = InMemoryDayPlanRepository()
        if let plan { try? await plans.upsert(plan) }
        let energy = InMemoryEnergyRepository()
        if let energyToday { try? await energy.upsert(energyToday) }
        let winRepo = InMemoryWinRepository(calendar: calendar)
        for event in wins { try? await winRepo.append(event) }
        let prefsRepo = InMemoryPreferencesRepository()
        try? await prefsRepo.save(preferences)
        return TodayViewModel(
            dayPlans: plans,
            energy: energy,
            wins: winRepo,
            preferences: prefsRepo,
            dateProvider: provider(hour, minute)
        )
    }
}

@MainActor
@Test func heroShowsCurrentBlockAndProgress() async {
    let plan = DayPlan(date: Fixture.day, mode: .clock, blocks: [Fixture.block("Morning focus", start: 9, minutes: 60, order: 0)])
    let viewModel = await Fixture.viewModel(plan: plan, at: 9, 30)

    await viewModel.load()

    #expect(viewModel.currentBlock?.title == "Morning focus")
    #expect(viewModel.blockProgress != nil)
    if let progress = viewModel.blockProgress {
        #expect(abs(progress - 0.5) < 0.001)
    }
}

@MainActor
@Test func timeRemainingHiddenInSequenceMode() async {
    let stretch = Fixture.block("Stretch", category: .care, start: 9, minutes: 60, order: 0)
    let plan = DayPlan(date: Fixture.day, mode: .sequence, blocks: [stretch])
    let viewModel = await Fixture.viewModel(plan: plan, at: 9, 30)

    await viewModel.load()

    #expect(viewModel.presentation.showsTimers == false)
    #expect(viewModel.blockProgress == nil)
}

@MainActor
@Test func timeRemainingHiddenInLowDemand() async {
    var prefs = UserPreferences()
    prefs.lowDemandMode = true
    let plan = DayPlan(date: Fixture.day, mode: .clock, blocks: [Fixture.block("Morning focus", start: 9, minutes: 60, order: 0)])
    let viewModel = await Fixture.viewModel(plan: plan, preferences: prefs, at: 9, 30)

    await viewModel.load()

    #expect(viewModel.presentation.invitational)
    #expect(viewModel.blockProgress == nil)
}

@MainActor
@Test func energyPromptShownWhenNoCheckIn() async {
    let viewModel = await Fixture.viewModel(plan: nil, at: 8)
    await viewModel.load()
    #expect(viewModel.showEnergyPrompt)
}

@MainActor
@Test func energyPromptHiddenAfterCheckIn() async {
    let viewModel = await Fixture.viewModel(
        plan: nil,
        energyToday: EnergyCheckIn(day: Fixture.day, level: 3),
        at: 8
    )
    await viewModel.load()
    #expect(viewModel.showEnergyPrompt == false)
}

@MainActor
@Test func winsRowHiddenWhenDisabled() async {
    var prefs = UserPreferences()
    prefs.showWins = false
    let wins = [WinEvent(date: Fixture.at(9), kind: .checkIn)]
    let viewModel = await Fixture.viewModel(plan: nil, preferences: prefs, wins: wins, at: 10)

    await viewModel.load()

    #expect(viewModel.winsSummaries.isEmpty)
}

@MainActor
@Test func winsRowShownWhenEnabled() async {
    let wins = [WinEvent(date: Fixture.at(9), kind: .checkIn)]
    let viewModel = await Fixture.viewModel(plan: nil, wins: wins, at: 10)

    await viewModel.load()

    #expect(!viewModel.winsSummaries.isEmpty)
}

@MainActor
@Test func nudgeShownByDefaultThenDismissPersistsForDay() async {
    let viewModel = await Fixture.viewModel(plan: nil, at: 10)
    await viewModel.load()
    #expect(viewModel.showReflectionNudge)

    await viewModel.dismissNudge()
    #expect(viewModel.showReflectionNudge == false)

    // Reloading the same day keeps it dismissed.
    await viewModel.load()
    #expect(viewModel.showReflectionNudge == false)
}

@MainActor
@Test func nudgeHiddenInLowDemand() async {
    var prefs = UserPreferences()
    prefs.lowDemandMode = true
    let viewModel = await Fixture.viewModel(plan: nil, preferences: prefs, at: 10)

    await viewModel.load()

    #expect(viewModel.showReflectionNudge == false)
}

// MARK: - Task 3.5: energy, lightening, low-demand, wins pause

@MainActor
private struct Harness {
    let viewModel: TodayViewModel
    let plans: InMemoryDayPlanRepository
    let energy: InMemoryEnergyRepository
    let wins: InMemoryWinRepository
    let preferences: InMemoryPreferencesRepository
}

@MainActor
private func makeHarness(
    plan: DayPlan?,
    preferences: UserPreferences = UserPreferences(),
    energyToday: EnergyCheckIn? = nil,
    wins: [WinEvent] = [],
    at hour: Int,
    _ minute: Int = 0
) async -> Harness {
    let plans = InMemoryDayPlanRepository()
    if let plan { try? await plans.upsert(plan) }
    let energyRepo = InMemoryEnergyRepository()
    if let energyToday { try? await energyRepo.upsert(energyToday) }
    let winRepo = InMemoryWinRepository(calendar: Fixture.calendar)
    for event in wins { try? await winRepo.append(event) }
    let prefsRepo = InMemoryPreferencesRepository()
    try? await prefsRepo.save(preferences)
    let viewModel = TodayViewModel(
        dayPlans: plans,
        energy: energyRepo,
        wins: winRepo,
        preferences: prefsRepo,
        dateProvider: Fixture.provider(hour, minute)
    )
    return Harness(viewModel: viewModel, plans: plans, energy: energyRepo, wins: winRepo, preferences: prefsRepo)
}

@MainActor
@Test func firstOpenPromptsOncePerDay() async {
    let harness = await makeHarness(plan: nil, at: 8)
    await harness.viewModel.load()
    #expect(harness.viewModel.showEnergyPrompt)

    await harness.viewModel.dismissEnergyPrompt()
    #expect(harness.viewModel.showEnergyPrompt == false)

    // Same day, reopened: the prompt does not return even with no check-in.
    await harness.viewModel.load()
    #expect(harness.viewModel.showEnergyPrompt == false)
}

@MainActor
@Test func applySuggestionRequiresExplicitUserAction() async {
    let laundry = TimeBlock(
        title: "Laundry",
        category: .focus,
        startTime: Fixture.at(14),
        durationMinutes: 30,
        orderIndex: 0,
        isFlexible: true
    )
    let plan = DayPlan(date: Fixture.day, mode: .clock, blocks: [laundry])
    let harness = await makeHarness(plan: plan, at: 8)
    await harness.viewModel.load()

    await harness.viewModel.submitEnergy(level: 1)
    #expect(!harness.viewModel.lighteningSuggestions.isEmpty)

    // Offering a suggestion must not change the plan on its own.
    let before = (try? await harness.plans.plan(for: Fixture.day)) ?? nil
    #expect(before?.blocks.count == 1)

    guard let suggestion = harness.viewModel.lighteningSuggestions.first else {
        Issue.record("expected a lightening suggestion")
        return
    }
    await harness.viewModel.applySuggestion(suggestion)

    // Postpone moves it off today onto the next day; nothing else touched.
    let todayAfter = (try? await harness.plans.plan(for: Fixture.day)) ?? nil
    #expect(todayAfter?.blocks.isEmpty == true)
    let tomorrow = Fixture.day.advanced(by: 1, calendar: Fixture.calendar)
    let tomorrowAfter = (try? await harness.plans.plan(for: tomorrow)) ?? nil
    #expect(tomorrowAfter?.blocks.count == 1)
    #expect(harness.viewModel.lighteningSuggestions.isEmpty)
}

@MainActor
@Test func lowDemandPersistsAcrossLaunches() async {
    let harness = await makeHarness(plan: nil, at: 9)
    await harness.viewModel.load()
    #expect(harness.viewModel.presentation.invitational == false)

    await harness.viewModel.setLowDemand(true)
    #expect(harness.viewModel.presentation.invitational)

    // A fresh view model over the same stored preferences still sees it on.
    let relaunched = TodayViewModel(
        dayPlans: harness.plans,
        energy: harness.energy,
        wins: harness.wins,
        preferences: harness.preferences,
        dateProvider: Fixture.provider(9)
    )
    await relaunched.load()
    #expect(relaunched.presentation.invitational)
}

@MainActor
@Test func winsNeverRenderZeroAfterHavingCounts() async {
    var prefs = UserPreferences()
    prefs.winsPaused = true
    let wins = [WinEvent(date: Fixture.at(9), kind: .checkIn)]
    let harness = await makeHarness(plan: nil, preferences: prefs, wins: wins, at: 10)

    await harness.viewModel.load()

    // Pausing keeps the existing counts and shows a paused note, not zero.
    #expect(!harness.viewModel.winsSummaries.isEmpty)
    #expect(harness.viewModel.winsArePaused)
    let counts = harness.viewModel.winsSummaries.map(\.count)
    #expect(counts.allSatisfy { $0 > 0 })
}

/// A clock whose `now` can be moved forward, for the midnight-rollover test.
private final class MutableDateProvider: DateProviding, @unchecked Sendable {
    var now: Date
    let calendar: Calendar

    init(now: Date, calendar: Calendar) {
        self.now = now
        self.calendar = calendar
    }
}

@MainActor
@Test func todayRefreshesWhenDayRollsOverPastMidnight() async {
    let provider = MutableDateProvider(now: Fixture.at(23, 50), calendar: Fixture.calendar)
    let viewModel = TodayViewModel(
        dayPlans: InMemoryDayPlanRepository(),
        energy: InMemoryEnergyRepository(),
        wins: InMemoryWinRepository(calendar: Fixture.calendar),
        preferences: InMemoryPreferencesRepository(),
        dateProvider: provider
    )

    await viewModel.load()
    #expect(viewModel.loadedDay == Fixture.day)

    // Same day, ten minutes later: no reload needed.
    provider.now = Fixture.at(23, 55)
    await viewModel.refreshIfDayChanged()
    #expect(viewModel.loadedDay == Fixture.day)

    // Twenty minutes past 23:50 is 00:10 the next day — it should reload.
    provider.now = Fixture.at(23, 50).addingTimeInterval(20 * 60)
    await viewModel.refreshIfDayChanged()
    #expect(viewModel.loadedDay == Fixture.day.advanced(by: 1, calendar: Fixture.calendar))
}
