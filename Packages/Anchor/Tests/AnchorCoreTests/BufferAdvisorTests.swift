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

@Test func noBufferInSequenceMode() {
    let deepWork = TestSupport.block("Deep work", startHour: 9, minutes: 60, order: 0)
    let errands = TestSupport.block("Errands", category: .out, startHour: 10, minutes: 60, order: 1)
    let plan = TestSupport.plan(mode: .sequence, blocks: [deepWork, errands])

    #expect(BufferAdvisor.suggestions(for: plan, calendar: newYork).isEmpty)
}
