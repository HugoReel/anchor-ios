import Foundation

/// One day's plan: a mode and its blocks. One plan per `DayDate`.
public struct DayPlan: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public var date: DayDate
    public var mode: ScheduleMode
    public var blocks: [TimeBlock]
    public var notes: String?
    public let createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        date: DayDate,
        mode: ScheduleMode = .clock,
        blocks: [TimeBlock] = [],
        notes: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.mode = mode
        self.blocks = blocks
        self.notes = notes
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    /// Blocks in presentation order: start time in clock mode (order index
    /// breaking ties and placing untimed blocks last), order index in
    /// sequence mode.
    public var sortedBlocks: [TimeBlock] {
        switch mode {
        case .sequence:
            return blocks.sorted { $0.orderIndex < $1.orderIndex }
        case .clock:
            return blocks.sorted { lhs, rhs in
                switch (lhs.startTime, rhs.startTime) {
                case let (left?, right?):
                    if left != right { return left < right }
                    return lhs.orderIndex < rhs.orderIndex
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return lhs.orderIndex < rhs.orderIndex
                }
            }
        }
    }

    public func block(withID blockID: UUID) -> TimeBlock? {
        blocks.first { $0.id == blockID }
    }
}
