import Foundation

/// Something that just happened and might mint a gentle win.
public enum WinEventTrigger: Sendable {
    case blockDone(TimeBlock)
    case stepDone(BlockStep)
    case goalStepDone(GoalStep)
    case checkIn
    case journal
}

/// An additive counter shown on Today. Counters only ever grow; zero-count
/// summaries are omitted rather than shown as zero.
public struct WinsSummary: Sendable, Hashable {
    public enum SummaryKind: String, Sendable {
        case checkInsThisMonth
        case showedUpThisWeek
        case blocksDoneThisWeek
        case restThisWeek
    }

    public let kind: SummaryKind
    public let label: String
    public let count: Int

    public init(kind: SummaryKind, label: String, count: Int) {
        self.kind = kind
        self.label = label
        self.count = count
    }
}

/// The streak replacement. Wins accrue; they never reset, decay or judge.
public enum WinsEngine {
    /// Mints a win for a trigger, or nil while wins are paused. Hiding wins
    /// is a display preference and does not stop minting.
    public static func mintedWin(for trigger: WinEventTrigger, preferences: UserPreferences, at instant: Date) -> WinEvent? {
        nil
    }

    /// Additive summaries for the reference day's week and month. Days
    /// without events are simply not mentioned.
    public static func summaries(events: [WinEvent], reference: DayDate, calendar: Calendar) -> [WinsSummary] {
        []
    }
}
