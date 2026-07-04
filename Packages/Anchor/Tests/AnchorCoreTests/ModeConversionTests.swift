import Foundation
import Testing
@testable import AnchorCore

private let newYork = TestSupport.newYork

@Test func convertToSequenceRetainsDormantTimes() {
    let morning = TestSupport.block("Morning focus", startHour: 9, minutes: 50, order: 3)
    let lunch = TestSupport.block("Lunch", category: .care, startHour: 12, minutes: 45, order: 0)
    let plan = TestSupport.plan(blocks: [morning, lunch])

    let converted = ModeConversion.convert(plan, to: .sequence, wakeStartMinutes: nil, calendar: newYork)

    #expect(converted.mode == .sequence)
    #expect(converted.block(withID: morning.id)?.startTime == TestSupport.time(9))
    #expect(converted.block(withID: morning.id)?.durationMinutes == 50)
    // Sequence order is derived from clock order, not the stale indices.
    #expect(converted.sortedBlocks.map(\.title) == ["Morning focus", "Lunch"])
}

private func fingerprint(_ plan: DayPlan) -> [[String]] {
    plan.sortedBlocks.map { block in
        [block.title, String(describing: block.startTime), String(describing: block.durationMinutes)]
    }
}

@Test func convertRoundTripLossless() {
    let morning = TestSupport.block("Morning focus", startHour: 9, minutes: 50, order: 0)
    let lunch = TestSupport.block("Lunch", category: .care, startHour: 12, minutes: 45, order: 1)
    let plan = TestSupport.plan(blocks: [morning, lunch])

    let sequence = ModeConversion.convert(plan, to: .sequence, wakeStartMinutes: nil, calendar: newYork)
    let restored = ModeConversion.convert(sequence, to: .clock, wakeStartMinutes: nil, calendar: newYork)

    #expect(restored.mode == .clock)
    #expect(fingerprint(plan) == fingerprint(restored))
}

@Test func convertToSameModeIsNoOp() {
    let morning = TestSupport.block("Morning focus", startHour: 9, minutes: 50, order: 0)
    let plan = TestSupport.plan(blocks: [morning])

    let converted = ModeConversion.convert(plan, to: .clock, wakeStartMinutes: nil, calendar: newYork)

    #expect(converted.mode == .clock)
    #expect(converted.block(withID: morning.id)?.startTime == TestSupport.time(9))
}

@Test func convertToClockFromWakeWindowLaysOutSequentially() {
    let stretch = TestSupport.block("Stretch", category: .care, minutes: 30, order: 0)
    let breakfast = TestSupport.block("Breakfast", category: .home, order: 1)
    let walk = TestSupport.block("Walk", category: .out, minutes: 45, order: 2)
    let plan = TestSupport.plan(mode: .sequence, blocks: [stretch, breakfast, walk])

    let converted = ModeConversion.convert(plan, to: .clock, wakeStartMinutes: 8 * 60, calendar: newYork)

    #expect(converted.mode == .clock)
    #expect(converted.block(withID: stretch.id)?.startTime == TestSupport.time(8))
    // Blocks without a duration get the 30-minute default slot.
    #expect(converted.block(withID: breakfast.id)?.startTime == TestSupport.time(8, 30))
    #expect(converted.block(withID: breakfast.id)?.durationMinutes == 30)
    #expect(converted.block(withID: walk.id)?.startTime == TestSupport.time(9))
}

@Test func convertToClockPlacesUntimedAfterTimed() {
    let timed = TestSupport.block("Morning focus", startHour: 9, minutes: 60, order: 0)
    let floating = TestSupport.block("Sometime today", category: .home, minutes: 30, order: 1)
    let plan = TestSupport.plan(mode: .sequence, blocks: [timed, floating])

    let converted = ModeConversion.convert(plan, to: .clock, wakeStartMinutes: 8 * 60, calendar: newYork)

    #expect(converted.block(withID: timed.id)?.startTime == TestSupport.time(9))
    #expect(converted.block(withID: floating.id)?.startTime == TestSupport.time(10))
}
