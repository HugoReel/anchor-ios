import Foundation
import Testing
@testable import AnchorCore

/// Guard rail for the spec's copy rules: sentence case, literal, no
/// exclamation marks, and guilt language banned outright.
@Test func copyContainsNoBannedPhrases() {
    let banned = ["missed", "streak", "!", "don't break", "hurry", "failed", "you must", "overdue"]
    for sample in Copy.auditableSamples {
        let lowered = sample.lowercased()
        for phrase in banned {
            #expect(!lowered.contains(phrase), "\"\(sample)\" contains banned phrase \"\(phrase)\"")
        }
    }
}

@Test func copyTransitionBodyMentionsLeadAndNext() {
    let body = Copy.transitionBody(leadMinutes: 15, nextTitle: "Lunch")
    #expect(body.contains("15"))
    #expect(body.contains("Lunch"))

    let withoutNext = Copy.transitionBody(leadMinutes: 20, nextTitle: nil)
    #expect(withoutNext.contains("20"))
}

@Test func copyPluralisesCounts() {
    #expect(Copy.winsCheckIns(count: 1).contains("1 check-in "))
    #expect(Copy.winsCheckIns(count: 3).contains("3 check-ins"))
    #expect(Copy.winsShowedUp(days: 1).contains("1 day "))
    #expect(Copy.winsShowedUp(days: 4).contains("4 days"))
}
