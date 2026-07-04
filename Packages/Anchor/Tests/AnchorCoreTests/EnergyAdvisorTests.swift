import Foundation
import Testing
@testable import AnchorCore

@Test func lowEnergyProducesAtMostThreeSuggestions() {
    let blocks = [
        TestSupport.block("Deep work", startHour: 9, minutes: 90, order: 0, flexible: true),
        TestSupport.block("Emails", startHour: 11, minutes: 30, order: 1, flexible: true),
        TestSupport.block("Cleaning", category: .home, startHour: 13, minutes: 45, order: 2, flexible: true),
        TestSupport.block("Call", category: .connect, startHour: 15, minutes: 30, order: 3, flexible: true),
        TestSupport.block("Shopping", category: .out, startHour: 16, minutes: 60, order: 4, flexible: true)
    ]
    let plan = TestSupport.plan(blocks: blocks)

    let suggestions = EnergyAdvisor.suggestions(for: plan, energyLevel: 1)

    #expect(!suggestions.isEmpty)
    #expect(suggestions.count <= 3)
}

@Test func suggestionsNeverTargetRestBlocks() {
    let rest = TestSupport.block("Quiet time", category: .rest, startHour: 14, minutes: 60, order: 0)
    let chores = TestSupport.block("Chores", category: .home, startHour: 9, minutes: 60, order: 1, flexible: true)
    let plan = TestSupport.plan(blocks: [rest, chores])

    let suggestions = EnergyAdvisor.suggestions(for: plan, energyLevel: 2)

    #expect(!suggestions.isEmpty)
    #expect(!suggestions.contains { $0.blockID == rest.id })
}

@Test func energyAboveTwoProducesNone() {
    let chores = TestSupport.block("Chores", category: .home, startHour: 9, minutes: 60, order: 0, flexible: true)
    let plan = TestSupport.plan(blocks: [chores])

    #expect(EnergyAdvisor.suggestions(for: plan, energyLevel: 3).isEmpty)
}

@Test func postponeSuggestsFlexibleBlocksFirst() {
    let fixed = TestSupport.block("Appointment", category: .out, startHour: 9, minutes: 60, order: 0)
    let flexible = TestSupport.block("Laundry", category: .home, startHour: 11, minutes: 30, order: 1, flexible: true)
    let plan = TestSupport.plan(blocks: [fixed, flexible])

    let suggestions = EnergyAdvisor.suggestions(for: plan, energyLevel: 1)

    #expect(suggestions.first?.blockID == flexible.id)
    #expect(suggestions.first?.action == .postpone)
}

@Test func suggestionsSkipDoneBlocks() {
    let finished = TestSupport.block("Done already", startHour: 8, minutes: 30, order: 0, flexible: true, state: .done)
    let pending = TestSupport.block("Laundry", category: .home, startHour: 11, minutes: 30, order: 1, flexible: true)
    let plan = TestSupport.plan(blocks: [finished, pending])

    let suggestions = EnergyAdvisor.suggestions(for: plan, energyLevel: 1)

    #expect(!suggestions.isEmpty)
    #expect(!suggestions.contains { $0.blockID == finished.id })
}

@Test func suggestionReasonsAreInvitational() {
    let flexible = TestSupport.block("Laundry", category: .home, startHour: 11, minutes: 30, order: 0, flexible: true)
    let plan = TestSupport.plan(blocks: [flexible])

    for suggestion in EnergyAdvisor.suggestions(for: plan, energyLevel: 1) {
        #expect(suggestion.reason.contains("could"), "reasons are offers, not orders: \(suggestion.reason)")
        #expect(!suggestion.reason.contains("!"))
    }
}
