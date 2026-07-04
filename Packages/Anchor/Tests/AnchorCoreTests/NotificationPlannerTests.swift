import Foundation
import Testing
@testable import AnchorCore

private let newYork = TestSupport.newYork

@Test func transitionWarningUsesLeadMinutes() {
    let morning = TestSupport.block("Morning focus", startHour: 9, minutes: 50, order: 0)
    let plan = TestSupport.plan(blocks: [morning])

    let warning = NotificationPlanner.transitionWarning(
        for: morning,
        in: plan,
        preferences: UserPreferences(),
        calendar: newYork
    )

    #expect(warning?.fireDate == TestSupport.time(9, 35))
    #expect(warning?.id == "transition-\(morning.id.uuidString)")
    #expect(warning?.body.contains("15") == true)
}

@Test func transitionWarningNamesNextBlock() {
    let morning = TestSupport.block("Morning focus", startHour: 9, minutes: 50, order: 0)
    let lunch = TestSupport.block("Lunch", category: .care, startHour: 12, minutes: 45, order: 1)
    let plan = TestSupport.plan(blocks: [morning, lunch])

    let warning = NotificationPlanner.transitionWarning(
        for: morning,
        in: plan,
        preferences: UserPreferences(),
        calendar: newYork
    )

    #expect(warning?.body.contains("Lunch") == true)
}

@Test func transitionWarningNilInSequenceMode() {
    let morning = TestSupport.block("Morning focus", startHour: 9, minutes: 50, order: 0)
    let plan = TestSupport.plan(mode: .sequence, blocks: [morning])

    let warning = NotificationPlanner.transitionWarning(
        for: morning,
        in: plan,
        preferences: UserPreferences(),
        calendar: newYork
    )

    #expect(warning == nil)
}

@Test func transitionWarningNilInLowDemand() {
    let morning = TestSupport.block("Morning focus", startHour: 9, minutes: 50, order: 0)
    let plan = TestSupport.plan(blocks: [morning])
    var preferences = UserPreferences()
    preferences.lowDemandMode = true

    let warning = NotificationPlanner.transitionWarning(for: morning, in: plan, preferences: preferences, calendar: newYork)

    #expect(warning == nil)
}

@Test func transitionWarningSuppressedInQuietHours() {
    var preferences = UserPreferences()
    preferences.quietStartMinutes = 21 * 60
    preferences.quietEndMinutes = 8 * 60

    // Daytime warning fires normally.
    let morning = TestSupport.block("Morning focus", startHour: 9, minutes: 50, order: 0)
    let dayPlan = TestSupport.plan(blocks: [morning])
    let dayWarning = NotificationPlanner.transitionWarning(for: morning, in: dayPlan, preferences: preferences, calendar: newYork)
    #expect(dayWarning != nil)

    // A warning that would land at 22:45 stays silent.
    let evening = TestSupport.block("Wind down", category: .rest, startHour: 22, startMinute: 10, minutes: 50, order: 0)
    let eveningPlan = TestSupport.plan(blocks: [evening])
    let eveningWarning = NotificationPlanner.transitionWarning(for: evening, in: eveningPlan, preferences: preferences, calendar: newYork)
    #expect(eveningWarning == nil)
}

@Test func reflectionRemindersRespectCadenceAndTime() {
    var preferences = UserPreferences()
    preferences.remindDaily = true
    preferences.remindDailyTimeMinutes = 20 * 60

    let reminders = NotificationPlanner.reflectionReminders(
        preferences: preferences,
        from: TestSupport.time(10),
        calendar: newYork,
        horizonDays: 3
    )

    #expect(reminders.count == 3)
    #expect(reminders.first?.fireDate == TestSupport.time(20))
    #expect(reminders.first?.id == "reflect-daily-2025-06-02")
}

@Test func reflectionSkipsPastTimeToday() {
    var preferences = UserPreferences()
    preferences.remindDaily = true
    preferences.remindDailyTimeMinutes = 9 * 60

    let reminders = NotificationPlanner.reflectionReminders(
        preferences: preferences,
        from: TestSupport.time(10),
        calendar: newYork,
        horizonDays: 2
    )

    #expect(reminders.count == 1)
    #expect(reminders.first?.fireDate == TestSupport.time(9, day: TestSupport.baseDay.advanced(by: 1, calendar: newYork)))
}

@Test func weeklyRemindersLandOnCalendarWeekStart() {
    var preferences = UserPreferences()
    preferences.remindWeekly = true
    preferences.remindWeeklyTimeMinutes = 18 * 60

    let reminders = NotificationPlanner.reflectionReminders(
        preferences: preferences,
        from: TestSupport.time(10),
        calendar: newYork,
        horizonDays: 14
    )

    // Gregorian first weekday is Sunday: 2025-06-08 and 2025-06-15.
    #expect(reminders.count == 2)
    #expect(reminders.first?.fireDate == TestSupport.time(18, day: DayDate(year: 2025, month: 6, day: 8)))
}

@Test func reflectionRemindersShiftOutOfQuietHours() {
    var preferences = UserPreferences()
    preferences.remindDaily = true
    preferences.remindDailyTimeMinutes = 22 * 60
    preferences.quietStartMinutes = 21 * 60
    preferences.quietEndMinutes = 8 * 60

    let reminders = NotificationPlanner.reflectionReminders(
        preferences: preferences,
        from: TestSupport.time(10),
        calendar: newYork,
        horizonDays: 1
    )

    #expect(reminders.count == 1)
    #expect(reminders.first?.fireDate == TestSupport.time(8, day: TestSupport.baseDay.advanced(by: 1, calendar: newYork)))
}

@Test func remindersEmptyWhenAllTogglesOff() {
    let reminders = NotificationPlanner.reflectionReminders(
        preferences: UserPreferences(),
        from: TestSupport.time(10),
        calendar: newYork,
        horizonDays: 7
    )

    #expect(reminders.isEmpty)
}

@Test func snoozeAddsExactMinutes() {
    let original = PlannedNotification(
        id: "reflect-daily-2025-06-02",
        fireDate: TestSupport.time(20),
        title: "A moment for you",
        body: "If you feel like it, a moment to reflect is here."
    )

    let snoozed = NotificationPlanner.snoozed(original, byMinutes: 10)

    #expect(snoozed.fireDate == original.fireDate.addingTimeInterval(600))
    #expect(snoozed.id == original.id)
    #expect(snoozed.title == original.title)
    #expect(snoozed.body == original.body)
}
