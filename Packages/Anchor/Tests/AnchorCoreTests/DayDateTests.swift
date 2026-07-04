import Foundation
import Testing
@testable import AnchorCore

private func calendar(inZone identifier: String) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: identifier) ?? TimeZone(secondsFromGMT: 0) ?? .current
    return calendar
}

// 2025-06-01T23:30:00Z
private let lateEveningUTC = Date(timeIntervalSince1970: 1_748_820_600)

@Test func dayDateFromDateRespectsTimeZone() {
    let newYork = DayDate(date: lateEveningUTC, calendar: calendar(inZone: "America/New_York"))
    #expect(newYork == DayDate(year: 2025, month: 6, day: 1))

    let tokyo = DayDate(date: lateEveningUTC, calendar: calendar(inZone: "Asia/Tokyo"))
    #expect(tokyo == DayDate(year: 2025, month: 6, day: 2))
}

@Test func dayDateOrdering() {
    #expect(DayDate(year: 2025, month: 1, day: 31) < DayDate(year: 2025, month: 2, day: 1))
    #expect(DayDate(year: 2025, month: 2, day: 1) < DayDate(year: 2026, month: 1, day: 1))
    #expect(!(DayDate(year: 2025, month: 3, day: 9) < DayDate(year: 2025, month: 3, day: 9)))
}

@Test func dayDateAdvanceAcrossMonthEnd() {
    let utc = calendar(inZone: "Etc/UTC")
    let advanced = DayDate(year: 2025, month: 1, day: 31).advanced(by: 1, calendar: utc)
    #expect(advanced == DayDate(year: 2025, month: 2, day: 1))
}

@Test func dayDateAdvanceAcrossDSTSpringForward() {
    let newYork = calendar(inZone: "America/New_York")
    // 2025-03-09 is only 23 hours long in New York; day arithmetic must not care.
    let before = DayDate(year: 2025, month: 3, day: 8)
    #expect(before.advanced(by: 1, calendar: newYork) == DayDate(year: 2025, month: 3, day: 9))
    #expect(before.advanced(by: 2, calendar: newYork) == DayDate(year: 2025, month: 3, day: 10))
}

@Test func numericKeyRoundTrips() {
    let day = DayDate(year: 2025, month: 6, day: 2)
    #expect(day.numericKey == 20_250_602)
    #expect(DayDate(numericKey: day.numericKey) == day)
    // Ordering by key matches ordering by day.
    #expect(DayDate(year: 2025, month: 1, day: 31).numericKey < DayDate(year: 2025, month: 2, day: 1).numericKey)
}

@Test func startDateIsMidnightLocal() {
    let utc = calendar(inZone: "Etc/UTC")
    // 2025-06-01T00:00:00Z
    #expect(DayDate(year: 2025, month: 6, day: 1).startDate(calendar: utc) == Date(timeIntervalSince1970: 1_748_736_000))

    let newYork = calendar(inZone: "America/New_York")
    // Midnight EST on 2025-03-09 is 05:00Z (DST has not started yet at midnight).
    #expect(
        DayDate(year: 2025, month: 3, day: 9).startDate(calendar: newYork)
            == Date(timeIntervalSince1970: 1_741_496_400)
    )
}
