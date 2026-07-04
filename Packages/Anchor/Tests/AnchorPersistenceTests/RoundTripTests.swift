import Foundation
import Testing
@testable import AnchorCore
@testable import AnchorPersistence

private func makeStore() throws -> SwiftDataStore {
    let container = try ModelContainerFactory.makeContainer(inMemory: true)
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Etc/UTC") ?? .current
    return SwiftDataStore(modelContainer: container, calendar: calendar)
}

private let baseDay = DayDate(year: 2025, month: 6, day: 2)

private func date(_ hour: Int, day: DayDate = baseDay) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Etc/UTC") ?? .current
    var components = DateComponents()
    components.year = day.year
    components.month = day.month
    components.day = day.day
    components.hour = hour
    return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
}

@Test func dayPlanRoundTrips() async throws {
    let store = try makeStore()
    let block = TimeBlock(title: "Morning focus", category: .focus, startTime: date(9), durationMinutes: 60, orderIndex: 0, steps: [BlockStep(title: "Open notes", orderIndex: 0)])
    let plan = DayPlan(date: baseDay, mode: .clock, blocks: [block])

    try await store.upsert(plan)
    let fetched = try await store.plan(for: baseDay)

    #expect(fetched?.id == plan.id)
    #expect(fetched?.blocks.first?.title == "Morning focus")
    #expect(fetched?.blocks.first?.steps.first?.title == "Open notes")
}

@Test func dayPlanUniquePerDayInStore() async throws {
    let store = try makeStore()
    try await store.upsert(DayPlan(date: baseDay, blocks: [TimeBlock(title: "First", category: .focus, orderIndex: 0)]))
    try await store.upsert(DayPlan(date: baseDay, blocks: [TimeBlock(title: "Second", category: .care, orderIndex: 0)]))

    let all = try await store.allPlans()
    #expect(all.count == 1)
    #expect(all.first?.blocks.first?.title == "Second")
}

@Test func dayPlanRangeQueryInStore() async throws {
    let store = try makeStore()
    for offset in 0..<5 {
        let day = baseDay.advanced(by: offset, calendar: Calendar(identifier: .gregorian))
        try await store.upsert(DayPlan(date: day))
    }
    let range = baseDay...baseDay.advanced(by: 2, calendar: Calendar(identifier: .gregorian))
    let found = try await store.plans(in: range)

    #expect(found.count == 3)
}

@Test func goalRoundTripsWithSteps() async throws {
    let store = try makeStore()
    let ifThen = IfThenPlan(triggerKind: .time, triggerMinutes: 9 * 60)
    let step = GoalStep(title: "Draft outline", orderIndex: 0, ifThenPlans: [ifThen])
    let goal = Goal(title: "Write the thing", steps: [step])

    try await store.upsert(goal)
    let fetched = try await store.all(includeArchived: false)

    #expect(fetched.count == 1)
    #expect(fetched.first?.steps.first?.ifThenPlans.first?.triggerMinutes == 9 * 60)
}

@Test func archivedGoalsHiddenInStore() async throws {
    let store = try makeStore()
    try await store.upsert(Goal(title: "Active"))
    try await store.upsert(Goal(title: "Done with", isArchived: true))

    #expect(try await store.all(includeArchived: false).count == 1)
    #expect(try await store.all(includeArchived: true).count == 2)
}

@Test func winsAppendOnlyInStore() async throws {
    let store = try makeStore()
    try await store.append(WinEvent(date: date(9), kind: .checkIn))
    try await store.append(WinEvent(date: date(10), kind: .rest))

    #expect(try await store.allEvents().count == 2)
}

@Test func energyUniquePerDayInStore() async throws {
    let store = try makeStore()
    try await store.upsert(EnergyCheckIn(day: baseDay, level: 2))
    try await store.upsert(EnergyCheckIn(day: baseDay, level: 5))

    let all = try await store.all()
    #expect(all.count == 1)
    #expect(all.first?.level == 5)
}

@Test func preferencesDefaultsThenPersist() async throws {
    let store = try makeStore()
    let first = try await store.load()
    #expect(first.soundEnabled == false)

    var updated = first
    updated.lowDemandMode = true
    try await store.save(updated)

    #expect(try await store.load().lowDemandMode == true)
}

@Test func reflectionRoundTripsInStore() async throws {
    let store = try makeStore()
    try await store.upsert(MoodCheckIn(date: date(20), bodySensations: ["settled stomach"], isUnsure: true))
    try await store.upsert(JournalEntry(date: date(20), text: "Enough for today."))

    #expect(try await store.allCheckIns().first?.isUnsure == true)
    #expect(try await store.allJournalEntries().first?.text == "Enough for today.")
}

@Test func wipeAllClearsEverything() async throws {
    let store = try makeStore()
    try await store.upsert(DayPlan(date: baseDay))
    try await store.upsert(Goal(title: "Something"))
    try await store.append(WinEvent(date: date(9), kind: .checkIn))

    try await store.wipeAll()

    #expect(try await store.allPlans().isEmpty)
    #expect(try await store.all(includeArchived: true).isEmpty)
    #expect(try await store.allEvents().isEmpty)
}
