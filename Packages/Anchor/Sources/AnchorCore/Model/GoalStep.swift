import Foundation

/// One small checkable step towards a goal.
public struct GoalStep: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public var title: String
    public var isDone: Bool
    public var completedAt: Date?
    public var orderIndex: Int
    public var ifThenPlans: [IfThenPlan]
    public let createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        isDone: Bool = false,
        completedAt: Date? = nil,
        orderIndex: Int,
        ifThenPlans: [IfThenPlan] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.completedAt = completedAt
        self.orderIndex = orderIndex
        self.ifThenPlans = ifThenPlans
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
