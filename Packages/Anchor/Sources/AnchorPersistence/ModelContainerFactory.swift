import Foundation
import SwiftData
import AnchorCore

/// Builds the app's `ModelContainer` through the versioned schema and
/// migration plan. The store lives in the app's container and rides the
/// user's normal encrypted device/iCloud backup.
public enum ModelContainerFactory {
    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: AnchorSchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: AnchorMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            throw DomainError.storageFailure("could not open the data store")
        }
    }
}
