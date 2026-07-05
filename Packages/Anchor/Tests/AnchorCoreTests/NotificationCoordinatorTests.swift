import Foundation
import Testing
@testable import AnchorCore

private enum NotifFixture {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    static let day = DayDate(year: 2025, month: 6, day: 2)

    static func at(_ hour: Int, _ minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = day.year
        components.month = day.month
        components.day = day.day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }

    static func block(startHour: Int) -> TimeBlock {
        TimeBlock(title: "Focus", category: .focus, startTime: at(startHour), durationMinutes: 60, orderIndex: 0)
    }

    static func plan(startHour: Int) -> DayPlan {
        DayPlan(date: day, mode: .clock, blocks: [block(startHour: startHour)])
    }

    static func coordinator(
        scheduler: RecordingNotificationScheduler,
        prefs: InMemoryPreferencesRepository
    ) -> NotificationCoordinator {
        NotificationCoordinator(
            scheduler: scheduler,
            preferences: prefs,
            dateProvider: FixedDateProvider(now: at(6), calendar: calendar)
        )
    }
}

@Test func schedulingOnlyAfterAuthorization() async {
    let scheduler = RecordingNotificationScheduler(granted: true)
    let prefs = InMemoryPreferencesRepository()
    let coordinator = NotifFixture.coordinator(scheduler: scheduler, prefs: prefs)
    let plan = NotifFixture.plan(startHour: 9)

    // Not yet authorized: refreshing schedules nothing.
    await coordinator.refreshTransitionWarnings(for: plan)
    var scheduled = await scheduler.scheduled
    #expect(scheduled.isEmpty)

    // After enabling and being granted, warnings schedule.
    await coordinator.enableReminders()
    await coordinator.refreshTransitionWarnings(for: plan)
    scheduled = await scheduler.scheduled
    #expect(scheduled.count == 1)
}

@Test func permanentOffCancelsEverything() async throws {
    let scheduler = RecordingNotificationScheduler(granted: true)
    let prefs = InMemoryPreferencesRepository()
    let coordinator = NotifFixture.coordinator(scheduler: scheduler, prefs: prefs)

    await coordinator.enableReminders()
    await coordinator.refreshTransitionWarnings(for: NotifFixture.plan(startHour: 9))
    var scheduled = await scheduler.scheduled
    #expect(!scheduled.isEmpty)

    await coordinator.disableReminders()
    scheduled = await scheduler.scheduled
    #expect(scheduled.isEmpty)
    let cancels = await scheduler.cancelledAllCount
    #expect(cancels == 1)
    let saved = try await prefs.load()
    #expect(saved.notificationsEnabled == false)
}

@Test func planChangeReschedulesWarnings() async {
    let scheduler = RecordingNotificationScheduler(granted: true)
    let prefs = InMemoryPreferencesRepository()
    let coordinator = NotifFixture.coordinator(scheduler: scheduler, prefs: prefs)
    await coordinator.enableReminders()

    let original = NotifFixture.block(startHour: 9)
    let planV1 = DayPlan(date: NotifFixture.day, mode: .clock, blocks: [original])
    var shifted = original
    shifted.startTime = NotifFixture.at(11)
    let planV2 = DayPlan(date: NotifFixture.day, mode: .clock, blocks: [shifted])

    await coordinator.refreshTransitionWarnings(for: planV1)
    let firstPending = await scheduler.pending()
    await coordinator.refreshTransitionWarnings(for: planV2)
    let secondPending = await scheduler.pending()

    #expect(firstPending == secondPending)
    let scheduled = await scheduler.scheduled
    #expect(scheduled.count == 1)
    #expect(scheduled.first?.fireDate == NotifFixture.at(11, 45))
}

@Test func noSchedulingWhileLowDemand() async throws {
    let scheduler = RecordingNotificationScheduler(granted: true)
    let prefs = InMemoryPreferencesRepository()
    var stored = UserPreferences()
    stored.notificationsEnabled = true
    stored.lowDemandMode = true
    try await prefs.save(stored)
    let coordinator = NotifFixture.coordinator(scheduler: scheduler, prefs: prefs)

    await coordinator.refreshTransitionWarnings(for: NotifFixture.plan(startHour: 9))
    let scheduled = await scheduler.scheduled
    #expect(scheduled.isEmpty)
}
