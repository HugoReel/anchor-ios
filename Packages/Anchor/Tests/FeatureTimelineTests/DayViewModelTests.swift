import Foundation
import Testing
import AnchorCore
@testable import FeatureTimeline

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

    static func block(
        _ title: String,
        category: BlockCategory = .focus,
        start: Int?,
        minutes: Int?,
        order: Int,
        state: BlockState = .notStarted
    ) -> TimeBlock {
        TimeBlock(
            title: title,
            category: category,
            startTime: start.map { at($0) },
            durationMinutes: minutes,
            orderIndex: order,
            state: state
        )
    }

    static func viewModel(
        plan: DayPlan,
        preferences: UserPreferences = UserPreferences(),
        at hour: Int
    ) async -> (DayViewModel, InMemoryWinRepository, InMemoryDayPlanRepository) {
        let plans = InMemoryDayPlanRepository()
        try? await plans.upsert(plan)
        let winRepo = InMemoryWinRepository(calendar: calendar)
        let prefsRepo = InMemoryPreferencesRepository()
        try? await prefsRepo.save(preferences)
        let viewModel = DayViewModel(
            day: day,
            dayPlans: plans,
            wins: winRepo,
            preferences: prefsRepo,
            dateProvider: FixedDateProvider(now: at(hour), calendar: calendar)
        )
        return (viewModel, winRepo, plans)
    }
}

@MainActor
@Test func loadReadsPlanForDay() async {
    let plan = DayPlan(date: Fixture.day, blocks: [Fixture.block("Focus", start: 9, minutes: 60, order: 0)])
    let (viewModel, _, _) = await Fixture.viewModel(plan: plan, at: 8)

    await viewModel.load()

    #expect(viewModel.blocks.count == 1)
    #expect(viewModel.blocks.first?.title == "Focus")
}

@MainActor
@Test func toggleDoneMarksBlockAndMintsWin() async {
    let block = Fixture.block("Focus", start: 9, minutes: 60, order: 0)
    let plan = DayPlan(date: Fixture.day, blocks: [block])
    let (viewModel, wins, plans) = await Fixture.viewModel(plan: plan, at: 10)
    await viewModel.load()

    await viewModel.toggleDone(blockID: block.id)

    #expect(viewModel.blocks.first?.state == .done)
    let events = (try? await wins.allEvents()) ?? []
    #expect(events.count == 1)
    // Persisted.
    let stored = (try? await plans.plan(for: Fixture.day)) ?? nil
    #expect(stored?.blocks.first?.state == .done)
}

@MainActor
@Test func toggleUndoneKeepsWin() async {
    let block = Fixture.block("Focus", start: 9, minutes: 60, order: 0)
    let plan = DayPlan(date: Fixture.day, blocks: [block])
    let (viewModel, wins, _) = await Fixture.viewModel(plan: plan, at: 10)
    await viewModel.load()

    await viewModel.toggleDone(blockID: block.id)
    await viewModel.toggleDone(blockID: block.id)

    #expect(viewModel.blocks.first?.state == .notStarted)
    // Wins never reset: the earned win stays.
    let events = (try? await wins.allEvents()) ?? []
    #expect(events.count == 1)
}

@MainActor
@Test func restCompletionMintsRestWin() async {
    let rest = Fixture.block("Quiet time", category: .rest, start: 14, minutes: 30, order: 0)
    let plan = DayPlan(date: Fixture.day, blocks: [rest])
    let (viewModel, wins, _) = await Fixture.viewModel(plan: plan, at: 14)
    await viewModel.load()

    await viewModel.toggleDone(blockID: rest.id)

    let events = (try? await wins.allEvents()) ?? []
    #expect(events.first?.kind == .rest)
}

@MainActor
@Test func pausedWinsToggleMintsNothing() async {
    var prefs = UserPreferences()
    prefs.winsPaused = true
    let block = Fixture.block("Focus", start: 9, minutes: 60, order: 0)
    let plan = DayPlan(date: Fixture.day, blocks: [block])
    let (viewModel, wins, _) = await Fixture.viewModel(plan: plan, preferences: prefs, at: 10)
    await viewModel.load()

    await viewModel.toggleDone(blockID: block.id)

    #expect(viewModel.blocks.first?.state == .done)
    let events = (try? await wins.allEvents()) ?? []
    #expect(events.isEmpty)
}

@MainActor
@Test func switchModeConvertsAndPersistsLosingNoData() async {
    let plan = DayPlan(date: Fixture.day, mode: .clock, blocks: [Fixture.block("Focus", start: 9, minutes: 60, order: 0)])
    let (viewModel, _, plans) = await Fixture.viewModel(plan: plan, at: 8)
    await viewModel.load()

    await viewModel.switchMode()

    #expect(viewModel.plan.mode == .sequence)
    // Times are retained dormant, not lost.
    #expect(viewModel.blocks.first?.startTime == Fixture.at(9))
    let stored = (try? await plans.plan(for: Fixture.day)) ?? nil
    #expect(stored?.mode == .sequence)
}

@MainActor
@Test func shiftDayMovesFutureBlocks() async {
    let done = Fixture.block("Morning", start: 9, minutes: 50, order: 0, state: .done)
    let upcoming = Fixture.block("Errand", category: .out, start: 10, minutes: 60, order: 1)
    let plan = DayPlan(date: Fixture.day, blocks: [done, upcoming])
    let (viewModel, _, _) = await Fixture.viewModel(plan: plan, at: 10)
    await viewModel.load()

    // Running 20 minutes late.
    await viewModel.shiftDay()

    let moved = viewModel.plan.block(withID: upcoming.id)
    #expect(moved?.startTime == Fixture.at(10, 20))
}

@MainActor
@Test func convertToRestChangesCategory() async {
    let block = Fixture.block("Chores", category: .home, start: 13, minutes: 60, order: 0)
    let plan = DayPlan(date: Fixture.day, blocks: [block])
    let (viewModel, _, plans) = await Fixture.viewModel(plan: plan, at: 12)
    await viewModel.load()

    await viewModel.convertToRest(blockID: block.id)

    #expect(viewModel.plan.block(withID: block.id)?.category == .rest)
    let stored = (try? await plans.plan(for: Fixture.day)) ?? nil
    #expect(stored?.block(withID: block.id)?.category == .rest)
}
