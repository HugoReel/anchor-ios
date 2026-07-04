import Foundation
import Testing
@testable import AnchorCore

private let newYork = TestSupport.newYork

@Test func dayPlanUpsertThenFetchRoundTrips() async throws {
    let repo = InMemoryDayPlanRepository()
    let plan = TestSupport.plan(blocks: [TestSupport.block("Focus", startHour: 9, minutes: 60, order: 0)])

    try await repo.upsert(plan)
    let fetched = try await repo.plan(for: plan.date)

    #expect(fetched?.id == plan.id)
    #expect(fetched?.blocks.count == 1)
}

@Test func dayPlanUniquePerDay() async throws {
    let repo = InMemoryDayPlanRepository()
    let first = TestSupport.plan(blocks: [TestSupport.block("First", startHour: 9, minutes: 60, order: 0)])
    let second = DayPlan(date: first.date, mode: .clock, blocks: [TestSupport.block("Second", startHour: 10, minutes: 30, order: 0)])

    try await repo.upsert(first)
    try await repo.upsert(second)

    let all = try await repo.allPlans()
    #expect(all.count == 1)
    #expect(all.first?.id == second.id)
}

@Test func dayPlanRangeQuery() async throws {
    let repo = InMemoryDayPlanRepository()
    let dayOne = DayDate(year: 2025, month: 6, day: 1)
    let dayFive = DayDate(year: 2025, month: 6, day: 5)
    let dayTen = DayDate(year: 2025, month: 6, day: 10)
    for day in [dayOne, dayFive, dayTen] {
        try await repo.upsert(DayPlan(date: day))
    }

    let middle = try await repo.plans(in: dayOne...dayFive)
    #expect(middle.count == 2)
    #expect(middle.map(\.date) == [dayOne, dayFive])
}

@Test func energyUniquePerDay() async throws {
    let repo = InMemoryEnergyRepository()
    let day = TestSupport.baseDay
    try await repo.upsert(EnergyCheckIn(day: day, level: 2))
    try await repo.upsert(EnergyCheckIn(day: day, level: 4))

    let all = try await repo.all()
    #expect(all.count == 1)
    #expect(all.first?.level == 4)
}

@Test func winsAppendAccumulate() async throws {
    let repo = InMemoryWinRepository(calendar: newYork)
    try await repo.append(WinEvent(date: TestSupport.time(9), kind: .checkIn))
    try await repo.append(WinEvent(date: TestSupport.time(10), kind: .blockDone))

    let all = try await repo.allEvents()
    #expect(all.count == 2)
}

@Test func winsRangeQueryFiltersByDay() async throws {
    let repo = InMemoryWinRepository(calendar: newYork)
    let inRange = DayDate(year: 2025, month: 6, day: 3)
    let outOfRange = DayDate(year: 2025, month: 7, day: 1)
    try await repo.append(WinEvent(date: TestSupport.time(9, day: inRange), kind: .checkIn))
    try await repo.append(WinEvent(date: TestSupport.time(9, day: outOfRange), kind: .checkIn))

    let june = try await repo.events(in: DayDate(year: 2025, month: 6, day: 1)...DayDate(year: 2025, month: 6, day: 30))
    #expect(june.count == 1)
}

@Test func goalArchiveFiltering() async throws {
    let repo = InMemoryGoalRepository()
    try await repo.upsert(Goal(title: "Active"))
    try await repo.upsert(Goal(title: "Archived", isArchived: true))

    let visible = try await repo.all(includeArchived: false)
    let everything = try await repo.all(includeArchived: true)
    #expect(visible.count == 1)
    #expect(everything.count == 2)
}

@Test func preferencesLoadReturnsDefaultsFirstRun() async throws {
    let repo = InMemoryPreferencesRepository()
    let loaded = try await repo.load()

    #expect(loaded.soundEnabled == false)
    #expect(loaded.showWins == true)
    #expect(loaded.transitionLeadMinutes == 15)
    #expect(loaded.onboardingComplete == false)
}

@Test func preferencesSaveThenLoad() async throws {
    let repo = InMemoryPreferencesRepository()
    var preferences = try await repo.load()
    preferences.lowDemandMode = true
    preferences.themeRawValue = "warm"
    try await repo.save(preferences)

    let reloaded = try await repo.load()
    #expect(reloaded.lowDemandMode == true)
    #expect(reloaded.themeRawValue == "warm")
}

@Test func reflectionCheckInAndJournalRoundTrip() async throws {
    let repo = InMemoryReflectionRepository(calendar: newYork)
    let checkIn = MoodCheckIn(date: TestSupport.time(20), bodySensations: ["tired eyes"], isUnsure: true)
    let entry = JournalEntry(date: TestSupport.time(20), text: "A quiet evening.")
    try await repo.upsert(checkIn)
    try await repo.upsert(entry)

    let checkIns = try await repo.allCheckIns()
    let entries = try await repo.allJournalEntries()
    #expect(checkIns.first?.isUnsure == true)
    #expect(entries.first?.text == "A quiet evening.")
}

@Test func exporterProducesHumanReadableJSON() async throws {
    let dayPlans = InMemoryDayPlanRepository()
    try await dayPlans.upsert(TestSupport.plan(blocks: [TestSupport.block("Focus", startHour: 9, minutes: 60, order: 0)]))
    let exporter = DataExporter(
        dayPlans: dayPlans,
        templates: InMemoryTemplateRepository(),
        goals: InMemoryGoalRepository(),
        reflections: InMemoryReflectionRepository(calendar: newYork),
        energy: InMemoryEnergyRepository(),
        wins: InMemoryWinRepository(calendar: newYork),
        coping: InMemoryCopingRepository(),
        preferences: InMemoryPreferencesRepository()
    )

    let data = try await exporter.exportJSON(now: TestSupport.time(21))
    let text = String(decoding: data, as: UTF8.self)
    #expect(text.contains("\"schemaVersion\" : 1"))
    #expect(text.contains("Focus"))

    // Round-trips back to a payload.
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let payload = try decoder.decode(ExportPayload.self, from: data)
    #expect(payload.dayPlans.count == 1)
}
