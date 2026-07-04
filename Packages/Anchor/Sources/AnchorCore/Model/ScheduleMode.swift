/// How a day is organised. Both modes hold the same data; switching is
/// lossless in both directions.
public enum ScheduleMode: String, CaseIterable, Codable, Sendable {
    /// Timed blocks with start times and durations.
    case clock
    /// Ordered, untimed blocks — move on when you're ready.
    case sequence

    public var displayName: String {
        switch self {
        case .clock: "Clock"
        case .sequence: "Sequence"
        }
    }
}
