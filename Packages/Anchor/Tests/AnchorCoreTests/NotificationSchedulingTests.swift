import Foundation
import Testing
@testable import AnchorCore

@Test func recordingSchedulerReportsAuthorizationAndSchedules() async throws {
    let scheduler = RecordingNotificationScheduler(granted: true)

    let granted = try await scheduler.requestAuthorization()
    #expect(granted)
    let requested = await scheduler.authorizationRequested
    #expect(requested)

    let notification = PlannedNotification(
        id: "transition-1",
        fireDate: Date(timeIntervalSince1970: 1_000),
        title: "Gently wrap up soon",
        body: "In about 15 minutes, gently wrap up."
    )
    try await scheduler.schedule([notification])
    let pending = await scheduler.pending()
    #expect(pending == ["transition-1"])
}

@Test func recordingSchedulerReplacesByIDAndCancels() async throws {
    let scheduler = RecordingNotificationScheduler()
    let first = PlannedNotification(id: "x", fireDate: Date(timeIntervalSince1970: 1_000), title: "One", body: "First")
    let second = PlannedNotification(id: "x", fireDate: Date(timeIntervalSince1970: 2_000), title: "Two", body: "Second")

    try await scheduler.schedule([first])
    try await scheduler.schedule([second])
    let scheduled = await scheduler.scheduled
    #expect(scheduled.count == 1)
    #expect(scheduled.first?.title == "Two")

    await scheduler.cancelAll()
    let pending = await scheduler.pending()
    #expect(pending.isEmpty)
    let cancels = await scheduler.cancelledAllCount
    #expect(cancels == 1)
}

@Test func recordingSchedulerHonoursDeniedAuthorization() async throws {
    let scheduler = RecordingNotificationScheduler(granted: false)
    let granted = try await scheduler.requestAuthorization()
    #expect(granted == false)
}
