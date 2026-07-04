import Foundation

/// Injected everywhere time is read so scheduling logic is testable across
/// midnight boundaries, DST changes and time zones. Production code never
/// calls `Date()` or `Calendar.current` directly outside an implementation
/// of this protocol.
public protocol DateProviding: Sendable {
    var now: Date { get }
    var calendar: Calendar { get }
}

/// Deterministic provider for tests and previews.
public struct FixedDateProvider: DateProviding {
    public var now: Date
    public var calendar: Calendar

    public init(now: Date, calendar: Calendar) {
        self.now = now
        self.calendar = calendar
    }
}
