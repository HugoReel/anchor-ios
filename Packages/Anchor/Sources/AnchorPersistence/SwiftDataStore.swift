import Foundation
import SwiftData
import AnchorCore

/// SwiftData-backed implementation of every repository protocol plus data
/// wiping. Manual `ModelActor` conformance (rather than the `@ModelActor`
/// macro) so a calendar can be injected for deriving day keys from
/// timestamps. All work happens on the actor's own `ModelContext`.
public actor SwiftDataStore: ModelActor {
    public nonisolated let modelContainer: ModelContainer
    public nonisolated let modelExecutor: any ModelExecutor
    private let calendar: Calendar

    public init(modelContainer: ModelContainer, calendar: Calendar) {
        self.modelContainer = modelContainer
        let context = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
        self.calendar = calendar
    }

    private func save() throws {
        do {
            try modelContext.save()
        } catch {
            throw DomainError.storageFailure("could not save changes")
        }
    }

    private func dayKey(for date: Date) -> Int {
        DayDate(date: date, calendar: calendar).numericKey
    }
}

// MARK: - DayPlanRepository

extension SwiftDataStore: DayPlanRepository {
    public func plan(for day: DayDate) async throws -> DayPlan? {
        let key = day.numericKey
        var descriptor = FetchDescriptor<AnchorSchemaV1.DayPlanModel>(predicate: #Predicate { $0.dayKey == key })
        descriptor.fetchLimit = 1
        guard let model = try modelContext.fetch(descriptor).first else { return nil }
        return try PayloadCoder.decode(DayPlan.self, from: model.payload)
    }

    public func plans(in range: ClosedRange<DayDate>) async throws -> [DayPlan] {
        let lower = range.lowerBound.numericKey
        let upper = range.upperBound.numericKey
        let descriptor = FetchDescriptor<AnchorSchemaV1.DayPlanModel>(
            predicate: #Predicate { $0.dayKey >= lower && $0.dayKey <= upper },
            sortBy: [SortDescriptor(\.dayKey)]
        )
        return try modelContext.fetch(descriptor).map { try PayloadCoder.decode(DayPlan.self, from: $0.payload) }
    }

    public func allPlans() async throws -> [DayPlan] {
        let descriptor = FetchDescriptor<AnchorSchemaV1.DayPlanModel>(sortBy: [SortDescriptor(\.dayKey)])
        return try modelContext.fetch(descriptor).map { try PayloadCoder.decode(DayPlan.self, from: $0.payload) }
    }

    public func upsert(_ plan: DayPlan) async throws {
        let key = plan.date.numericKey
        let planID = plan.id
        // Enforce one plan per day: drop any other plan sharing this day.
        let clashing = FetchDescriptor<AnchorSchemaV1.DayPlanModel>(
            predicate: #Predicate { $0.dayKey == key && $0.id != planID }
        )
        for stale in try modelContext.fetch(clashing) {
            modelContext.delete(stale)
        }
        let payload = try PayloadCoder.encode(plan)
        let existing = FetchDescriptor<AnchorSchemaV1.DayPlanModel>(predicate: #Predicate { $0.id == planID })
        if let model = try modelContext.fetch(existing).first {
            model.dayKey = key
            model.payload = payload
            model.modifiedAt = plan.modifiedAt
        } else {
            modelContext.insert(
                AnchorSchemaV1.DayPlanModel(id: plan.id, dayKey: key, payload: payload, modifiedAt: plan.modifiedAt)
            )
        }
        try save()
    }

    public func delete(id: UUID) async throws {
        try modelContext.delete(model: AnchorSchemaV1.DayPlanModel.self, where: #Predicate { $0.id == id })
        try save()
    }
}

// MARK: - TemplateRepository

extension SwiftDataStore: TemplateRepository {
    public func all() async throws -> [DayTemplate] {
        let descriptor = FetchDescriptor<AnchorSchemaV1.DayTemplateModel>(sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(descriptor).map { try PayloadCoder.decode(DayTemplate.self, from: $0.payload) }
    }

    public func upsert(_ template: DayTemplate) async throws {
        let templateID = template.id
        let payload = try PayloadCoder.encode(template)
        let existing = FetchDescriptor<AnchorSchemaV1.DayTemplateModel>(predicate: #Predicate { $0.id == templateID })
        if let model = try modelContext.fetch(existing).first {
            model.name = template.name
            model.payload = payload
            model.modifiedAt = template.modifiedAt
        } else {
            modelContext.insert(
                AnchorSchemaV1.DayTemplateModel(id: template.id, name: template.name, payload: payload, modifiedAt: template.modifiedAt)
            )
        }
        try save()
    }

    public func delete(id: UUID) async throws {
        try modelContext.delete(model: AnchorSchemaV1.DayTemplateModel.self, where: #Predicate { $0.id == id })
        try save()
    }
}

// MARK: - GoalRepository

extension SwiftDataStore: GoalRepository {
    public func all(includeArchived: Bool) async throws -> [Goal] {
        let descriptor = FetchDescriptor<AnchorSchemaV1.GoalModel>(
            predicate: includeArchived ? nil : #Predicate { $0.isArchived == false },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor).map { try PayloadCoder.decode(Goal.self, from: $0.payload) }
    }

    public func upsert(_ goal: Goal) async throws {
        let goalID = goal.id
        let payload = try PayloadCoder.encode(goal)
        let existing = FetchDescriptor<AnchorSchemaV1.GoalModel>(predicate: #Predicate { $0.id == goalID })
        if let model = try modelContext.fetch(existing).first {
            model.isArchived = goal.isArchived
            model.payload = payload
            model.modifiedAt = goal.modifiedAt
        } else {
            modelContext.insert(
                AnchorSchemaV1.GoalModel(
                    id: goal.id,
                    isArchived: goal.isArchived,
                    createdAt: goal.createdAt,
                    payload: payload,
                    modifiedAt: goal.modifiedAt
                )
            )
        }
        try save()
    }

    public func delete(id: UUID) async throws {
        try modelContext.delete(model: AnchorSchemaV1.GoalModel.self, where: #Predicate { $0.id == id })
        try save()
    }
}

// MARK: - ReflectionRepository

extension SwiftDataStore: ReflectionRepository {
    public func checkIns(in range: ClosedRange<DayDate>) async throws -> [MoodCheckIn] {
        let lower = range.lowerBound.numericKey
        let upper = range.upperBound.numericKey
        let descriptor = FetchDescriptor<AnchorSchemaV1.MoodCheckInModel>(
            predicate: #Predicate { $0.dayKey >= lower && $0.dayKey <= upper },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        return try modelContext.fetch(descriptor).map { try PayloadCoder.decode(MoodCheckIn.self, from: $0.payload) }
    }

    public func allCheckIns() async throws -> [MoodCheckIn] {
        let descriptor = FetchDescriptor<AnchorSchemaV1.MoodCheckInModel>(sortBy: [SortDescriptor(\.timestamp)])
        return try modelContext.fetch(descriptor).map { try PayloadCoder.decode(MoodCheckIn.self, from: $0.payload) }
    }

    public func upsert(_ checkIn: MoodCheckIn) async throws {
        let checkInID = checkIn.id
        let payload = try PayloadCoder.encode(checkIn)
        let existing = FetchDescriptor<AnchorSchemaV1.MoodCheckInModel>(predicate: #Predicate { $0.id == checkInID })
        if let model = try modelContext.fetch(existing).first {
            model.dayKey = dayKey(for: checkIn.date)
            model.timestamp = checkIn.date
            model.payload = payload
            model.modifiedAt = checkIn.modifiedAt
        } else {
            modelContext.insert(
                AnchorSchemaV1.MoodCheckInModel(
                    id: checkIn.id,
                    dayKey: dayKey(for: checkIn.date),
                    timestamp: checkIn.date,
                    payload: payload,
                    modifiedAt: checkIn.modifiedAt
                )
            )
        }
        try save()
    }

    public func delete(checkInID: UUID) async throws {
        try modelContext.delete(model: AnchorSchemaV1.MoodCheckInModel.self, where: #Predicate { $0.id == checkInID })
        try save()
    }

    public func journalEntries(in range: ClosedRange<DayDate>) async throws -> [JournalEntry] {
        let lower = range.lowerBound.numericKey
        let upper = range.upperBound.numericKey
        let descriptor = FetchDescriptor<AnchorSchemaV1.JournalEntryModel>(
            predicate: #Predicate { $0.dayKey >= lower && $0.dayKey <= upper },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        return try modelContext.fetch(descriptor).map { try PayloadCoder.decode(JournalEntry.self, from: $0.payload) }
    }

    public func allJournalEntries() async throws -> [JournalEntry] {
        let descriptor = FetchDescriptor<AnchorSchemaV1.JournalEntryModel>(sortBy: [SortDescriptor(\.timestamp)])
        return try modelContext.fetch(descriptor).map { try PayloadCoder.decode(JournalEntry.self, from: $0.payload) }
    }

    public func upsert(_ entry: JournalEntry) async throws {
        let entryID = entry.id
        let payload = try PayloadCoder.encode(entry)
        let existing = FetchDescriptor<AnchorSchemaV1.JournalEntryModel>(predicate: #Predicate { $0.id == entryID })
        if let model = try modelContext.fetch(existing).first {
            model.dayKey = dayKey(for: entry.date)
            model.timestamp = entry.date
            model.payload = payload
            model.modifiedAt = entry.modifiedAt
        } else {
            modelContext.insert(
                AnchorSchemaV1.JournalEntryModel(
                    id: entry.id,
                    dayKey: dayKey(for: entry.date),
                    timestamp: entry.date,
                    payload: payload,
                    modifiedAt: entry.modifiedAt
                )
            )
        }
        try save()
    }

    public func delete(journalID: UUID) async throws {
        try modelContext.delete(model: AnchorSchemaV1.JournalEntryModel.self, where: #Predicate { $0.id == journalID })
        try save()
    }
}

// MARK: - EnergyRepository

extension SwiftDataStore: EnergyRepository {
    public func checkIn(for day: DayDate) async throws -> EnergyCheckIn? {
        let key = day.numericKey
        var descriptor = FetchDescriptor<AnchorSchemaV1.EnergyCheckInModel>(predicate: #Predicate { $0.dayKey == key })
        descriptor.fetchLimit = 1
        guard let model = try modelContext.fetch(descriptor).first else { return nil }
        return try PayloadCoder.decode(EnergyCheckIn.self, from: model.payload)
    }

    public func all() async throws -> [EnergyCheckIn] {
        let descriptor = FetchDescriptor<AnchorSchemaV1.EnergyCheckInModel>(sortBy: [SortDescriptor(\.dayKey)])
        return try modelContext.fetch(descriptor).map { try PayloadCoder.decode(EnergyCheckIn.self, from: $0.payload) }
    }

    public func upsert(_ checkIn: EnergyCheckIn) async throws {
        let key = checkIn.day.numericKey
        let checkInID = checkIn.id
        let clashing = FetchDescriptor<AnchorSchemaV1.EnergyCheckInModel>(
            predicate: #Predicate { $0.dayKey == key && $0.id != checkInID }
        )
        for stale in try modelContext.fetch(clashing) {
            modelContext.delete(stale)
        }
        let payload = try PayloadCoder.encode(checkIn)
        let existing = FetchDescriptor<AnchorSchemaV1.EnergyCheckInModel>(predicate: #Predicate { $0.id == checkInID })
        if let model = try modelContext.fetch(existing).first {
            model.dayKey = key
            model.payload = payload
            model.modifiedAt = checkIn.modifiedAt
        } else {
            modelContext.insert(
                AnchorSchemaV1.EnergyCheckInModel(id: checkIn.id, dayKey: key, payload: payload, modifiedAt: checkIn.modifiedAt)
            )
        }
        try save()
    }
}

// MARK: - WinRepository

extension SwiftDataStore: WinRepository {
    public func events(in range: ClosedRange<DayDate>) async throws -> [WinEvent] {
        let lower = range.lowerBound.numericKey
        let upper = range.upperBound.numericKey
        let descriptor = FetchDescriptor<AnchorSchemaV1.WinEventModel>(
            predicate: #Predicate { $0.dayKey >= lower && $0.dayKey <= upper },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        return try modelContext.fetch(descriptor).map { try PayloadCoder.decode(WinEvent.self, from: $0.payload) }
    }

    public func allEvents() async throws -> [WinEvent] {
        let descriptor = FetchDescriptor<AnchorSchemaV1.WinEventModel>(sortBy: [SortDescriptor(\.timestamp)])
        return try modelContext.fetch(descriptor).map { try PayloadCoder.decode(WinEvent.self, from: $0.payload) }
    }

    public func append(_ event: WinEvent) async throws {
        let payload = try PayloadCoder.encode(event)
        modelContext.insert(
            AnchorSchemaV1.WinEventModel(
                id: event.id,
                dayKey: dayKey(for: event.date),
                timestamp: event.date,
                payload: payload
            )
        )
        try save()
    }
}

// MARK: - CopingRepository

extension SwiftDataStore: CopingRepository {
    public func all() async throws -> [CopingStrategy] {
        let descriptor = FetchDescriptor<AnchorSchemaV1.CopingStrategyModel>(sortBy: [SortDescriptor(\.orderIndex)])
        return try modelContext.fetch(descriptor).map { try PayloadCoder.decode(CopingStrategy.self, from: $0.payload) }
    }

    public func upsert(_ strategy: CopingStrategy) async throws {
        let strategyID = strategy.id
        let payload = try PayloadCoder.encode(strategy)
        let existing = FetchDescriptor<AnchorSchemaV1.CopingStrategyModel>(predicate: #Predicate { $0.id == strategyID })
        if let model = try modelContext.fetch(existing).first {
            model.orderIndex = strategy.orderIndex
            model.payload = payload
            model.modifiedAt = strategy.modifiedAt
        } else {
            modelContext.insert(
                AnchorSchemaV1.CopingStrategyModel(id: strategy.id, orderIndex: strategy.orderIndex, payload: payload, modifiedAt: strategy.modifiedAt)
            )
        }
        try save()
    }

    public func delete(id: UUID) async throws {
        try modelContext.delete(model: AnchorSchemaV1.CopingStrategyModel.self, where: #Predicate { $0.id == id })
        try save()
    }
}

// MARK: - PreferencesRepository

extension SwiftDataStore: PreferencesRepository {
    public func load() async throws -> UserPreferences {
        let descriptor = FetchDescriptor<AnchorSchemaV1.UserPreferencesModel>()
        guard let model = try modelContext.fetch(descriptor).first else { return UserPreferences() }
        return try PayloadCoder.decode(UserPreferences.self, from: model.payload)
    }

    public func save(_ preferences: UserPreferences) async throws {
        let prefsID = preferences.id
        let payload = try PayloadCoder.encode(preferences)
        let existing = FetchDescriptor<AnchorSchemaV1.UserPreferencesModel>(predicate: #Predicate { $0.id == prefsID })
        if let model = try modelContext.fetch(existing).first {
            model.payload = payload
            model.modifiedAt = preferences.modifiedAt
        } else {
            modelContext.insert(
                AnchorSchemaV1.UserPreferencesModel(id: preferences.id, payload: payload, modifiedAt: preferences.modifiedAt)
            )
        }
        try save()
    }
}

// MARK: - DataWiping

extension SwiftDataStore: DataWiping {
    public func wipeAll() async throws {
        try modelContext.delete(model: AnchorSchemaV1.DayPlanModel.self)
        try modelContext.delete(model: AnchorSchemaV1.DayTemplateModel.self)
        try modelContext.delete(model: AnchorSchemaV1.GoalModel.self)
        try modelContext.delete(model: AnchorSchemaV1.MoodCheckInModel.self)
        try modelContext.delete(model: AnchorSchemaV1.JournalEntryModel.self)
        try modelContext.delete(model: AnchorSchemaV1.EnergyCheckInModel.self)
        try modelContext.delete(model: AnchorSchemaV1.WinEventModel.self)
        try modelContext.delete(model: AnchorSchemaV1.CopingStrategyModel.self)
        try modelContext.delete(model: AnchorSchemaV1.UserPreferencesModel.self)
        try save()
    }
}
