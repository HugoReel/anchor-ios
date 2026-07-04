import Foundation

/// A suggested breathing space after a block. Suggestions are offers the
/// user applies; nothing is inserted automatically.
public struct BufferSuggestion: Sendable, Hashable {
    public let afterBlockID: UUID
    public let minutes: Int

    public init(afterBlockID: UUID, minutes: Int) {
        self.afterBlockID = afterBlockID
        self.minutes = minutes
    }
}

public enum BufferAdvisor {
    public static let longBlockMinutes = 60
    public static let bufferMinutes = 10

    /// Applies a suggestion by moving every later timed, not-started block
    /// back by the buffer length, opening a breathing space after the named
    /// block. Done and untimed blocks stay put.
    public static func applying(_ suggestion: BufferSuggestion, to plan: DayPlan, at instant: Date) -> DayPlan {
        guard let anchor = plan.block(withID: suggestion.afterBlockID),
              let anchorEnd = anchor.scheduledEnd else { return plan }
        var updated = plan
        updated.blocks = plan.blocks.map { block in
            guard block.id != anchor.id,
                  block.state == .notStarted,
                  let start = block.startTime,
                  start >= anchorEnd else { return block }
            var moved = block
            moved.startTime = start.addingTimeInterval(Double(suggestion.minutes) * 60)
            moved.modifiedAt = instant
            return moved
        }
        updated.modifiedAt = instant
        return updated
    }

    /// Suggests a buffer between adjacent long timed blocks in clock mode.
    public static func suggestions(for plan: DayPlan, calendar: Calendar) -> [BufferSuggestion] {
        guard plan.mode == .clock else { return [] }
        let timed = plan.sortedBlocks.filter { $0.startTime != nil && $0.scheduledEnd != nil }
        var result: [BufferSuggestion] = []
        for (first, second) in zip(timed, timed.dropFirst()) {
            guard let firstMinutes = first.durationMinutes,
                  let secondMinutes = second.durationMinutes,
                  firstMinutes >= longBlockMinutes,
                  secondMinutes >= longBlockMinutes,
                  let firstEnd = first.scheduledEnd,
                  let secondStart = second.startTime,
                  secondStart.timeIntervalSince(firstEnd) < 60 else { continue }
            result.append(BufferSuggestion(afterBlockID: first.id, minutes: bufferMinutes))
        }
        return result
    }
}
