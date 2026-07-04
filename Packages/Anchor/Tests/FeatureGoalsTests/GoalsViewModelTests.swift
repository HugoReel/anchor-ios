import Foundation
import Testing
import AnchorCore
@testable import FeatureGoals

@MainActor
private struct Setup {
    let viewModel: GoalsViewModel
    let goals: InMemoryGoalRepository
    let wins: InMemoryWinRepository
}

@MainActor
private enum Fixture {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    static let now = DayDate(year: 2025, month: 6, day: 2)

    static func setup(goals initial: [Goal] = []) async -> Setup {
        let goalRepo = InMemoryGoalRepository()
        for goal in initial {
            try? await goalRepo.upsert(goal)
        }
        let winRepo = InMemoryWinRepository(calendar: calendar)
        let prefsRepo = InMemoryPreferencesRepository()
        let provider = FixedDateProvider(now: now.startDate(calendar: calendar), calendar: calendar)
        let viewModel = GoalsViewModel(
            goals: goalRepo,
            wins: winRepo,
            preferences: prefsRepo,
            dateProvider: provider
        )
        return Setup(viewModel: viewModel, goals: goalRepo, wins: winRepo)
    }
}

@MainActor
@Test func loadShowsActiveGoalsOnly() async {
    let active = Goal(title: "Learn to bake bread")
    let archived = Goal(title: "Done with this", isArchived: true)
    let setup = await Fixture.setup(goals: [active, archived])

    await setup.viewModel.load()

    #expect(setup.viewModel.goals.map(\.title) == ["Learn to bake bread"])
}

@MainActor
@Test func upsertGoalAddsAndPersists() async {
    let setup = await Fixture.setup()
    await setup.viewModel.load()

    await setup.viewModel.upsertGoal(Goal(title: "Sort the spare room"))

    #expect(setup.viewModel.goals.count == 1)
    let stored = (try? await setup.goals.allGoals(includeArchived: true)) ?? []
    #expect(stored.first?.title == "Sort the spare room")
}

@MainActor
@Test func addStepAppendsInOrder() async {
    let goal = Goal(title: "Learn to bake bread")
    let setup = await Fixture.setup(goals: [goal])
    await setup.viewModel.load()

    await setup.viewModel.addStep(goalID: goal.id, title: "Buy flour")
    await setup.viewModel.addStep(goalID: goal.id, title: "Find a recipe")

    let steps = setup.viewModel.goals.first?.steps ?? []
    #expect(steps.map(\.title) == ["Buy flour", "Find a recipe"])
    #expect(steps.map(\.orderIndex) == [0, 1])
}

@MainActor
@Test func toggleStepAccruesProgressAndMintsWin() async {
    let step = GoalStep(title: "Buy flour", orderIndex: 0)
    let goal = Goal(title: "Learn to bake bread", steps: [step, GoalStep(title: "Recipe", orderIndex: 1)])
    let setup = await Fixture.setup(goals: [goal])
    await setup.viewModel.load()

    await setup.viewModel.toggleStep(goalID: goal.id, stepID: step.id)

    let updated = setup.viewModel.goals.first
    #expect(updated?.steps.first?.isDone == true)
    #expect(abs((updated?.progress ?? 0) - 0.5) < 0.001)
    let events = (try? await setup.wins.allEvents()) ?? []
    #expect(events.first?.kind == .goalStepDone)
}

@MainActor
@Test func untoggleStepKeepsWin() async {
    let step = GoalStep(title: "Buy flour", orderIndex: 0)
    let goal = Goal(title: "Learn to bake bread", steps: [step])
    let setup = await Fixture.setup(goals: [goal])
    await setup.viewModel.load()

    await setup.viewModel.toggleStep(goalID: goal.id, stepID: step.id)
    await setup.viewModel.toggleStep(goalID: goal.id, stepID: step.id)

    #expect(setup.viewModel.goals.first?.steps.first?.isDone == false)
    // Progress recomputes, but the earned win is never taken back.
    let events = (try? await setup.wins.allEvents()) ?? []
    #expect(events.count == 1)
}

@MainActor
@Test func archiveGoalHidesItWithoutDeleting() async {
    let goal = Goal(title: "Learn to bake bread")
    let setup = await Fixture.setup(goals: [goal])
    await setup.viewModel.load()

    await setup.viewModel.archiveGoal(id: goal.id)

    #expect(setup.viewModel.goals.isEmpty)
    let stored = (try? await setup.goals.allGoals(includeArchived: true)) ?? []
    #expect(stored.first?.isArchived == true)
}

@MainActor
@Test func addIfThenPlanToStep() async {
    let step = GoalStep(title: "Buy flour", orderIndex: 0)
    let goal = Goal(title: "Learn to bake bread", steps: [step])
    let setup = await Fixture.setup(goals: [goal])
    await setup.viewModel.load()

    let plan = IfThenPlan(triggerKind: .time, triggerMinutes: 10 * 60)
    await setup.viewModel.addIfThen(goalID: goal.id, stepID: step.id, plan: plan)

    let plans = setup.viewModel.goals.first?.steps.first?.ifThenPlans ?? []
    #expect(plans.count == 1)
    #expect(plans.first?.triggerMinutes == 10 * 60)
}

@MainActor
@Test func targetDateNeverProducesCountdownString() async {
    let goal = Goal(title: "Learn to bake bread", targetDate: DayDate(year: 2026, month: 6, day: 15))
    let setup = await Fixture.setup(goals: [goal])
    await setup.viewModel.load()

    let label = setup.viewModel.targetLabel(for: goal)

    #expect(label != nil)
    if let label {
        #expect(label.contains("2026"))
        let lowered = label.lowercased()
        #expect(!lowered.contains("left"))
        #expect(!lowered.contains("remaining"))
        #expect(!lowered.contains("overdue"))
        #expect(!lowered.contains("countdown"))
    }
}

@MainActor
@Test func goalWithoutTargetHasNoLabel() async {
    let goal = Goal(title: "Learn to bake bread")
    let setup = await Fixture.setup(goals: [goal])
    await setup.viewModel.load()

    #expect(setup.viewModel.targetLabel(for: goal) == nil)
}
