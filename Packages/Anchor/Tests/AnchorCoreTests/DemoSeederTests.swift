import Foundation
import Testing
@testable import AnchorCore

@MainActor
private func makeSeeder(
    dayPlans: InMemoryDayPlanRepository,
    goals: InMemoryGoalRepository,
    coping: InMemoryCopingRepository,
    preferences: InMemoryPreferencesRepository
) -> DemoSeeder {
    let calendar = Calendar(identifier: .gregorian)
    return DemoSeeder(
        dayPlans: dayPlans,
        goals: goals,
        reflections: InMemoryReflectionRepository(calendar: calendar),
        energy: InMemoryEnergyRepository(),
        wins: InMemoryWinRepository(calendar: calendar),
        coping: coping,
        preferences: preferences,
        dateProvider: FixedDateProvider(now: Date(timeIntervalSince1970: 1_700_000_000), calendar: calendar)
    )
}

@MainActor
@Test func seedDataOnlyBehindFlag() async throws {
    let dayPlans = InMemoryDayPlanRepository()
    let goals = InMemoryGoalRepository()
    let coping = InMemoryCopingRepository()
    let preferences = InMemoryPreferencesRepository()
    let seeder = makeSeeder(dayPlans: dayPlans, goals: goals, coping: coping, preferences: preferences)

    // Disabled: nothing is written.
    await seeder.seedIfNeeded(enabled: false)
    let plansOff = try await dayPlans.allPlans()
    let goalsOff = try await goals.allGoals(includeArchived: true)
    #expect(plansOff.isEmpty)
    #expect(goalsOff.isEmpty)

    // Enabled: a representative dataset appears.
    await seeder.seedIfNeeded(enabled: true)
    let plansOn = try await dayPlans.allPlans()
    let goalsOn = try await goals.allGoals(includeArchived: true)
    let copingOn = try await coping.allCoping()
    #expect(!plansOn.isEmpty)
    #expect(goalsOn.count >= 2)
    #expect(!copingOn.isEmpty)

    // Idempotent: a second enabled run does not duplicate.
    await seeder.seedIfNeeded(enabled: true)
    let plansAgain = try await dayPlans.allPlans()
    #expect(plansAgain.count == plansOn.count)
}
