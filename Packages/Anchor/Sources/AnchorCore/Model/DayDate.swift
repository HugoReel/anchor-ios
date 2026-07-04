import Foundation

/// A calendar day without a time of day. Used as the key for day-scoped
/// data so "which day is this" is decided exactly once, with an explicit
/// calendar, instead of by ad-hoc `Date` truncation.
public struct DayDate: Sendable, Hashable, Codable, Comparable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public init(date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        // Requested components are always present; the fallbacks never fire.
        self.init(year: components.year ?? 0, month: components.month ?? 0, day: components.day ?? 0)
    }

    /// Midnight at the start of this day in the calendar's time zone.
    public func startDate(calendar: Calendar) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        // A valid day always resolves; the fallback never fires.
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }

    public func advanced(by days: Int, calendar: Calendar) -> DayDate {
        let start = startDate(calendar: calendar)
        let moved = calendar.date(byAdding: .day, value: days, to: start) ?? start
        return DayDate(date: moved, calendar: calendar)
    }

    public static func < (lhs: DayDate, rhs: DayDate) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}
