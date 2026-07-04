import Foundation

/// One block of the day. In clock mode `startTime` and `durationMinutes`
/// drive layout; in sequence mode `orderIndex` does, while any stored times
/// stay dormant so mode switching loses nothing.
public struct TimeBlock: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public var title: String
    public var category: BlockCategory
    public var startTime: Date?
    public var durationMinutes: Int?
    public var orderIndex: Int
    public var isFlexible: Bool
    public var notes: String?
    public var steps: [BlockStep]
    public var state: BlockState
    public var completedAt: Date?
    public let createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        category: BlockCategory,
        startTime: Date? = nil,
        durationMinutes: Int? = nil,
        orderIndex: Int,
        isFlexible: Bool = false,
        notes: String? = nil,
        steps: [BlockStep] = [],
        state: BlockState = .notStarted,
        completedAt: Date? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.orderIndex = orderIndex
        self.isFlexible = isFlexible
        self.notes = notes
        self.steps = steps
        self.state = state
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    /// Scheduled end, when both start and duration exist. Durations are
    /// absolute time (a 50-minute block is 50 minutes long across a DST
    /// change), so this is plain interval arithmetic on purpose.
    public var scheduledEnd: Date? {
        guard let startTime, let durationMinutes else { return nil }
        return startTime.addingTimeInterval(Double(durationMinutes) * 60)
    }

    public var isRest: Bool {
        category.isRest
    }
}
