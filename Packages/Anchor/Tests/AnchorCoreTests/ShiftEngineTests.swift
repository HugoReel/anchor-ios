import Foundation
import Testing
@testable import AnchorCore

private let newYork = TestSupport.newYork

@Test func shiftMovesOnlyNotStartedBlocks() {
    let finished = TestSupport.block("Morning focus", startHour: 9, minutes: 50, order: 0, state: .done)
    let errand = TestSupport.block("Errand", category: .out, startHour: 10, minutes: 60, order: 1)
    let lunch = TestSupport.block("Lunch", category: .care, startHour: 11, startMinute: 15, minutes: 45, order: 2)
    let plan = TestSupport.plan(blocks: [finished, errand, lunch])

    // Running 20 minutes late at 10:20.
    let shifted = ShiftEngine.shiftRemainder(of: plan, from: TestSupport.time(10, 20), calendar: newYork)

    #expect(shifted.block(withID: finished.id)?.startTime == TestSupport.time(9))
    #expect(shifted.block(withID: errand.id)?.startTime == TestSupport.time(10, 20))
    #expect(shifted.block(withID: lunch.id)?.startTime == TestSupport.time(11, 35))
}

@Test func shiftPreservesDurationsAndGaps() {
    let errand = TestSupport.block("Errand", category: .out, startHour: 10, minutes: 60, order: 0)
    let lunch = TestSupport.block("Lunch", category: .care, startHour: 11, startMinute: 15, minutes: 45, order: 1)
    let plan = TestSupport.plan(blocks: [errand, lunch])

    let shifted = ShiftEngine.shiftRemainder(of: plan, from: TestSupport.time(10, 20), calendar: newYork)

    let movedErrand = shifted.block(withID: errand.id)
    let movedLunch = shifted.block(withID: lunch.id)
    #expect(movedErrand?.durationMinutes == 60)
    #expect(movedLunch?.durationMinutes == 45)
    if let errandEnd = movedErrand?.scheduledEnd, let lunchStart = movedLunch?.startTime {
        // The original 15-minute gap between errand end and lunch start survives.
        #expect(lunchStart.timeIntervalSince(errandEnd) == 15 * 60)
    } else {
        Issue.record("shifted blocks should keep their times")
    }
}

@Test func shiftNoOpWhenNothingRemains() {
    let finished = TestSupport.block("Morning focus", startHour: 9, minutes: 50, order: 0, state: .done)
    let plan = TestSupport.plan(blocks: [finished])

    let shifted = ShiftEngine.shiftRemainder(of: plan, from: TestSupport.time(10, 20), calendar: newYork)

    #expect(shifted.block(withID: finished.id)?.startTime == TestSupport.time(9))
}

@Test func shiftNoOpWhenAheadOfSchedule() {
    let errand = TestSupport.block("Errand", category: .out, startHour: 10, minutes: 60, order: 0)
    let plan = TestSupport.plan(blocks: [errand])

    let shifted = ShiftEngine.shiftRemainder(of: plan, from: TestSupport.time(9, 40), calendar: newYork)

    #expect(shifted.block(withID: errand.id)?.startTime == TestSupport.time(10))
}

@Test func shiftLeavesUntimedBlocksAlone() {
    let errand = TestSupport.block("Errand", category: .out, startHour: 10, minutes: 60, order: 0)
    let floating = TestSupport.block("Sometime today", category: .home, order: 1)
    let plan = TestSupport.plan(blocks: [errand, floating])

    let shifted = ShiftEngine.shiftRemainder(of: plan, from: TestSupport.time(10, 20), calendar: newYork)

    #expect(shifted.block(withID: errand.id)?.startTime == TestSupport.time(10, 20))
    #expect(shifted.block(withID: floating.id)?.startTime == nil)
}
