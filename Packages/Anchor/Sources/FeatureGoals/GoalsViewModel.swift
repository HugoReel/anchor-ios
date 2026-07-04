import Foundation
import Observation
import AnchorCore

/// Drives Goals. Progress only ever accrues: completing a step mints a win
/// that is never taken back, and there are no streaks, decay or shame states.
@MainActor
@Observable
public final class GoalsViewModel {
    public private(set) var goals: [Goal] = []
    public private(set) var loadFailed = false

    private let goalRepository: any GoalRepository
    private let wins: any WinRepository
    private let preferences: any PreferencesRepository
    private let dateProvider: any DateProviding
    private var preferencesValue = UserPreferences()

    public init(
        goals: any GoalRepository,
        wins: any WinRepository,
        preferences: any PreferencesRepository,
        dateProvider: any DateProviding
    ) {
        self.goalRepository = goals
        self.wins = wins
        self.preferences = preferences
        self.dateProvider = dateProvider
    }

    public func load() async {
        loadFailed = false
        do {
            preferencesValue = try await preferences.load()
            goals = try await goalRepository.allGoals(includeArchived: false)
        } catch {
            loadFailed = true
        }
    }

    public func upsertGoal(_ goal: Goal) async {
        var updated = goal
        updated.modifiedAt = dateProvider.now
        await save(updated)
    }

    public func archiveGoal(id: UUID) async {
        guard var goal = goals.first(where: { $0.id == id }) else { return }
        goal.isArchived = true
        goal.modifiedAt = dateProvider.now
        await save(goal)
    }

    public func addStep(goalID: UUID, title: String) async {
        guard var goal = goals.first(where: { $0.id == goalID }) else { return }
        let now = dateProvider.now
        let step = GoalStep(title: title, orderIndex: goal.steps.count, createdAt: now, modifiedAt: now)
        goal.steps.append(step)
        goal.modifiedAt = now
        await save(goal)
    }

    public func toggleStep(goalID: UUID, stepID: UUID) async {
        guard var goal = goals.first(where: { $0.id == goalID }),
              let index = goal.steps.firstIndex(where: { $0.id == stepID }) else { return }
        let now = dateProvider.now
        var step = goal.steps[index]

        if step.isDone {
            // Un-checking never removes the earned win — progress only accrues.
            step.isDone = false
            step.completedAt = nil
        } else {
            step.isDone = true
            step.completedAt = now
        }
        step.modifiedAt = now
        goal.steps[index] = step
        goal.modifiedAt = now

        if step.isDone, let win = WinsEngine.mintedWin(for: .goalStepDone(step), preferences: preferencesValue, at: now) {
            try? await wins.append(win)
        }
        await save(goal)
    }

    public func addIfThen(goalID: UUID, stepID: UUID, plan: IfThenPlan) async {
        guard var goal = goals.first(where: { $0.id == goalID }),
              let index = goal.steps.firstIndex(where: { $0.id == stepID }) else { return }
        let now = dateProvider.now
        goal.steps[index].ifThenPlans.append(plan)
        goal.steps[index].modifiedAt = now
        goal.modifiedAt = now
        await save(goal)
    }

    /// A calm target-date label, or nil when there is no target. Never a
    /// countdown, never "days left" or "overdue" — just the date.
    public func targetLabel(for goal: Goal) -> String? {
        guard let target = goal.targetDate else { return nil }
        let date = target.startDate(calendar: dateProvider.calendar)
        return "Aiming for \(Self.dateFormatter.string(from: date))"
    }

    private func save(_ goal: Goal) async {
        do {
            try await goalRepository.upsert(goal)
            goals = try await goalRepository.allGoals(includeArchived: false)
        } catch {
            loadFailed = true
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
}
