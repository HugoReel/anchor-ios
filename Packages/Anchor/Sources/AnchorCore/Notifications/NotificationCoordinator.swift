import Foundation

/// Orchestrates local notifications: it turns the planner's pure output into
/// scheduling calls, but only ever after the user has opted in and the system
/// has granted authorization. Nothing is scheduled in Low-Demand Mode, and
/// turning reminders off cancels everything.
public struct NotificationCoordinator: Sendable {
    private let scheduler: any NotificationScheduling
    private let preferences: any PreferencesRepository
    private let dateProvider: any DateProviding

    public init(
        scheduler: any NotificationScheduling,
        preferences: any PreferencesRepository,
        dateProvider: any DateProviding
    ) {
        self.scheduler = scheduler
        self.preferences = preferences
        self.dateProvider = dateProvider
    }

    /// Asks the system for permission, persists the outcome, and — if granted —
    /// schedules the reflection reminders currently configured. Returns whether
    /// authorization was granted.
    @discardableResult
    public func enableReminders(horizonDays: Int = 30) async -> Bool {
        do {
            let granted = try await scheduler.requestAuthorization()
            var prefs = try await preferences.load()
            prefs.notificationsEnabled = granted
            prefs.modifiedAt = dateProvider.now
            try await preferences.save(prefs)
            guard granted else { return false }
            let reminders = NotificationPlanner.reflectionReminders(
                preferences: prefs,
                from: dateProvider.now,
                calendar: dateProvider.calendar,
                horizonDays: horizonDays
            )
            try await scheduler.schedule(reminders)
            return true
        } catch {
            return false
        }
    }

    /// Turns reminders off for good: persists the choice and cancels every
    /// pending notification.
    public func disableReminders() async {
        do {
            var prefs = try await preferences.load()
            prefs.notificationsEnabled = false
            prefs.modifiedAt = dateProvider.now
            try await preferences.save(prefs)
        } catch {
            // Even if persistence fails, still cancel what is pending.
        }
        await scheduler.cancelAll()
    }

    /// Reschedules the transition warnings for a plan (replace-by-id keeps
    /// them from duplicating). A no-op when reminders are off or the day is in
    /// Low-Demand Mode.
    public func refreshTransitionWarnings(for plan: DayPlan) async {
        do {
            let prefs = try await preferences.load()
            guard prefs.notificationsEnabled == true, !prefs.lowDemandMode else { return }
            let calendar = dateProvider.calendar
            let warnings = plan.blocks.compactMap {
                NotificationPlanner.transitionWarning(for: $0, in: plan, preferences: prefs, calendar: calendar)
            }
            guard !warnings.isEmpty else { return }
            try await scheduler.schedule(warnings)
        } catch {
            // Best-effort; a scheduling failure leaves prior warnings in place.
        }
    }
}
