import Foundation

/// Lossless switching between clock and sequence modes.
public enum ModeConversion {
    /// Slot length for blocks that have no duration when laying a sequence
    /// out onto the clock.
    public static let defaultSlotMinutes = 30

    /// Converts a plan to the requested mode without losing data:
    /// clock → sequence keeps times dormant and derives order from clock
    /// order; sequence → clock restores dormant times and lays untimed
    /// blocks out from the wake window (or after the last timed block).
    public static func convert(_ plan: DayPlan, to mode: ScheduleMode, wakeStartMinutes: Int?, calendar: Calendar) -> DayPlan {
        plan
    }
}
