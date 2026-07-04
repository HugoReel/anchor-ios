import Foundation
import SwiftData
import AnchorCore

/// Versioned schema v1. Each aggregate is a top-level `@Model` carrying the
/// columns we actually query or sort on, plus a `payload` holding the
/// Codable Core value type as its source of truth. Nested value collections
/// (blocks, steps, if–then plans) live inside the payload rather than as
/// SwiftData relationships: mapping stays a single encode/decode, and the
/// blob shape is CloudKit-friendly for the future sync seam. See
/// DECISIONS.md.
public enum AnchorSchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    public static var models: [any PersistentModel.Type] {
        [
            DayPlanModel.self,
            DayTemplateModel.self,
            GoalModel.self,
            MoodCheckInModel.self,
            JournalEntryModel.self,
            EnergyCheckInModel.self,
            WinEventModel.self,
            CopingStrategyModel.self,
            UserPreferencesModel.self
        ]
    }

    @Model
    public final class DayPlanModel {
        @Attribute(.unique) public var id: UUID
        /// `yyyymmdd`, unique per day, used for equality and range queries.
        public var dayKey: Int
        public var payload: Data
        public var modifiedAt: Date

        public init(id: UUID, dayKey: Int, payload: Data, modifiedAt: Date) {
            self.id = id
            self.dayKey = dayKey
            self.payload = payload
            self.modifiedAt = modifiedAt
        }
    }

    @Model
    public final class DayTemplateModel {
        @Attribute(.unique) public var id: UUID
        public var name: String
        public var payload: Data
        public var modifiedAt: Date

        public init(id: UUID, name: String, payload: Data, modifiedAt: Date) {
            self.id = id
            self.name = name
            self.payload = payload
            self.modifiedAt = modifiedAt
        }
    }

    @Model
    public final class GoalModel {
        @Attribute(.unique) public var id: UUID
        public var isArchived: Bool
        public var createdAt: Date
        public var payload: Data
        public var modifiedAt: Date

        public init(id: UUID, isArchived: Bool, createdAt: Date, payload: Data, modifiedAt: Date) {
            self.id = id
            self.isArchived = isArchived
            self.createdAt = createdAt
            self.payload = payload
            self.modifiedAt = modifiedAt
        }
    }

    @Model
    public final class MoodCheckInModel {
        @Attribute(.unique) public var id: UUID
        public var dayKey: Int
        public var timestamp: Date
        public var payload: Data
        public var modifiedAt: Date

        public init(id: UUID, dayKey: Int, timestamp: Date, payload: Data, modifiedAt: Date) {
            self.id = id
            self.dayKey = dayKey
            self.timestamp = timestamp
            self.payload = payload
            self.modifiedAt = modifiedAt
        }
    }

    @Model
    public final class JournalEntryModel {
        @Attribute(.unique) public var id: UUID
        public var dayKey: Int
        public var timestamp: Date
        public var payload: Data
        public var modifiedAt: Date

        public init(id: UUID, dayKey: Int, timestamp: Date, payload: Data, modifiedAt: Date) {
            self.id = id
            self.dayKey = dayKey
            self.timestamp = timestamp
            self.payload = payload
            self.modifiedAt = modifiedAt
        }
    }

    @Model
    public final class EnergyCheckInModel {
        @Attribute(.unique) public var id: UUID
        public var dayKey: Int
        public var payload: Data
        public var modifiedAt: Date

        public init(id: UUID, dayKey: Int, payload: Data, modifiedAt: Date) {
            self.id = id
            self.dayKey = dayKey
            self.payload = payload
            self.modifiedAt = modifiedAt
        }
    }

    @Model
    public final class WinEventModel {
        @Attribute(.unique) public var id: UUID
        public var dayKey: Int
        public var timestamp: Date
        public var payload: Data

        public init(id: UUID, dayKey: Int, timestamp: Date, payload: Data) {
            self.id = id
            self.dayKey = dayKey
            self.timestamp = timestamp
            self.payload = payload
        }
    }

    @Model
    public final class CopingStrategyModel {
        @Attribute(.unique) public var id: UUID
        public var orderIndex: Int
        public var payload: Data
        public var modifiedAt: Date

        public init(id: UUID, orderIndex: Int, payload: Data, modifiedAt: Date) {
            self.id = id
            self.orderIndex = orderIndex
            self.payload = payload
            self.modifiedAt = modifiedAt
        }
    }

    @Model
    public final class UserPreferencesModel {
        @Attribute(.unique) public var id: UUID
        public var payload: Data
        public var modifiedAt: Date

        public init(id: UUID, payload: Data, modifiedAt: Date) {
            self.id = id
            self.payload = payload
            self.modifiedAt = modifiedAt
        }
    }
}
