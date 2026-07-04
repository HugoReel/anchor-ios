import Foundation
import Testing
import AnchorCore
@testable import FeatureReflect

@MainActor
private struct Setup {
    let viewModel: ReflectViewModel
    let reflections: InMemoryReflectionRepository
    let wins: InMemoryWinRepository
}

@MainActor
private enum Fixture {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    static let day = DayDate(year: 2025, month: 6, day: 2)

    static func at(_ hour: Int) -> Date {
        day.startDate(calendar: calendar).addingTimeInterval(Double(hour) * 3600)
    }

    static func setup(checkIns: [MoodCheckIn] = [], journals: [JournalEntry] = []) async -> Setup {
        let reflectionRepo = InMemoryReflectionRepository(calendar: calendar)
        for checkIn in checkIns { try? await reflectionRepo.upsert(checkIn) }
        for journal in journals { try? await reflectionRepo.upsert(journal) }
        let winRepo = InMemoryWinRepository(calendar: calendar)
        let prefsRepo = InMemoryPreferencesRepository()
        let viewModel = ReflectViewModel(
            reflections: reflectionRepo,
            wins: winRepo,
            preferences: prefsRepo,
            dateProvider: FixedDateProvider(now: at(20), calendar: calendar)
        )
        return Setup(viewModel: viewModel, reflections: reflectionRepo, wins: winRepo)
    }
}

@MainActor
@Test func checkInSavableWithOnlyBodySensations() async {
    let setup = await Fixture.setup()
    await setup.viewModel.load()

    setup.viewModel.bodySensations = ["tired eyes"]

    #expect(setup.viewModel.canSaveCheckIn)
    await setup.viewModel.saveCheckIn()
    let saved = (try? await setup.reflections.allCheckIns()) ?? []
    #expect(saved.count == 1)
    #expect(saved.first?.bodySensations == ["tired eyes"])
}

@MainActor
@Test func checkInSavableAsNotSureAlone() async {
    let setup = await Fixture.setup()
    await setup.viewModel.load()

    setup.viewModel.isUnsure = true

    #expect(setup.viewModel.canSaveCheckIn)
    await setup.viewModel.saveCheckIn()
    let saved = (try? await setup.reflections.allCheckIns()) ?? []
    #expect(saved.first?.isUnsure == true)
}

@MainActor
@Test func emptyDraftIsNotSavable() async {
    let setup = await Fixture.setup()
    await setup.viewModel.load()

    #expect(setup.viewModel.canSaveCheckIn == false)
}

@MainActor
@Test func emotionWordsNeverRequired() async {
    let setup = await Fixture.setup()
    await setup.viewModel.load()

    setup.viewModel.energy = 3

    // Energy alone is enough; emotion words stay empty.
    #expect(setup.viewModel.canSaveCheckIn)
    #expect(setup.viewModel.emotionWords.isEmpty)
}

@MainActor
@Test func saveCheckInMintsWinAndResetsDraft() async {
    let setup = await Fixture.setup()
    await setup.viewModel.load()
    setup.viewModel.bodySensations = ["settled stomach"]
    setup.viewModel.energy = 4

    await setup.viewModel.saveCheckIn()

    let events = (try? await setup.wins.allEvents()) ?? []
    #expect(events.first?.kind == .checkIn)
    // Draft cleared for next time.
    #expect(setup.viewModel.bodySensations.isEmpty)
    #expect(setup.viewModel.energy == nil)
    #expect(setup.viewModel.canSaveCheckIn == false)
}

@MainActor
@Test func saveJournalCreatesEntryAndMintsWin() async {
    let setup = await Fixture.setup()
    await setup.viewModel.load()

    await setup.viewModel.saveJournal(text: "A calm evening.")

    let entries = (try? await setup.reflections.allJournalEntries()) ?? []
    #expect(entries.first?.text == "A calm evening.")
    let events = (try? await setup.wins.allEvents()) ?? []
    #expect(events.first?.kind == .journal)
}

@MainActor
@Test func saveJournalUpdatesExistingWithoutSecondWin() async {
    let setup = await Fixture.setup()
    await setup.viewModel.load()

    await setup.viewModel.saveJournal(text: "First draft.")
    await setup.viewModel.saveJournal(text: "First draft, expanded.")

    let entries = (try? await setup.reflections.allJournalEntries()) ?? []
    #expect(entries.count == 1)
    #expect(entries.first?.text == "First draft, expanded.")
    // Journaling more on the same day is not a new win.
    let events = (try? await setup.wins.allEvents()) ?? []
    #expect(events.count == 1)
}

@MainActor
@Test func blankJournalDoesNotSave() async {
    let setup = await Fixture.setup()
    await setup.viewModel.load()

    await setup.viewModel.saveJournal(text: "   ")

    let entries = (try? await setup.reflections.allJournalEntries()) ?? []
    #expect(entries.isEmpty)
    let events = (try? await setup.wins.allEvents()) ?? []
    #expect(events.isEmpty)
}

@MainActor
@Test func historyLoadsCheckInsAndJournals() async {
    let checkIn = MoodCheckIn(date: Fixture.at(9), bodySensations: ["restless legs"])
    let journal = JournalEntry(date: Fixture.at(10), text: "Morning thoughts.")
    let setup = await Fixture.setup(checkIns: [checkIn], journals: [journal])

    await setup.viewModel.load()

    #expect(setup.viewModel.history.count == 2)
}

@MainActor
@Test func patternsSummariseNeutrally() async {
    let checkIns = [
        MoodCheckIn(date: Fixture.at(9), bodySensations: ["tired eyes"], energy: 2),
        MoodCheckIn(date: Fixture.at(10), bodySensations: ["tired eyes", "tense shoulders"], energy: 4)
    ]
    let setup = await Fixture.setup(checkIns: checkIns)
    await setup.viewModel.load()

    let patterns = setup.viewModel.patterns

    #expect(patterns.checkInCount == 2)
    #expect(patterns.topBodySensations.first?.label == "tired eyes")
    #expect(patterns.topBodySensations.first?.count == 2)
    for line in patterns.summaryLines {
        let lowered = line.lowercased()
        #expect(!lowered.contains("should"))
        #expect(!lowered.contains("bad"))
        #expect(!lowered.contains("!"))
        #expect(!lowered.contains("streak"))
    }
}
