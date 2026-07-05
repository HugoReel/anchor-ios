import Foundation
import UserNotifications
import AnchorCore

/// The real `NotificationScheduling`, backed by `UNUserNotificationCenter`.
/// Sound is deliberately off by default (spec §8); adding a request with an
/// existing identifier replaces the pending one, matching the planner's
/// stable ids for snooze and reschedule.
public struct UserNotificationScheduler: NotificationScheduling {
    private let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    private var center: UNUserNotificationCenter { .current() }

    public func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .badge])
    }

    public func schedule(_ notifications: [PlannedNotification]) async throws {
        for notification in notifications {
            let content = UNMutableNotificationContent()
            content.title = notification.title
            content.body = notification.body
            // No sound: quiet by default.
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: notification.fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: notification.id, content: content, trigger: trigger)
            try await center.add(request)
        }
    }

    public func cancelAll() async {
        center.removeAllPendingNotificationRequests()
    }

    public func pending() async -> [String] {
        await center.pendingNotificationRequests().map(\.identifier)
    }
}
