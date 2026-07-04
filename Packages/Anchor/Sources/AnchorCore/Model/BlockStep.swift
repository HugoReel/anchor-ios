import Foundation

/// One checkable step inside a time block.
public struct BlockStep: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public var title: String
    public var isDone: Bool
    public var orderIndex: Int
    public let createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        isDone: Bool = false,
        orderIndex: Int,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.orderIndex = orderIndex
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
