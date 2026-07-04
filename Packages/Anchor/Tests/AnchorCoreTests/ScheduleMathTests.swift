import Foundation
import Testing
@testable import AnchorCore

private let newYork = TestSupport.newYork

@Test func currentBlockInsideTimedBlock() {
    let morning = TestSupport.block("Morning focus", startHour: 9, minutes: 50, order: 0)
    let lunch = TestSupport.block("Lunch", category: .care, startHour: 12, minutes: 45, order: 1)
    let plan = TestSupport.plan(blocks: [morning, lunch])

    let found = ScheduleMath.currentBlock(in: plan, at: TestSupport.time(9, 30), calendar: newYork)

    #expect(found?.id == morning.id)
}

@Test func currentBlockNilInGap() {
    let morning = TestSupport.block("Morning focus", startHour: 9, minutes: 50, order: 0)
    let lunch = TestSupport.block("Lunch", category: .care, startHour: 12, minutes: 45, order: 1)
    let plan = TestSupport.plan(blocks: [morning, lunch])

    #expect(ScheduleMath.currentBlock(in: plan, at: TestSupport.time(11), calendar: newYork) == nil)
}

@Test func currentBlockIgnoresDoneBlocks() {
    let finished = TestSupport.block("Morning focus", startHour: 9, minutes: 50, order: 0, state: .done)
    let plan = TestSupport.plan(blocks: [finished])

    #expect(ScheduleMath.currentBlock(in: plan, at: TestSupport.time(9, 30), calendar: newYork) == nil)
}

@Test func currentBlockSequenceModeIsFirstUnfinished() {
    let wake = TestSupport.block("Wake", order: 0, state: .done)
    let stretch = TestSupport.block("Stretch", category: .care, order: 1)
    let breakfast = TestSupport.block("Breakfast", category: .home, order: 2)
    let plan = TestSupport.plan(mode: .sequence, blocks: [wake, stretch, breakfast])

    let found = ScheduleMath.currentBlock(in: plan, at: TestSupport.time(9), calendar: newYork)

    #expect(found?.id == stretch.id)
}

@Test func nextBlockSkipsDoneBlocks() {
    let morning = TestSupport.block("Morning focus", startHour: 9, minutes: 50, order: 0)
    let errand = TestSupport.block("Errand", category: .out, startHour: 10, minutes: 30, order: 1, state: .done)
    let lunch = TestSupport.block("Lunch", category: .care, startHour: 12, minutes: 45, order: 2)
    let plan = TestSupport.plan(blocks: [morning, errand, lunch])

    let next = ScheduleMath.nextBlock(in: plan, at: TestSupport.time(9, 30), calendar: newYork)

    #expect(next?.id == lunch.id)
}

@Test func nextBlockAcrossGap() {
    let morning = TestSupport.block("Morning focus", startHour: 9, minutes: 50, order: 0)
    let lunch = TestSupport.block("Lunch", category: .care, startHour: 12, minutes: 45, order: 1)
    let plan = TestSupport.plan(blocks: [morning, lunch])

    let next = ScheduleMath.nextBlock(in: plan, at: TestSupport.time(10, 30), calendar: newYork)

    #expect(next?.id == lunch.id)
}

@Test func nextBlockSequenceIsSecondUnfinished() {
    let wake = TestSupport.block("Wake", order: 0, state: .done)
    let stretch = TestSupport.block("Stretch", category: .care, order: 1)
    let breakfast = TestSupport.block("Breakfast", category: .home, order: 2)
    let plan = TestSupport.plan(mode: .sequence, blocks: [wake, stretch, breakfast])

    let next = ScheduleMath.nextBlock(in: plan, at: TestSupport.time(9), calendar: newYork)

    #expect(next?.id == breakfast.id)
}

@Test func progressHalfwayIsPointFive() {
    let morning = TestSupport.block("Morning focus", startHour: 9, minutes: 50, order: 0)
    let plan = TestSupport.plan(blocks: [morning])

    let progress = ScheduleMath.progress(of: morning, in: plan, at: TestSupport.time(9, 25), calendar: newYork)

    #expect(progress != nil)
    if let progress {
        #expect(abs(progress - 0.5) < 0.001)
    }
}

@Test func progressNilForSequenceMode() {
    let stretch = TestSupport.block("Stretch", order: 0)
    let plan = TestSupport.plan(mode: .sequence, blocks: [stretch])

    #expect(ScheduleMath.progress(of: stretch, in: plan, at: TestSupport.time(9), calendar: newYork) == nil)
}

@Test func dayProgressCountsDoneOverTotal() {
    let blocks = [
        TestSupport.block("One", startHour: 8, minutes: 30, order: 0, state: .done),
        TestSupport.block("Two", startHour: 9, minutes: 30, order: 1, state: .done),
        TestSupport.block("Three", startHour: 10, minutes: 30, order: 2),
        TestSupport.block("Four", startHour: 11, minutes: 30, order: 3)
    ]
    let plan = TestSupport.plan(blocks: blocks)

    let progress = ScheduleMath.dayProgress(of: plan, at: TestSupport.time(10, 15), calendar: newYork)

    #expect(abs(progress - 0.5) < 0.001)
}

@Test func dayProgressZeroForEmptyPlan() {
    let plan = TestSupport.plan(blocks: [])
    #expect(ScheduleMath.dayProgress(of: plan, at: TestSupport.time(10), calendar: newYork) == 0)
}

@Test func transitionWarningLeadRespected() {
    let morning = TestSupport.block("Morning focus", startHour: 9, minutes: 50, order: 0)
    let plan = TestSupport.plan(blocks: [morning])

    let fireDate = ScheduleMath.transitionWarningDate(for: morning, in: plan, leadMinutes: 15, calendar: newYork)

    #expect(fireDate == TestSupport.time(9, 35))
}

@Test func transitionWarningNilWhenLeadExceedsBlock() {
    let quick = TestSupport.block("Quick tidy", category: .home, startHour: 9, minutes: 10, order: 0)
    let plan = TestSupport.plan(blocks: [quick])

    #expect(ScheduleMath.transitionWarningDate(for: quick, in: plan, leadMinutes: 15, calendar: newYork) == nil)
}

@Test func springForwardDayKeepsProgressMonotonic() {
    // 2025-03-09 in New York: 02:00 EST jumps to 03:00 EDT, so the day is
    // 23 hours long. A 90-minute block starting 01:30 runs to wall clock
    // 04:00; durations are absolute time.
    let dstDay = DayDate(year: 2025, month: 3, day: 9)
    let earlyBlock = TestSupport.block("Night routine", category: .care, startHour: 1, startMinute: 30, minutes: 90, order: 0, day: dstDay)
    let plan = TestSupport.plan(blocks: [earlyBlock], day: dstDay)

    let midway = ScheduleMath.progress(of: earlyBlock, in: plan, at: TestSupport.time(3, 15, day: dstDay), calendar: newYork)
    let later = ScheduleMath.progress(of: earlyBlock, in: plan, at: TestSupport.time(3, 30, day: dstDay), calendar: newYork)

    #expect(midway != nil)
    #expect(later != nil)
    if let midway, let later {
        #expect(abs(midway - 0.5) < 0.001)
        #expect(later > midway)
    }
}

@Test func fallBackDayHandlesRepeatedHour() {
    // 2025-11-02 in New York: 02:00 EDT falls back to 01:00 EST, so wall
    // clock 01:30 happens twice. Durations stay absolute.
    let dstDay = DayDate(year: 2025, month: 11, day: 2)
    let nightBlock = TestSupport.block("Night routine", category: .care, startHour: 0, startMinute: 30, minutes: 120, order: 0, day: dstDay)
    let plan = TestSupport.plan(blocks: [nightBlock], day: dstDay)

    if let start = nightBlock.startTime, let end = nightBlock.scheduledEnd {
        #expect(end.timeIntervalSince(start) == 7200)
        let progress = ScheduleMath.progress(of: nightBlock, in: plan, at: start.addingTimeInterval(3600), calendar: newYork)
        #expect(progress != nil)
        if let progress {
            #expect(abs(progress - 0.5) < 0.001)
        }
    } else {
        Issue.record("fixture block should have start and end")
    }
}

@Test func midnightBoundaryBlockBelongsToItsDay() {
    let lateBlock = TestSupport.block("Wind down", category: .rest, startHour: 23, startMinute: 30, minutes: 60, order: 0)
    let plan = TestSupport.plan(blocks: [lateBlock])
    let justAfterMidnight = TestSupport.time(0, 15, day: TestSupport.baseDay.advanced(by: 1, calendar: newYork))

    let found = ScheduleMath.currentBlock(in: plan, at: justAfterMidnight, calendar: newYork)

    #expect(found?.id == lateBlock.id)
}
