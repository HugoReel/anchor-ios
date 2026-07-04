import Foundation

/// Something that just happened and might mint a gentle win.
public enum WinEventTrigger: Sendable {
    case blockDone(TimeBlock)
    case stepDone(BlockStep)
    case goalStepDone(GoalStep)
    case checkIn
    case journal
}

/// An additive counter shown on Today. Counters only ever grow; zero-count
/// summaries are omitted rather than shown as zero.
public struct WinsSummary: Sendable, Hashable {
    public enum SummaryKind: String, Sendable {
        case checkInsThisMonth
        case showedUpThisWeek
        case blocksDoneThisWeek
        case restThisWeek
    }

    public let kind: SummaryKind
    public let label: String
    public let count: Int

    public init(kind: SummaryKind, label: String, count: Int) {
        self.kind = kind
        self.label = label
        self.count = count
    }
}

/// The streak replacement. Wins accrue; they never reset, decay or judge.
public enum WinsEngine {
    /// Mints a win for a trigger, or nil while wins are paused. Hiding wins
    /// is a display preference and does not stop minting.
    public static func mintedWin(for trigger: WinEventTrigger, preferences: UserPreferences, at instant: Date) -> WinEvent? {
        guard !preferences.winsPaused else { return nil }
        switch trigger {
        case .blockDone(let block):
            return WinEvent(
                date: instant,
                kind: block.isRest ? .rest : .blockDone,
                label: block.title,
                sourceID: block.id,
                createdAt: instant,
                modifiedAt: instant
            )
        case .stepDone(let step):
            return WinEvent(date: instant, kind: .stepDone, label: step.title, sourceID: step.id, createdAt: instant, modifiedAt: instant)
        case .goalStepDone(let step):
            return WinEvent(date: instant, kind: .goalStepDone, label: step.title, sourceID: step.id, createdAt: instant, modifiedAt: instant)
        case .checkIn:
            return WinEvent(date: instant, kind: .checkIn, createdAt: instant, modifiedAt: instant)
        case .journal:
            return WinEvent(date: instant, kind: .journal, createdAt: instant, modifiedAt: instant)
        }
    }

    /// Additive summaries for the reference day's week and month. Days
    /// without events are simply not mentioned; zero counts are omitted.
    public static func summaries(events: [WinEvent], reference: DayDate, calendar: Calendar) -> [WinsSummary] {
        guard !events.isEmpty else { return [] }
        let referenceDate = reference.startDate(calendar: calendar)

        func inWeek(_ date: Date) -> Bool {
            calendar.isDate(date, equalTo: referenceDate, toGranularity: .weekOfYear)
        }
        func inMonth(_ date: Date) -> Bool {
            calendar.isDate(date, equalTo: referenceDate, toGranularity: .month)
        }

        var result: [WinsSummary] = []

        let checkIns = events.filter { $0.kind == .checkIn && inMonth($0.date) }.count
        if checkIns > 0 {
            result.append(WinsSummary(kind: .checkInsThisMonth, label: Copy.winsCheckIns(count: checkIns), count: checkIns))
        }

        let showedUpDays = Set(
            events.filter { inWeek($0.date) }.map { DayDate(date: $0.date, calendar: calendar) }
        ).count
        if showedUpDays > 0 {
            result.append(WinsSummary(kind: .showedUpThisWeek, label: Copy.winsShowedUp(days: showedUpDays), count: showedUpDays))
        }

        let blocksDone = events.filter { $0.kind == .blockDone && inWeek($0.date) }.count
        if blocksDone > 0 {
            result.append(WinsSummary(kind: .blocksDoneThisWeek, label: Copy.winsBlocksDone(count: blocksDone), count: blocksDone))
        }

        let rests = events.filter { $0.kind == .rest && inWeek($0.date) }.count
        if rests > 0 {
            result.append(WinsSummary(kind: .restThisWeek, label: Copy.winsRest(count: rests), count: rests))
        }

        return result
    }
}
