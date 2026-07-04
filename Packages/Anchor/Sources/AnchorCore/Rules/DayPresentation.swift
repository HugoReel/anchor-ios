/// What the UI is allowed to show for a day. Low-Demand Mode and sequence
/// mode both work by narrowing this, never by deleting data.
public struct DayPresentation: Sendable, Hashable {
    public let showsTimes: Bool
    public let showsTimers: Bool
    public let showsTransitionWarnings: Bool
    public let showsWins: Bool
    /// Invitational copy set: "You could…" instead of task language.
    public let invitational: Bool

    public init(showsTimes: Bool, showsTimers: Bool, showsTransitionWarnings: Bool, showsWins: Bool, invitational: Bool) {
        self.showsTimes = showsTimes
        self.showsTimers = showsTimers
        self.showsTransitionWarnings = showsTransitionWarnings
        self.showsWins = showsWins
        self.invitational = invitational
    }

    public static func standard(mode: ScheduleMode, preferences: UserPreferences) -> DayPresentation {
        let lowDemand = preferences.lowDemandMode
        let timed = mode == .clock && !lowDemand
        return DayPresentation(
            showsTimes: timed,
            showsTimers: timed,
            showsTransitionWarnings: timed,
            showsWins: preferences.showWins && !lowDemand,
            invitational: lowDemand
        )
    }
}
