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
