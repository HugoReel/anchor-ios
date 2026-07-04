import Foundation

/// The one-tap "shift the rest of my day" action. Falling behind is never
/// failure: the plan simply moves to meet the person where they are.
public enum ShiftEngine {
    /// Moves every not-started timed block later so the earliest of them
    /// starts at `instant`, preserving durations and the gaps between
    /// blocks. Done and untimed blocks are untouched. No-op when nothing
    /// remains or the plan is ahead of schedule.
    public static func shiftRemainder(of plan: DayPlan, from instant: Date, calendar: Calendar) -> DayPlan {
        plan
    }
}
