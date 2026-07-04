import Foundation
import Testing
@testable import AnchorCore

private let newYork = TestSupport.newYork

@Test func ifThenSurfacesWithinWindow() {
    let soon = IfThenPlan(triggerKind: .time, triggerMinutes: 14 * 60 + 30)
    let later = IfThenPlan(triggerKind: .time, triggerMinutes: 16 * 60)

    let surfaced = IfThenScheduler.surfacing(
        plans: [soon, later],
        at: TestSupport.time(14),
        calendar: newYork,
        windowMinutes: 60
    )

    #expect(surfaced.map(\.id) == [soon.id])
}

@Test func ifThenIgnoresInactive() {
    let active = IfThenPlan(triggerKind: .time, triggerMinutes: 14 * 60 + 30)
    let inactive = IfThenPlan(triggerKind: .time, triggerMinutes: 14 * 60 + 30, isActive: false)

    let surfaced = IfThenScheduler.surfacing(
        plans: [active, inactive],
        at: TestSupport.time(14),
        calendar: newYork,
        windowMinutes: 60
    )

    #expect(surfaced.map(\.id) == [active.id])
}

@Test func ifThenSituationTriggersExcludedFromTimeSurfacing() {
    let situational = IfThenPlan(triggerKind: .situation, situationText: "If I feel overwhelmed")
    let timed = IfThenPlan(triggerKind: .time, triggerMinutes: 14 * 60 + 30)

    let surfaced = IfThenScheduler.surfacing(
        plans: [situational, timed],
        at: TestSupport.time(14),
        calendar: newYork,
        windowMinutes: 60
    )

    #expect(surfaced.map(\.id) == [timed.id])
}

@Test func ifThenExcludesPastTriggers() {
    let past = IfThenPlan(triggerKind: .time, triggerMinutes: 13 * 60)
    let upcoming = IfThenPlan(triggerKind: .time, triggerMinutes: 14 * 60 + 15)

    let surfaced = IfThenScheduler.surfacing(
        plans: [past, upcoming],
        at: TestSupport.time(14),
        calendar: newYork,
        windowMinutes: 60
    )

    #expect(surfaced.map(\.id) == [upcoming.id])
}
