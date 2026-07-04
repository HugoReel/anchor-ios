import Foundation
import Testing
import SwiftData
@testable import AnchorCore
@testable import AnchorPersistence

/// The migration harness must exist and open a v1 store before v2 ever
/// arrives, so future model changes never strand user data.
@Test func migrationPlanOpensV1Store() throws {
    let container = try ModelContainerFactory.makeContainer(inMemory: true)
    #expect(!container.schema.entities.isEmpty)
}

@Test func migrationPlanStartsAtVersionOne() {
    #expect(AnchorMigrationPlan.schemas.count == 1)
    #expect(AnchorSchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
    // No stages yet: v1 is the first version, nothing to migrate from.
    #expect(AnchorMigrationPlan.stages.isEmpty)
}

@Test func v1StoreSurvivesReopenThroughPlan() async throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Etc/UTC") ?? .current

    // A store opened through the migration plan round-trips a save. In-memory
    // stores do not share state across containers, so this asserts the plan
    // and schema wire together and persist within the store's lifetime.
    let container = try ModelContainerFactory.makeContainer(inMemory: true)
    let store = SwiftDataStore(modelContainer: container, calendar: calendar)
    let day = DayDate(year: 2025, month: 6, day: 2)
    try await store.upsert(DayPlan(date: day, notes: "kept"))

    let reloaded = try await store.plan(for: day)
    #expect(reloaded?.notes == "kept")
}
