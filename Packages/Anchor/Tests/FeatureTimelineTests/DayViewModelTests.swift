import Foundation
import Testing
import AnchorCore
@testable import FeatureTimeline

@MainActor
private struct Setup {
    let viewModel: DayViewModel
    let wins: InMemoryWinRepository
    let plans: InMemoryDayPlanRepository
}

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

    static func setup(
        plan: DayPlan,
        preferences: UserPreferences = UserPreferences(),
        at hour: Int,
        _ minute: Int = 0
    ) async -> Setup {
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
            dateProvider: FixedDateProvider(now: at(hour, minute), calendar: calendar)
        )
        return Setup(viewModel: viewModel, wins: winRepo, plans: plans)
    }
}

@MainActor
@Test func loadReadsPlanForDay() async {
    let plan = DayPlan(date: Fixture.day, blocks: [Fixture.block("Focus", start: 9, minutes: 60, order: 0)])
    let viewModel = await Fixture.setup(plan: plan, at: 8).viewModel

    await viewModel.load()

    #expect(viewModel.blocks.count == 1)
    #expect(viewModel.blocks.first?.title == "Focus")
}

@MainActor
@Test func toggleDoneMarksBlockAndMintsWin() async {
    let block = Fixture.block("Focus", start: 9, minutes: 60, order: 0)
    let plan = DayPlan(date: Fixture.day, blocks: [block])
    let setup = await Fixture.setup(plan: plan, at: 10)
    await setup.viewModel.load()

    await setup.viewModel.toggleDone(blockID: block.id)

    #expect(setup.viewModel.blocks.first?.state == .done)
    let events = (try? await setup.wins.allEvents()) ?? []
    #expect(events.count == 1)
    let stored = (try? await setup.plans.plan(for: Fixture.day)) ?? nil
    #expect(stored?.blocks.first?.state == .done)
}

@MainActor
@Test func toggleUndoneKeepsWin() async {
    let block = Fixture.block("Focus", start: 9, minutes: 60, order: 0)
    let plan = DayPlan(date: Fixture.day, blocks: [block])
    let setup = await Fixture.setup(plan: plan, at: 10)
    await setup.viewModel.load()

    await setup.viewModel.toggleDone(blockID: block.id)
    await setup.viewModel.toggleDone(blockID: block.id)

    #expect(setup.viewModel.blocks.first?.state == .notStarted)
    // Wins never reset: the earned win stays.
    let events = (try? await setup.wins.allEvents()) ?? []
    #expect(events.count == 1)
}

@MainActor
@Test func restCompletionMintsRestWin() async {
    let rest = Fixture.block("Quiet time", category: .rest, start: 14, minutes: 30, order: 0)
    let plan = DayPlan(date: Fixture.day, blocks: [rest])
    let setup = await Fixture.setup(plan: plan, at: 14)
    await setup.viewModel.load()

    await setup.viewModel.toggleDone(blockID: rest.id)

    let events = (try? await setup.wins.allEvents()) ?? []
    #expect(events.first?.kind == .rest)
}

@MainActor
@Test func pausedWinsToggleMintsNothing() async {
    var prefs = UserPreferences()
    prefs.winsPaused = true
    let block = Fixture.block("Focus", start: 9, minutes: 60, order: 0)
    let plan = DayPlan(date: Fixture.day, blocks: [block])
    let setup = await Fixture.setup(plan: plan, preferences: prefs, at: 10)
    await setup.viewModel.load()

    await setup.viewModel.toggleDone(blockID: block.id)

    #expect(setup.viewModel.blocks.first?.state == .done)
    let events = (try? await setup.wins.allEvents()) ?? []
    #expect(events.isEmpty)
}

@MainActor
@Test func switchModeConvertsAndPersistsLosingNoData() async {
    let plan = DayPlan(date: Fixture.day, mode: .clock, blocks: [Fixture.block("Focus", start: 9, minutes: 60, order: 0)])
    let setup = await Fixture.setup(plan: plan, at: 8)
    await setup.viewModel.load()

    await setup.viewModel.switchMode()

    #expect(setup.viewModel.plan.mode == .sequence)
    // Times are retained dormant, not lost.
    #expect(setup.viewModel.blocks.first?.startTime == Fixture.at(9))
    let stored = (try? await setup.plans.plan(for: Fixture.day)) ?? nil
    #expect(stored?.mode == .sequence)
}

@MainActor
@Test func shiftDayMovesFutureBlocks() async {
    let done = Fixture.block("Morning", start: 9, minutes: 50, order: 0, state: .done)
    let upcoming = Fixture.block("Errand", category: .out, start: 10, minutes: 60, order: 1)
    let plan = DayPlan(date: Fixture.day, blocks: [done, upcoming])
    // Running 20 minutes late: now is 10:20, the upcoming block began at 10:00.
    let setup = await Fixture.setup(plan: plan, at: 10, 20)
    await setup.viewModel.load()

    await setup.viewModel.shiftDay()

    let moved = setup.viewModel.plan.block(withID: upcoming.id)
    #expect(moved?.startTime == Fixture.at(10, 20))
}

@MainActor
@Test func convertToRestChangesCategory() async {
    let block = Fixture.block("Chores", category: .home, start: 13, minutes: 60, order: 0)
    let plan = DayPlan(date: Fixture.day, blocks: [block])
    let setup = await Fixture.setup(plan: plan, at: 12)
    await setup.viewModel.load()

    await setup.viewModel.convertToRest(blockID: block.id)

    #expect(setup.viewModel.plan.block(withID: block.id)?.category == .rest)
    let stored = (try? await setup.plans.plan(for: Fixture.day)) ?? nil
    #expect(stored?.block(withID: block.id)?.category == .rest)
}
