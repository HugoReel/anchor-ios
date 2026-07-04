import Foundation

/// Pure scheduling math over a day plan. Everything takes an explicit
/// instant and calendar; nothing here reads the real clock.
public enum ScheduleMath {
    /// The block happening now: containment by time in clock mode, first
    /// unfinished block in sequence mode. Done blocks are never current.
    public static func currentBlock(in plan: DayPlan, at instant: Date, calendar: Calendar) -> TimeBlock? {
        switch plan.mode {
        case .sequence:
            return plan.sortedBlocks.first { $0.state == .notStarted }
        case .clock:
            return plan.sortedBlocks.first { block in
                guard block.state == .notStarted,
                      let start = block.startTime,
                      let end = block.scheduledEnd else { return false }
                return instant >= start && instant < end
            }
        }
    }

    /// The upcoming block: next not-started timed block after `instant` in
    /// clock mode, the unfinished block after the current one in sequence mode.
    public static func nextBlock(in plan: DayPlan, at instant: Date, calendar: Calendar) -> TimeBlock? {
        switch plan.mode {
        case .sequence:
            let unfinished = plan.sortedBlocks.filter { $0.state == .notStarted }
            return unfinished.dropFirst().first
        case .clock:
            return plan.sortedBlocks.first { block in
                guard block.state == .notStarted, let start = block.startTime else { return false }
                return start > instant
            }
        }
    }

    /// 0…1 position within a timed block; nil in sequence mode or for
    /// untimed blocks. Durations are absolute time, so progress stays
    /// steady across DST transitions.
    public static func progress(of block: TimeBlock, in plan: DayPlan, at instant: Date, calendar: Calendar) -> Double? {
        guard plan.mode == .clock,
              let start = block.startTime,
              let end = block.scheduledEnd,
              end > start else { return nil }
        let total = end.timeIntervalSince(start)
        let elapsed = instant.timeIntervalSince(start)
        return min(max(elapsed / total, 0), 1)
    }

    /// Share of blocks done, 0…1. Count-based on purpose: long blocks are
    /// not worth more than short ones.
    public static func dayProgress(of plan: DayPlan, at instant: Date, calendar: Calendar) -> Double {
        guard !plan.blocks.isEmpty else { return 0 }
        let done = plan.blocks.filter { $0.state == .done }.count
        return Double(done) / Double(plan.blocks.count)
    }

    /// When the gentle wrap-up notice for a block should appear: lead
    /// minutes before its scheduled end. Nil in sequence mode, for untimed
    /// blocks, or when the lead does not fit inside the block.
    public static func transitionWarningDate(for block: TimeBlock, in plan: DayPlan, leadMinutes: Int, calendar: Calendar) -> Date? {
        guard plan.mode == .clock,
              let start = block.startTime,
              let end = block.scheduledEnd else { return nil }
        let fireDate = end.addingTimeInterval(-Double(leadMinutes) * 60)
        guard fireDate > start else { return nil }
        return fireDate
    }
}
