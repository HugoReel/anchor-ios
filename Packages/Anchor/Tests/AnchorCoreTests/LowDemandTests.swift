import Foundation
import Testing
@testable import AnchorCore

@Test func standardClockModeShowsAll() {
    let presentation = DayPresentation.standard(mode: .clock, preferences: UserPreferences())

    #expect(presentation.showsTimes)
    #expect(presentation.showsTimers)
    #expect(presentation.showsTransitionWarnings)
    #expect(presentation.showsWins)
    #expect(!presentation.invitational)
}

@Test func sequenceModeHidesTimes() {
    let presentation = DayPresentation.standard(mode: .sequence, preferences: UserPreferences())

    #expect(!presentation.showsTimes)
    #expect(!presentation.showsTimers)
    #expect(!presentation.showsTransitionWarnings)
    #expect(presentation.showsWins)
}

@Test func lowDemandHidesTimersWarningsWins() {
    var preferences = UserPreferences()
    preferences.lowDemandMode = true

    let presentation = DayPresentation.standard(mode: .clock, preferences: preferences)

    #expect(!presentation.showsTimes)
    #expect(!presentation.showsTimers)
    #expect(!presentation.showsTransitionWarnings)
    #expect(!presentation.showsWins)
    #expect(presentation.invitational)
}

@Test func winsHiddenWhenDisabled() {
    var preferences = UserPreferences()
    preferences.showWins = false

    let presentation = DayPresentation.standard(mode: .clock, preferences: preferences)

    #expect(!presentation.showsWins)
    #expect(presentation.showsTimes)
}
