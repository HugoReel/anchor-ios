import Foundation

/// Pure scheduling math over a day plan. Everything takes an explicit
/// instant and calendar; nothing here reads the real clock.
public enum ScheduleMath {
    /// The block happening now: containment by time in clock mode, first
    /// unfinished block in sequence mode. Done blocks are never current.
    public static func currentBlock(in plan: DayPlan, at instant: Date, calendar: Calendar) -> TimeBlock? {
        nil
    }

    /// The upcoming block: next not-started timed block after `instant` in
    /// clock mode, the unfinished block after the current one in sequence mode.
    public static func nextBlock(in plan: DayPlan, at instant: Date, calendar: Calendar) -> TimeBlock? {
        nil
    }

    /// 0…1 position within a timed block; nil in sequence mode or for
    /// untimed blocks.
    public static func progress(of block: TimeBlock, in plan: DayPlan, at instant: Date, calendar: Calendar) -> Double? {
        nil
    }

    /// Share of blocks done, 0…1. Count-based on purpose: long blocks are
    /// not worth more than short ones.
    public static func dayProgress(of plan: DayPlan, at instant: Date, calendar: Calendar) -> Double {
        0
    }

    /// When the gentle wrap-up notice for a block should appear: lead
    /// minutes before its scheduled end. Nil in sequence mode, for untimed
    /// blocks, or when the lead does not fit inside the block.
    public static func transitionWarningDate(for block: TimeBlock, in plan: DayPlan, leadMinutes: Int, calendar: Calendar) -> Date? {
        nil
    }
}
