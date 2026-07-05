import Foundation

/// The system boundary for local notifications. Defined in Core so feature
/// view models can depend on it; the real `UNUserNotificationCenter` adapter
/// lives in AnchorPlatform and a recording double lives here for tests and
/// previews. Scheduling replaces any pending request sharing an id.
public protocol NotificationScheduling: Sendable {
    /// Asks the system for permission. Returns whether it was granted.
    func requestAuthorization() async throws -> Bool
    /// Schedules (or reschedules, by id) the given notifications.
    func schedule(_ notifications: [PlannedNotification]) async throws
    /// Cancels every pending notification this app scheduled.
    func cancelAll() async
    /// The ids of every pending notification.
    func pending() async -> [String]
}

/// An in-memory `NotificationScheduling` that records what it was asked to do.
/// Used by tests and previews; mirrors the real adapter's replace-by-id rule.
public actor RecordingNotificationScheduler: NotificationScheduling {
    public private(set) var authorizationRequested = false
    public private(set) var scheduled: [PlannedNotification] = []
    public private(set) var cancelledAllCount = 0
    private let granted: Bool

    public init(granted: Bool = true) {
        self.granted = granted
    }

    public func requestAuthorization() async throws -> Bool {
        authorizationRequested = true
        return granted
    }

    public func schedule(_ notifications: [PlannedNotification]) async throws {
        for notification in notifications {
            scheduled.removeAll { $0.id == notification.id }
            scheduled.append(notification)
        }
    }

    public func cancelAll() async {
        cancelledAllCount += 1
        scheduled.removeAll()
    }

    public func pending() async -> [String] {
        scheduled.map(\.id)
    }
}
