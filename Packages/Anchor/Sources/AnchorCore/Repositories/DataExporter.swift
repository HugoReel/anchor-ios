import Foundation

/// Everything the user owns, in one human-readable document.
public struct ExportPayload: Codable, Sendable {
    public let exportedAt: Date
    public let schemaVersion: Int
    public let dayPlans: [DayPlan]
    public let templates: [DayTemplate]
    public let goals: [Goal]
    public let moodCheckIns: [MoodCheckIn]
    public let journalEntries: [JournalEntry]
    public let energyCheckIns: [EnergyCheckIn]
    public let winEvents: [WinEvent]
    public let copingStrategies: [CopingStrategy]
    public let preferences: UserPreferences
}

/// Builds the export document from the repositories. The user owns their
/// data: pretty-printed, stable key order, ISO 8601 dates.
public struct DataExporter: Sendable {
    private let dayPlans: any DayPlanRepository
    private let templates: any TemplateRepository
    private let goals: any GoalRepository
    private let reflections: any ReflectionRepository
    private let energy: any EnergyRepository
    private let wins: any WinRepository
    private let coping: any CopingRepository
    private let preferences: any PreferencesRepository

    public init(
        dayPlans: any DayPlanRepository,
        templates: any TemplateRepository,
        goals: any GoalRepository,
        reflections: any ReflectionRepository,
        energy: any EnergyRepository,
        wins: any WinRepository,
        coping: any CopingRepository,
        preferences: any PreferencesRepository
    ) {
        self.dayPlans = dayPlans
        self.templates = templates
        self.goals = goals
        self.reflections = reflections
        self.energy = energy
        self.wins = wins
        self.coping = coping
        self.preferences = preferences
    }

    public func exportJSON(now: Date) async throws -> Data {
        let payload = ExportPayload(
            exportedAt: now,
            schemaVersion: 1,
            dayPlans: try await dayPlans.allPlans(),
            templates: try await templates.allTemplates(),
            goals: try await goals.allGoals(includeArchived: true),
            moodCheckIns: try await reflections.allCheckIns(),
            journalEntries: try await reflections.allJournalEntries(),
            energyCheckIns: try await energy.allEnergyCheckIns(),
            winEvents: try await wins.allEvents(),
            copingStrategies: try await coping.allCoping(),
            preferences: try await preferences.load()
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }
}
