import Foundation

/// Populates a representative dataset so every screen has something to show
/// during review. Runs once, only when explicitly enabled (DEBUG builds via
/// `FeatureFlag.seedDemoData`), and is a no-op once `seedDataInserted` is set.
public struct DemoSeeder: Sendable {
    private let dayPlans: any DayPlanRepository
    private let goals: any GoalRepository
    private let reflections: any ReflectionRepository
    private let energy: any EnergyRepository
    private let wins: any WinRepository
    private let coping: any CopingRepository
    private let preferences: any PreferencesRepository
    private let dateProvider: any DateProviding

    public init(
        dayPlans: any DayPlanRepository,
        goals: any GoalRepository,
        reflections: any ReflectionRepository,
        energy: any EnergyRepository,
        wins: any WinRepository,
        coping: any CopingRepository,
        preferences: any PreferencesRepository,
        dateProvider: any DateProviding
    ) {
        self.dayPlans = dayPlans
        self.goals = goals
        self.reflections = reflections
        self.energy = energy
        self.wins = wins
        self.coping = coping
        self.preferences = preferences
        self.dateProvider = dateProvider
    }

    public func seedIfNeeded(enabled: Bool) async {
        guard enabled else { return }
        do {
            var prefs = try await preferences.load()
            guard !prefs.seedDataInserted else { return }
            let now = dateProvider.now
            let calendar = dateProvider.calendar
            let today = DayDate(date: now, calendar: calendar)

            try await seedDay(today, calendar: calendar, now: now)
            try await seedGoals(today, calendar: calendar, now: now)
            try await seedReflections(today, calendar: calendar, now: now)
            try await seedCoping(now: now)

            prefs.seedDataInserted = true
            prefs.modifiedAt = now
            try await preferences.save(prefs)
        } catch {
            // Seeding is best-effort; a failure simply leaves screens empty.
        }
    }

    // MARK: - Day

    private struct BlockSpec {
        let title: String
        let category: BlockCategory
        let hour: Int
        let minutes: Int
        var flexible = false
    }

    private func seedDay(_ today: DayDate, calendar: Calendar, now: Date) async throws {
        let specs = [
            BlockSpec(title: "Slow start", category: .care, hour: 8, minutes: 30),
            BlockSpec(title: "Focused work", category: .focus, hour: 9, minutes: 90),
            BlockSpec(title: "Lunch and a pause", category: .rest, hour: 12, minutes: 45),
            BlockSpec(title: "Errand outside", category: .out, hour: 15, minutes: 60, flexible: true),
            BlockSpec(title: "Call a friend", category: .connect, hour: 18, minutes: 30)
        ]
        let blocks = specs.enumerated().map { index, spec in
            TimeBlock(
                title: spec.title,
                category: spec.category,
                startTime: time(today, spec.hour, calendar: calendar),
                durationMinutes: spec.minutes,
                orderIndex: index,
                isFlexible: spec.flexible,
                createdAt: now,
                modifiedAt: now
            )
        }
        try await dayPlans.upsert(DayPlan(date: today, mode: .clock, blocks: blocks, createdAt: now, modifiedAt: now))
    }

    // MARK: - Goals

    private func seedGoals(_ today: DayDate, calendar: Calendar, now: Date) async throws {
        try await goals.upsert(makeMorningGoal(now: now))
        try await goals.upsert(makeReadingGoal(today, calendar: calendar, now: now))
    }

    private func makeMorningGoal(now: Date) -> Goal {
        let laidOut = GoalStep(
            title: "Lay out clothes the night before",
            isDone: true,
            completedAt: now,
            orderIndex: 0,
            createdAt: now,
            modifiedAt: now
        )
        let quietTime = GoalStep(
            title: "Ten quiet minutes before screens",
            orderIndex: 1,
            ifThenPlans: [IfThenPlan(triggerKind: .time, triggerMinutes: 7 * 60, createdAt: now, modifiedAt: now)],
            createdAt: now,
            modifiedAt: now
        )
        return Goal(
            title: "Set up a calmer morning",
            note: "Small, kind steps. No rush.",
            steps: [laidOut, quietTime],
            createdAt: now,
            modifiedAt: now
        )
    }

    private func makeReadingGoal(_ today: DayDate, calendar: Calendar, now: Date) -> Goal {
        let plan = IfThenPlan(triggerKind: .situation, situationText: "After dinner", createdAt: now, modifiedAt: now)
        let step = GoalStep(
            title: "Keep a book by the sofa",
            orderIndex: 0,
            ifThenPlans: [plan],
            createdAt: now,
            modifiedAt: now
        )
        return Goal(
            title: "Read a little more",
            targetDate: today.advanced(by: 30, calendar: calendar),
            steps: [step],
            createdAt: now,
            modifiedAt: now
        )
    }

    // MARK: - Reflections, energy, wins

    private func seedReflections(_ today: DayDate, calendar: Calendar, now: Date) async throws {
        for dayOffset in 0...5 {
            let day = today.advanced(by: -dayOffset, calendar: calendar)
            let date = time(day, 20, calendar: calendar)
            try await energy.upsert(
                EnergyCheckIn(day: day, level: 2 + (dayOffset % 3), createdAt: date, modifiedAt: date)
            )
            try await wins.append(WinEvent(date: date, kind: .checkIn, createdAt: date, modifiedAt: date))
        }

        try await reflections.upsert(
            MoodCheckIn(
                date: time(today, 20, calendar: calendar),
                bodySensations: ["settled stomach", "tired eyes"],
                energy: 3,
                createdAt: now,
                modifiedAt: now
            )
        )
        try await reflections.upsert(
            MoodCheckIn(date: time(today.advanced(by: -2, calendar: calendar), 21, calendar: calendar), isUnsure: true)
        )
        try await reflections.upsert(
            JournalEntry(
                date: time(today, 21, calendar: calendar),
                text: "A steady day. The slow start helped.",
                createdAt: now,
                modifiedAt: now
            )
        )
        try await seedDayWins(today, calendar: calendar, now: now)
    }

    private func seedDayWins(_ today: DayDate, calendar: Calendar, now: Date) async throws {
        try await wins.append(
            WinEvent(date: time(today, 10, calendar: calendar), kind: .blockDone, label: "Slow start", createdAt: now, modifiedAt: now)
        )
        try await wins.append(
            WinEvent(date: time(today, 13, calendar: calendar), kind: .rest, label: "Lunch and a pause", createdAt: now, modifiedAt: now)
        )
    }

    // MARK: - Coping

    private func seedCoping(now: Date) async throws {
        for strategy in CopingSeeds.examples(now: now) {
            try await coping.upsert(strategy)
        }
    }

    // MARK: - Helpers

    private func time(_ day: DayDate, _ hour: Int, calendar: Calendar) -> Date {
        let start = day.startDate(calendar: calendar)
        return calendar.date(byAdding: DateComponents(hour: hour), to: start) ?? start
    }
}
