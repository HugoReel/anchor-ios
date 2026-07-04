import Foundation

/// Lossless switching between clock and sequence modes.
public enum ModeConversion {
    /// Slot length for blocks that have no duration when laying a sequence
    /// out onto the clock.
    public static let defaultSlotMinutes = 30

    /// Fallback wake-window start (minutes from midnight) when none is set.
    public static let defaultWakeStartMinutes = 9 * 60

    /// Converts a plan to the requested mode without losing data:
    /// clock → sequence keeps times dormant and derives order from clock
    /// order; sequence → clock restores dormant times and lays untimed
    /// blocks out from the wake window (or after the last timed block).
    public static func convert(_ plan: DayPlan, to mode: ScheduleMode, wakeStartMinutes: Int?, calendar: Calendar) -> DayPlan {
        guard plan.mode != mode else { return plan }
        var updated = plan
        updated.mode = mode

        switch mode {
        case .sequence:
            let ordered = plan.sortedBlocks
            var indexByID: [UUID: Int] = [:]
            for (index, block) in ordered.enumerated() {
                indexByID[block.id] = index
            }
            updated.blocks = plan.blocks.map { block in
                var reordered = block
                reordered.orderIndex = indexByID[block.id] ?? block.orderIndex
                return reordered
            }

        case .clock:
            let ordered = plan.sortedBlocks
            var cursor: Date
            if let lastTimedEnd = ordered.compactMap(\.scheduledEnd).max() {
                cursor = lastTimedEnd
            } else {
                let wake = wakeStartMinutes ?? defaultWakeStartMinutes
                cursor = plan.date.startDate(calendar: calendar).addingTimeInterval(Double(wake) * 60)
            }
            updated.blocks = ordered.map { block in
                guard block.startTime == nil else { return block }
                var placed = block
                let minutes = block.durationMinutes ?? defaultSlotMinutes
                placed.startTime = cursor
                placed.durationMinutes = minutes
                cursor = cursor.addingTimeInterval(Double(minutes) * 60)
                return placed
            }
        }
        return updated
    }
}
