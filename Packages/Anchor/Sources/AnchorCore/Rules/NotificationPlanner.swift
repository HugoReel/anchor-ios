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

    private enum Cadence: String, CaseIterable {
        case daily
        case weekly
        case monthly
        case yearly

        func isEnabled(_ preferences: UserPreferences) -> Bool {
            switch self {
            case .daily: preferences.remindDaily
            case .weekly: preferences.remindWeekly
            case .monthly: preferences.remindMonthly
            case .yearly: preferences.remindYearly
            }
        }

        func timeMinutes(_ preferences: UserPreferences) -> Int? {
            switch self {
            case .daily: preferences.remindDailyTimeMinutes
            case .weekly: preferences.remindWeeklyTimeMinutes
            case .monthly: preferences.remindMonthlyTimeMinutes
            case .yearly: preferences.remindYearlyTimeMinutes
            }
        }

        func applies(to day: DayDate, calendar: Calendar) -> Bool {
            switch self {
            case .daily:
                return true
            case .weekly:
                let weekday = calendar.component(.weekday, from: day.startDate(calendar: calendar))
                return weekday == calendar.firstWeekday
            case .monthly:
                return day.day == 1
            case .yearly:
                return day.month == 1 && day.day == 1
            }
        }
    }

    /// The gentle wrap-up notice for a timed block, or nil when warnings
    /// are hidden (sequence mode, Low-Demand), the lead does not fit, or
    /// the fire time lands in quiet hours.
    public static func transitionWarning(
        for block: TimeBlock,
        in plan: DayPlan,
        preferences: UserPreferences,
        calendar: Calendar
    ) -> PlannedNotification? {
        guard !preferences.lowDemandMode else { return nil }
        guard let fireDate = ScheduleMath.transitionWarningDate(
            for: block,
            in: plan,
            leadMinutes: preferences.transitionLeadMinutes,
            calendar: calendar
        ) else { return nil }
        guard !inQuietHours(fireDate, preferences: preferences, calendar: calendar) else { return nil }

        let next = ScheduleMath.nextBlock(in: plan, at: fireDate, calendar: calendar)
        return PlannedNotification(
            id: "transition-\(block.id.uuidString)",
            fireDate: fireDate,
            title: Copy.transitionTitle,
            body: Copy.transitionBody(leadMinutes: preferences.transitionLeadMinutes, nextTitle: next?.title)
        )
    }

    /// Upcoming reflection reminders for every enabled cadence within the
    /// horizon, shifted out of quiet hours to the next quiet end.
    public static func reflectionReminders(
        preferences: UserPreferences,
        from instant: Date,
        calendar: Calendar,
        horizonDays: Int
    ) -> [PlannedNotification] {
        guard horizonDays > 0 else { return [] }
        let startDay = DayDate(date: instant, calendar: calendar)
        var result: [PlannedNotification] = []

        for offset in 0..<horizonDays {
            let day = startDay.advanced(by: offset, calendar: calendar)
            for cadence in Cadence.allCases {
                guard cadence.isEnabled(preferences),
                      let timeMinutes = cadence.timeMinutes(preferences),
                      cadence.applies(to: day, calendar: calendar) else { continue }

                var fireDate = day.startDate(calendar: calendar).addingTimeInterval(Double(timeMinutes) * 60)
                guard fireDate >= instant else { continue }
                if inQuietHours(fireDate, preferences: preferences, calendar: calendar) {
                    fireDate = nextQuietEnd(after: fireDate, preferences: preferences, calendar: calendar)
                }

                let dayStamp = String(format: "%04d-%02d-%02d", day.year, day.month, day.day)
                result.append(
                    PlannedNotification(
                        id: "reflect-\(cadence.rawValue)-\(dayStamp)",
                        fireDate: fireDate,
                        title: Copy.reflectionTitle,
                        body: Copy.reflectionBody
                    )
                )
            }
        }
        return result.sorted { $0.fireDate < $1.fireDate }
    }

    /// The same notification, later. Identity is preserved so the pending
    /// request is replaced rather than duplicated.
    public static func snoozed(_ notification: PlannedNotification, byMinutes minutes: Int) -> PlannedNotification {
        PlannedNotification(
            id: notification.id,
            fireDate: notification.fireDate.addingTimeInterval(Double(minutes) * 60),
            title: notification.title,
            body: notification.body
        )
    }

    // MARK: - Quiet hours

    private static func minutesOfDay(_ date: Date, calendar: Calendar) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private static func inQuietHours(_ date: Date, preferences: UserPreferences, calendar: Calendar) -> Bool {
        guard let start = preferences.quietStartMinutes,
              let end = preferences.quietEndMinutes,
              start != end else { return false }
        let minutes = minutesOfDay(date, calendar: calendar)
        if start < end {
            return minutes >= start && minutes < end
        }
        // Quiet hours wrap midnight, e.g. 21:00 → 08:00.
        return minutes >= start || minutes < end
    }

    private static func nextQuietEnd(after date: Date, preferences: UserPreferences, calendar: Calendar) -> Date {
        guard let end = preferences.quietEndMinutes else { return date }
        let day = DayDate(date: date, calendar: calendar)
        let sameDayEnd = day.startDate(calendar: calendar).addingTimeInterval(Double(end) * 60)
        if sameDayEnd > date {
            return sameDayEnd
        }
        return day.advanced(by: 1, calendar: calendar).startDate(calendar: calendar).addingTimeInterval(Double(end) * 60)
    }
}
