import Foundation
import Observation
import AnchorCore

/// One entry in the reflection history — a check-in or a journal entry.
public enum ReflectionItem: Identifiable, Sendable {
    case checkIn(MoodCheckIn)
    case journal(JournalEntry)

    public var id: UUID {
        switch self {
        case .checkIn(let value): value.id
        case .journal(let value): value.id
        }
    }

    public var date: Date {
        switch self {
        case .checkIn(let value): value.date
        case .journal(let value): value.date
        }
    }
}

/// A counted body sensation, most frequent first.
public struct SensationCount: Sendable, Hashable {
    public let label: String
    public let count: Int
}

/// Descriptive, never judgemental. Neutral counts and trends only.
public struct ReflectionPatterns: Sendable {
    public let checkInCount: Int
    public let averageEnergy: Double?
    public let topBodySensations: [SensationCount]

    public var summaryLines: [String] {
        var lines: [String] = []
        if checkInCount > 0 {
            lines.append(checkInCount == 1 ? "1 check-in recorded" : "\(checkInCount) check-ins recorded")
        }
        if let averageEnergy {
            lines.append("Energy has averaged about \(String(format: "%.1f", averageEnergy)) out of 5")
        }
        if let top = topBodySensations.first {
            lines.append("Most noted sensation: \(top.label)")
        }
        return lines
    }

    static let empty = ReflectionPatterns(checkInCount: 0, averageEnergy: nil, topBodySensations: [])
}

/// Drives Reflect. The check-in is layered and every layer is optional;
/// "I'm not sure" is always a complete, guilt-free answer. Journaling
/// autosaves with no minimum length.
@MainActor
@Observable
public final class ReflectViewModel {
    // Check-in draft.
    public var bodySensations: Set<String> = []
    public var energy: Int?
    public var valence: Double?
    public var arousal: Double?
    public var emotionWords: Set<String> = []
    public var isUnsure = false
    public var checkInNote = ""

    public private(set) var history: [ReflectionItem] = []
    public private(set) var patterns: ReflectionPatterns = .empty
    public private(set) var todaysJournalText = ""
    public private(set) var loadFailed = false

    private let reflections: any ReflectionRepository
    private let wins: any WinRepository
    private let preferences: any PreferencesRepository
    private let dateProvider: any DateProviding
    private var preferencesValue = UserPreferences()
    private var todaysJournalID: UUID?

    public init(
        reflections: any ReflectionRepository,
        wins: any WinRepository,
        preferences: any PreferencesRepository,
        dateProvider: any DateProviding
    ) {
        self.reflections = reflections
        self.wins = wins
        self.preferences = preferences
        self.dateProvider = dateProvider
    }

    /// A check-in is savable once it carries any information at all, or when
    /// the person has said they're not sure.
    public var canSaveCheckIn: Bool {
        isUnsure
            || !bodySensations.isEmpty
            || energy != nil
            || valence != nil
            || arousal != nil
            || !emotionWords.isEmpty
            || !checkInNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public func load() async {
        loadFailed = false
        do {
            preferencesValue = try await preferences.load()
            let checkIns = try await reflections.allCheckIns()
            let journals = try await reflections.allJournalEntries()
            rebuildHistory(checkIns: checkIns, journals: journals)
            patterns = Self.patterns(from: checkIns)

            let today = DayDate(date: dateProvider.now, calendar: dateProvider.calendar)
            if let entry = journals.first(where: { DayDate(date: $0.date, calendar: dateProvider.calendar) == today }) {
                todaysJournalID = entry.id
                todaysJournalText = entry.text
            } else {
                todaysJournalID = nil
                todaysJournalText = ""
            }
        } catch {
            loadFailed = true
        }
    }

    public func saveCheckIn() async {
        guard canSaveCheckIn else { return }
        let now = dateProvider.now
        let checkIn = MoodCheckIn(
            date: now,
            bodySensations: bodySensations.sorted(),
            energy: energy,
            valence: valence,
            arousal: arousal,
            emotionWords: emotionWords.sorted(),
            isUnsure: isUnsure,
            note: normalised(checkInNote),
            createdAt: now,
            modifiedAt: now
        )
        do {
            try await reflections.upsert(checkIn)
            if let win = WinsEngine.mintedWin(for: .checkIn, preferences: preferencesValue, at: now) {
                try await wins.append(win)
            }
            resetDraft()
            await load()
        } catch {
            loadFailed = true
        }
    }

    public func resetDraft() {
        bodySensations = []
        energy = nil
        valence = nil
        arousal = nil
        emotionWords = []
        isUnsure = false
        checkInNote = ""
    }

    /// Saves the day's journal entry, creating it (and minting a win) the
    /// first time, updating it thereafter. Blank text is never saved.
    public func saveJournal(text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = dateProvider.now
        do {
            if let id = todaysJournalID,
               let existing = try await reflections.allJournalEntries().first(where: { $0.id == id }) {
                var updated = existing
                updated.text = text
                updated.modifiedAt = now
                try await reflections.upsert(updated)
            } else {
                let entry = JournalEntry(date: now, text: text, createdAt: now, modifiedAt: now)
                todaysJournalID = entry.id
                try await reflections.upsert(entry)
                if let win = WinsEngine.mintedWin(for: .journal, preferences: preferencesValue, at: now) {
                    try await wins.append(win)
                }
            }
            todaysJournalText = text
            let checkIns = try await reflections.allCheckIns()
            let journals = try await reflections.allJournalEntries()
            rebuildHistory(checkIns: checkIns, journals: journals)
        } catch {
            loadFailed = true
        }
    }

    public func deleteJournal(id: UUID) async {
        do {
            try await reflections.delete(journalID: id)
            if id == todaysJournalID {
                todaysJournalID = nil
                todaysJournalText = ""
            }
            await load()
        } catch {
            loadFailed = true
        }
    }

    public func deleteCheckIn(id: UUID) async {
        do {
            try await reflections.delete(checkInID: id)
            await load()
        } catch {
            loadFailed = true
        }
    }

    // MARK: - Helpers

    private func normalised(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func rebuildHistory(checkIns: [MoodCheckIn], journals: [JournalEntry]) {
        var items = checkIns.map { ReflectionItem.checkIn($0) }
        items.append(contentsOf: journals.map { ReflectionItem.journal($0) })
        history = items.sorted { $0.date > $1.date }
    }

    private static func patterns(from checkIns: [MoodCheckIn]) -> ReflectionPatterns {
        guard !checkIns.isEmpty else { return .empty }
        let energies = checkIns.compactMap(\.energy)
        let average = energies.isEmpty ? nil : Double(energies.reduce(0, +)) / Double(energies.count)

        var counts: [String: Int] = [:]
        for checkIn in checkIns {
            for sensation in checkIn.bodySensations {
                counts[sensation, default: 0] += 1
            }
        }
        let top = counts
            .map { SensationCount(label: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                lhs.count != rhs.count ? lhs.count > rhs.count : lhs.label < rhs.label
            }

        return ReflectionPatterns(checkInCount: checkIns.count, averageEnergy: average, topBodySensations: Array(top.prefix(5)))
    }
}
