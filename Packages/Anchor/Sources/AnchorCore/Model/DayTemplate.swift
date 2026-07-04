import Foundation

/// A reusable day shape: apply it to any date to create that day's blocks.
public struct DayTemplate: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public var name: String
    public var mode: ScheduleMode
    public var blocks: [TemplateBlock]
    public let createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        mode: ScheduleMode = .clock,
        blocks: [TemplateBlock] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.mode = mode
        self.blocks = blocks
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

/// One block within a template. Times are stored as minutes from midnight
/// so a template applies cleanly to any date in any time zone.
public struct TemplateBlock: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public var title: String
    public var category: BlockCategory
    public var startMinutes: Int?
    public var durationMinutes: Int?
    public var orderIndex: Int
    public var isFlexible: Bool
    public var stepTitles: [String]

    public init(
        id: UUID = UUID(),
        title: String,
        category: BlockCategory,
        startMinutes: Int? = nil,
        durationMinutes: Int? = nil,
        orderIndex: Int,
        isFlexible: Bool = false,
        stepTitles: [String] = []
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.startMinutes = startMinutes
        self.durationMinutes = durationMinutes
        self.orderIndex = orderIndex
        self.isFlexible = isFlexible
        self.stepTitles = stepTitles
    }
}
