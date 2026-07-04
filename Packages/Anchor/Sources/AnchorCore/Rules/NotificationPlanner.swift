import Foundation

/// A notification the platform layer may schedule. Pure value: the planner
/// decides what and when; AnchorPlatform decides how.
public struct PlannedNotification: Sendable, Hashable {
    public let id: String
    public let fireDate: Date
    public let title: String
    public let body: String

    public init(id: String, fireDate: Date, title: String, body: String) {
        self.id = id
        self.fireDate = fireDate
        self.title = title
        self.body = body
    }
}

/// Computes every notification the app may send. All opt-in, all calm,
/// all silenced by quiet hours, sequence mode and Low-Demand Mode.
public enum NotificationPlanner {
    /// Default surfacing window for if–then triggers, minutes.
    public static let defaultIfThenWindowMinutes = 60

    /// The gentle wrap-up notice for a timed block, or nil when warnings
    /// are hidden (sequence mode, Low-Demand), the lead does not fit, or
    /// the fire time lands in quiet hours.
    public static func transitionWarning(
        for block: TimeBlock,
        in plan: DayPlan,
        preferences: UserPreferences,
        calendar: Calendar
    ) -> PlannedNotification? {
        nil
    }

    /// Upcoming reflection reminders for every enabled cadence within the
    /// horizon, shifted out of quiet hours to the quiet end.
    public static func reflectionReminders(
        preferences: UserPreferences,
        from instant: Date,
        calendar: Calendar,
        horizonDays: Int
    ) -> [PlannedNotification] {
        []
    }

    /// The same notification, later. Identity is preserved so the pending
    /// request is replaced rather than duplicated.
    public static func snoozed(_ notification: PlannedNotification, byMinutes minutes: Int) -> PlannedNotification {
        notification
    }
}
