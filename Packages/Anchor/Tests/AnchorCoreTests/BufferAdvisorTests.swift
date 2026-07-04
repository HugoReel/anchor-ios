import Foundation
import Testing
@testable import AnchorCore

private let newYork = TestSupport.newYork

@Test func bufferSuggestedBetweenLongAdjacentBlocks() {
    let deepWork = TestSupport.block("Deep work", startHour: 9, minutes: 60, order: 0)
    let errands = TestSupport.block("Errands", category: .out, startHour: 10, minutes: 60, order: 1)
    let plan = TestSupport.plan(blocks: [deepWork, errands])

    let suggestions = BufferAdvisor.suggestions(for: plan, calendar: newYork)

    #expect(suggestions.count == 1)
    #expect(suggestions.first?.afterBlockID == deepWork.id)
    #expect(suggestions.first?.minutes == 10)
}

@Test func noBufferWhenGapExists() {
    let deepWork = TestSupport.block("Deep work", startHour: 9, minutes: 60, order: 0)
    let errands = TestSupport.block("Errands", category: .out, startHour: 10, startMinute: 15, minutes: 60, order: 1)
    let plan = TestSupport.plan(blocks: [deepWork, errands])

    #expect(BufferAdvisor.suggestions(for: plan, calendar: newYork).isEmpty)
}

@Test func noBufferForShortBlocks() {
    let tidy = TestSupport.block("Tidy", category: .home, startHour: 9, minutes: 30, order: 0)
    let snack = TestSupport.block("Snack", category: .care, startHour: 9, startMinute: 30, minutes: 30, order: 1)
    let plan = TestSupport.plan(blocks: [tidy, snack])

    #expect(BufferAdvisor.suggestions(for: plan, calendar: newYork).isEmpty)
}

@Test func applyingBufferMovesLaterBlocksOnly() {
    let deepWork = TestSupport.block("Deep work", startHour: 9, minutes: 60, order: 0)
    let errands = TestSupport.block("Errands", category: .out, startHour: 10, minutes: 60, order: 1)
    let evening = TestSupport.block("Call", category: .connect, startHour: 18, minutes: 30, order: 2)
    let plan = TestSupport.plan(blocks: [deepWork, errands, evening])
    let suggestion = BufferSuggestion(afterBlockID: deepWork.id, minutes: 10)

    let updated = BufferAdvisor.applying(suggestion, to: plan, at: TestSupport.time(9, 30))

    #expect(updated.block(withID: deepWork.id)?.startTime == TestSupport.time(9))
    #expect(updated.block(withID: errands.id)?.startTime == TestSupport.time(10, 10))
    #expect(updated.block(withID: evening.id)?.startTime == TestSupport.time(18, 10))
}

@Test func applyingBufferSkipsDoneBlocks() {
    let deepWork = TestSupport.block("Deep work", startHour: 9, minutes: 60, order: 0)
    let finished = TestSupport.block("Errands", category: .out, startHour: 10, minutes: 60, order: 1, state: .done)
    let plan = TestSupport.plan(blocks: [deepWork, finished])
    let suggestion = BufferSuggestion(afterBlockID: deepWork.id, minutes: 10)

    let updated = BufferAdvisor.applying(suggestion, to: plan, at: TestSupport.time(9, 30))

    #expect(updated.block(withID: finished.id)?.startTime == TestSupport.time(10))
}

@Test func noBufferInSequenceMode() {
    let deepWork = TestSupport.block("Deep work", startHour: 9, minutes: 60, order: 0)
    let errands = TestSupport.block("Errands", category: .out, startHour: 10, minutes: 60, order: 1)
    let plan = TestSupport.plan(mode: .sequence, blocks: [deepWork, errands])

    #expect(BufferAdvisor.suggestions(for: plan, calendar: newYork).isEmpty)
}
