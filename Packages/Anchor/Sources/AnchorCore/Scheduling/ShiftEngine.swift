import Foundation

/// The one-tap "shift the rest of my day" action. Falling behind is never
/// failure: the plan simply moves to meet the person where they are.
public enum ShiftEngine {
    /// Moves every not-started timed block later so the earliest of them
    /// starts at `instant`, preserving durations and the gaps between
    /// blocks. Done and untimed blocks are untouched. No-op when nothing
    /// remains or the plan is ahead of schedule.
    public static func shiftRemainder(of plan: DayPlan, from instant: Date, calendar: Calendar) -> DayPlan {
        let pendingStarts = plan.blocks
            .filter { $0.state == .notStarted }
            .compactMap(\.startTime)
        guard let anchorStart = pendingStarts.min() else { return plan }

        let delta = instant.timeIntervalSince(anchorStart)
        guard delta > 0 else { return plan }

        var updated = plan
        updated.blocks = plan.blocks.map { block in
            guard block.state == .notStarted, let start = block.startTime else { return block }
            var moved = block
            moved.startTime = start.addingTimeInterval(delta)
            moved.modifiedAt = instant
            return moved
        }
        updated.modifiedAt = instant
        return updated
    }
}
