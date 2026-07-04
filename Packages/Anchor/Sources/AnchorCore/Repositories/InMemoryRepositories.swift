import Foundation

/// In-memory repository implementations for tests and SwiftUI previews.
/// Behaviour must stay interchangeable with the SwiftData implementations;
/// LiveRepositoryTests runs the same assertions against both.

public actor InMemoryDayPlanRepository: DayPlanRepository {
    private var storage: [UUID: DayPlan] = [:]

    public init() {}

    public func plan(for day: DayDate) async throws -> DayPlan? {
        storage.values.first { $0.date == day }
    }

    public func plans(in range: ClosedRange<DayDate>) async throws -> [DayPlan] {
        storage.values.filter { range.contains($0.date) }.sorted { $0.date < $1.date }
    }

    public func allPlans() async throws -> [DayPlan] {
        storage.values.sorted { $0.date < $1.date }
    }

    public func upsert(_ plan: DayPlan) async throws {
        // One plan per day: replace any existing plan for the same date.
        for (id, existing) in storage where existing.date == plan.date && id != plan.id {
            storage[id] = nil
        }
        storage[plan.id] = plan
    }

    public func delete(id: UUID) async throws {
        storage[id] = nil
    }
}

public actor InMemoryTemplateRepository: TemplateRepository {
    private var storage: [UUID: DayTemplate] = [:]

    public init() {}

    public func all() async throws -> [DayTemplate] {
        storage.values.sorted { $0.name < $1.name }
    }

    public func upsert(_ template: DayTemplate) async throws {
        storage[template.id] = template
    }

    public func delete(id: UUID) async throws {
        storage[id] = nil
    }
}

public actor InMemoryGoalRepository: GoalRepository {
    private var storage: [UUID: Goal] = [:]

    public init() {}

    public func all(includeArchived: Bool) async throws -> [Goal] {
        storage.values
            .filter { includeArchived || !$0.isArchived }
            .sorted { $0.createdAt < $1.createdAt }
    }

    public func upsert(_ goal: Goal) async throws {
        storage[goal.id] = goal
    }

    public func delete(id: UUID) async throws {
        storage[id] = nil
    }
}

public actor InMemoryReflectionRepository: ReflectionRepository {
    private var checkInStorage: [UUID: MoodCheckIn] = [:]
    private var journalStorage: [UUID: JournalEntry] = [:]
    private let calendar: Calendar

    public init(calendar: Calendar) {
        self.calendar = calendar
    }

    public func checkIns(in range: ClosedRange<DayDate>) async throws -> [MoodCheckIn] {
        checkInStorage.values
            .filter { range.contains(DayDate(date: $0.date, calendar: calendar)) }
            .sorted { $0.date < $1.date }
    }

    public func allCheckIns() async throws -> [MoodCheckIn] {
        checkInStorage.values.sorted { $0.date < $1.date }
    }

    public func upsert(_ checkIn: MoodCheckIn) async throws {
        checkInStorage[checkIn.id] = checkIn
    }

    public func delete(checkInID: UUID) async throws {
        checkInStorage[checkInID] = nil
    }

    public func journalEntries(in range: ClosedRange<DayDate>) async throws -> [JournalEntry] {
        journalStorage.values
            .filter { range.contains(DayDate(date: $0.date, calendar: calendar)) }
            .sorted { $0.date < $1.date }
    }

    public func allJournalEntries() async throws -> [JournalEntry] {
        journalStorage.values.sorted { $0.date < $1.date }
    }

    public func upsert(_ entry: JournalEntry) async throws {
        journalStorage[entry.id] = entry
    }

    public func delete(journalID: UUID) async throws {
        journalStorage[journalID] = nil
    }
}

public actor InMemoryEnergyRepository: EnergyRepository {
    private var storage: [UUID: EnergyCheckIn] = [:]

    public init() {}

    public func checkIn(for day: DayDate) async throws -> EnergyCheckIn? {
        storage.values.first { $0.day == day }
    }

    public func all() async throws -> [EnergyCheckIn] {
        storage.values.sorted { $0.day < $1.day }
    }

    public func upsert(_ checkIn: EnergyCheckIn) async throws {
        // One check-in per day: replace any existing entry for the same day.
        for (id, existing) in storage where existing.day == checkIn.day && id != checkIn.id {
            storage[id] = nil
        }
        storage[checkIn.id] = checkIn
    }
}

public actor InMemoryWinRepository: WinRepository {
    private var storage: [WinEvent] = []
    private let calendar: Calendar

    public init(calendar: Calendar) {
        self.calendar = calendar
    }

    public func events(in range: ClosedRange<DayDate>) async throws -> [WinEvent] {
        storage
            .filter { range.contains(DayDate(date: $0.date, calendar: calendar)) }
            .sorted { $0.date < $1.date }
    }

    public func allEvents() async throws -> [WinEvent] {
        storage.sorted { $0.date < $1.date }
    }

    public func append(_ event: WinEvent) async throws {
        storage.append(event)
    }
}

public actor InMemoryCopingRepository: CopingRepository {
    private var storage: [UUID: CopingStrategy] = [:]

    public init() {}

    public func all() async throws -> [CopingStrategy] {
        storage.values.sorted { $0.orderIndex < $1.orderIndex }
    }

    public func upsert(_ strategy: CopingStrategy) async throws {
        storage[strategy.id] = strategy
    }

    public func delete(id: UUID) async throws {
        storage[id] = nil
    }
}

public actor InMemoryPreferencesRepository: PreferencesRepository {
    private var stored: UserPreferences?

    public init() {}

    public func load() async throws -> UserPreferences {
        stored ?? UserPreferences()
    }

    public func save(_ preferences: UserPreferences) async throws {
        stored = preferences
    }
}
