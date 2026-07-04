import Foundation

/// One protocol per aggregate. Defined in Core, implemented twice: SwiftData
/// in AnchorPersistence, in-memory actors here for tests and previews.
/// Features only ever see these protocols.

public protocol DayPlanRepository: Sendable {
    func plan(for day: DayDate) async throws -> DayPlan?
    func plans(in range: ClosedRange<DayDate>) async throws -> [DayPlan]
    func allPlans() async throws -> [DayPlan]
    func upsert(_ plan: DayPlan) async throws
    func delete(id: UUID) async throws
}

public protocol TemplateRepository: Sendable {
    func all() async throws -> [DayTemplate]
    func upsert(_ template: DayTemplate) async throws
    func delete(id: UUID) async throws
}

public protocol GoalRepository: Sendable {
    func all(includeArchived: Bool) async throws -> [Goal]
    func upsert(_ goal: Goal) async throws
    func delete(id: UUID) async throws
}

public protocol ReflectionRepository: Sendable {
    func checkIns(in range: ClosedRange<DayDate>) async throws -> [MoodCheckIn]
    func allCheckIns() async throws -> [MoodCheckIn]
    func upsert(_ checkIn: MoodCheckIn) async throws
    func delete(checkInID: UUID) async throws
    func journalEntries(in range: ClosedRange<DayDate>) async throws -> [JournalEntry]
    func allJournalEntries() async throws -> [JournalEntry]
    func upsert(_ entry: JournalEntry) async throws
    func delete(journalID: UUID) async throws
}

public protocol EnergyRepository: Sendable {
    func checkIn(for day: DayDate) async throws -> EnergyCheckIn?
    func all() async throws -> [EnergyCheckIn]
    func upsert(_ checkIn: EnergyCheckIn) async throws
}

/// Append-only by design: the API has no way to delete or reset a win.
public protocol WinRepository: Sendable {
    func events(in range: ClosedRange<DayDate>) async throws -> [WinEvent]
    func allEvents() async throws -> [WinEvent]
    func append(_ event: WinEvent) async throws
}

public protocol CopingRepository: Sendable {
    func all() async throws -> [CopingStrategy]
    func upsert(_ strategy: CopingStrategy) async throws
    func delete(id: UUID) async throws
}

public protocol PreferencesRepository: Sendable {
    /// Returns stored preferences, or spec defaults on first run.
    func load() async throws -> UserPreferences
    func save(_ preferences: UserPreferences) async throws
}

/// Full local wipe, implemented by the persistence layer and triggered
/// only from Settings behind a calm double confirmation.
public protocol DataWiping: Sendable {
    func wipeAll() async throws
}
