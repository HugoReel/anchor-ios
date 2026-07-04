import Foundation
import SwiftData

/// Migration plan, starting at v1. It exists from day one — with a real
/// round-trip test — so future model changes have a home and never strand
/// user data. New versions append a `VersionedSchema` and a stage here.
public enum AnchorMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [AnchorSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}
