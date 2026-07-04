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

    /// Suggests a buffer between adjacent long timed blocks in clock mode.
    public static func suggestions(for plan: DayPlan, calendar: Calendar) -> [BufferSuggestion] {
        []
    }
}
