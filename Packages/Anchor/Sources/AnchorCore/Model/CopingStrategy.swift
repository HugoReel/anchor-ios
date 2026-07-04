import Foundation

/// A personal coping strategy in the user-curated bank.
public struct CopingStrategy: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public var title: String
    public var note: String?
    public var category: String?
    public var orderIndex: Int
    public var isSeedExample: Bool
    public let createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        note: String? = nil,
        category: String? = nil,
        orderIndex: Int,
        isSeedExample: Bool = false,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.category = category
        self.orderIndex = orderIndex
        self.isSeedExample = isSeedExample
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
