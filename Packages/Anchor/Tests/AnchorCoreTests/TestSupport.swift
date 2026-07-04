import Foundation
@testable import AnchorCore

/// Shared fixtures. Base day is Monday 2025-06-02 in America/New_York;
/// DST cases use 2025-03-09 (spring forward) and 2025-11-02 (fall back).
enum TestSupport {
    static func calendar(zone: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone) ?? TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    static let newYork = calendar(zone: "America/New_York")
    static let utc = calendar(zone: "Etc/UTC")
    static let baseDay = DayDate(year: 2025, month: 6, day: 2)

    static func time(
        _ hour: Int,
        _ minute: Int = 0,
        day: DayDate = baseDay,
        calendar: Calendar = TestSupport.newYork
    ) -> Date {
        var components = DateComponents()
        components.year = day.year
        components.month = day.month
        components.day = day.day
        components.hour = hour
        components.minute = minute
        // Valid fixture times always resolve; the fallback never fires.
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }

    static func block(
        _ title: String,
        category: BlockCategory = .focus,
        startHour: Int? = nil,
        startMinute: Int = 0,
        minutes: Int? = nil,
        order: Int,
        flexible: Bool = false,
        state: BlockState = .notStarted,
        day: DayDate = baseDay,
        calendar: Calendar = TestSupport.newYork
    ) -> TimeBlock {
        TimeBlock(
            title: title,
            category: category,
            startTime: startHour.map { time($0, startMinute, day: day, calendar: calendar) },
            durationMinutes: minutes,
            orderIndex: order,
            isFlexible: flexible,
            state: state
        )
    }

    static func plan(
        mode: ScheduleMode = .clock,
        blocks: [TimeBlock],
        day: DayDate = baseDay
    ) -> DayPlan {
        DayPlan(date: day, mode: mode, blocks: blocks)
    }
}
