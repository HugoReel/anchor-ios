import Foundation
import Testing
@testable import AnchorCore

private let newYork = TestSupport.newYork

@Test func blockDoneMintsWin() {
    let focus = TestSupport.block("Morning focus", startHour: 9, minutes: 50, order: 0)
    let minted = WinsEngine.mintedWin(
        for: .blockDone(focus),
        preferences: UserPreferences(),
        at: TestSupport.time(9, 50)
    )

    #expect(minted?.kind == .blockDone)
    #expect(minted?.sourceID == focus.id)
    #expect(minted?.label == "Morning focus")
}

@Test func restCompletionMintsWin() {
    let rest = TestSupport.block("Quiet time", category: .rest, startHour: 14, minutes: 30, order: 0)
    let minted = WinsEngine.mintedWin(for: .blockDone(rest), preferences: UserPreferences(), at: TestSupport.time(14, 30))

    #expect(minted?.kind == .rest)
}

@Test func checkInMintsWin() {
    let minted = WinsEngine.mintedWin(for: .checkIn, preferences: UserPreferences(), at: TestSupport.time(20))
    #expect(minted?.kind == .checkIn)
}

@Test func pausedWinsMintNothing() {
    var preferences = UserPreferences()
    preferences.winsPaused = true

    let minted = WinsEngine.mintedWin(for: .checkIn, preferences: preferences, at: TestSupport.time(20))

    #expect(minted == nil)
}

@Test func hiddenWinsStillMint() {
    // Hiding wins is a display choice; pausing is the only thing that stops counting.
    var preferences = UserPreferences()
    preferences.showWins = false

    let minted = WinsEngine.mintedWin(for: .journal, preferences: preferences, at: TestSupport.time(20))

    #expect(minted?.kind == .journal)
}

@Test func showedUpCountsDistinctDays() {
    // Five events across three distinct days in the reference week (2025-06-01…07).
    let events = [
        WinEvent(date: TestSupport.time(9, day: DayDate(year: 2025, month: 6, day: 2)), kind: .checkIn),
        WinEvent(date: TestSupport.time(15, day: DayDate(year: 2025, month: 6, day: 2)), kind: .blockDone),
        WinEvent(date: TestSupport.time(9, day: DayDate(year: 2025, month: 6, day: 4)), kind: .journal),
        WinEvent(date: TestSupport.time(9, day: DayDate(year: 2025, month: 6, day: 6)), kind: .rest),
        WinEvent(date: TestSupport.time(20, day: DayDate(year: 2025, month: 6, day: 6)), kind: .checkIn)
    ]

    let summaries = WinsEngine.summaries(events: events, reference: TestSupport.baseDay, calendar: newYork)

    let showedUp = summaries.first { $0.kind == .showedUpThisWeek }
    #expect(showedUp?.count == 3)
}

@Test func monthWindowUsesCalendar() {
    let events = [
        WinEvent(date: TestSupport.time(9, day: DayDate(year: 2025, month: 5, day: 31)), kind: .checkIn),
        WinEvent(date: TestSupport.time(9, day: DayDate(year: 2025, month: 6, day: 3)), kind: .checkIn)
    ]

    let summaries = WinsEngine.summaries(events: events, reference: TestSupport.baseDay, calendar: newYork)

    let checkIns = summaries.first { $0.kind == .checkInsThisMonth }
    #expect(checkIns?.count == 1)
}

@Test func summariesNeverMentionMissedDays() {
    // Sparse events: gaps are simply not mentioned, no zero counts appear.
    let events = [
        WinEvent(date: TestSupport.time(9, day: DayDate(year: 2025, month: 6, day: 2)), kind: .checkIn)
    ]

    let summaries = WinsEngine.summaries(events: events, reference: TestSupport.baseDay, calendar: newYork)

    #expect(!summaries.isEmpty)
    for summary in summaries {
        #expect(summary.count >= 1, "zero-count summaries must be omitted, got \(summary.label)")
        #expect(!summary.label.lowercased().contains("missed"))
        #expect(!summary.label.contains("!"))
    }
}

@Test func emptyEventsYieldNoSummaries() {
    let summaries = WinsEngine.summaries(events: [], reference: TestSupport.baseDay, calendar: newYork)
    #expect(summaries.isEmpty)
}
