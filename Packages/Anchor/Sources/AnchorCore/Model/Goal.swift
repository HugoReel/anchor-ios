import Foundation

/// A long-term goal broken into small checkable steps. Progress only ever
/// accrues; there are no streaks, decay or shame states, and a target date
/// is context, never a countdown.
public struct Goal: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public var title: String
    public var note: String?
    public var targetDate: DayDate?
    public var isArchived: Bool
    public var steps: [GoalStep]
    public let createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        note: String? = nil,
        targetDate: DayDate? = nil,
        isArchived: Bool = false,
        steps: [GoalStep] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.targetDate = targetDate
        self.isArchived = isArchived
        self.steps = steps
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    /// 0…1 share of steps done. Empty goals sit at zero without judgement.
    public var progress: Double {
        guard !steps.isEmpty else { return 0 }
        let done = steps.filter(\.isDone).count
        return Double(done) / Double(steps.count)
    }
}
