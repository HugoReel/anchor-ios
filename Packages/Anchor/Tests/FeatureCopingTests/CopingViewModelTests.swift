import Foundation
import Testing
import AnchorCore
@testable import FeatureCoping

@MainActor
private struct Setup {
    let viewModel: CopingViewModel
    let coping: InMemoryCopingRepository
    let preferences: InMemoryPreferencesRepository
}

@MainActor
private enum Fixture {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    static func setup(existing: [CopingStrategy] = [], preferences: UserPreferences = UserPreferences()) async -> Setup {
        let copingRepo = InMemoryCopingRepository()
        for strategy in existing { try? await copingRepo.upsert(strategy) }
        let prefsRepo = InMemoryPreferencesRepository()
        try? await prefsRepo.save(preferences)
        let viewModel = CopingViewModel(
            coping: copingRepo,
            preferences: prefsRepo,
            dateProvider: FixedDateProvider(now: Date(timeIntervalSince1970: 1_748_800_000), calendar: calendar)
        )
        return Setup(viewModel: viewModel, coping: copingRepo, preferences: prefsRepo)
    }
}

@MainActor
@Test func seedExamplesInsertedOnFirstLoad() async {
    let setup = await Fixture.setup()

    await setup.viewModel.load()

    #expect(!setup.viewModel.strategies.isEmpty)
    let stored = (try? await setup.coping.allCoping()) ?? []
    let allSeeds = stored.allSatisfy(\.isSeedExample)
    #expect(allSeeds)
}

@MainActor
@Test func seedInsertedExactlyOnce() async {
    let setup = await Fixture.setup()

    await setup.viewModel.load()
    let firstCount = setup.viewModel.strategies.count
    await setup.viewModel.load()

    #expect(setup.viewModel.strategies.count == firstCount)
}

@MainActor
@Test func seedNotReinsertedAfterUserClearsAll() async {
    let setup = await Fixture.setup()
    await setup.viewModel.load()

    for strategy in setup.viewModel.strategies {
        await setup.viewModel.deleteStrategy(id: strategy.id)
    }
    await setup.viewModel.load()

    // Seeding happened once; clearing does not trigger it again.
    #expect(setup.viewModel.strategies.isEmpty)
}

@MainActor
@Test func addStrategyPersists() async {
    let already = CopingStrategy(title: "Existing", orderIndex: 0)
    let setup = await Fixture.setup(existing: [already], preferences: UserPreferences(copingSeeded: true))
    await setup.viewModel.load()

    await setup.viewModel.addStrategy(title: "Cold water", note: "Splash my face.", category: nil)

    let hasColdWater = setup.viewModel.strategies.contains { $0.title == "Cold water" }
    #expect(hasColdWater)
    let stored = (try? await setup.coping.allCoping()) ?? []
    let storedHasColdWater = stored.contains { $0.title == "Cold water" }
    #expect(storedHasColdWater)
}

@MainActor
@Test func deleteStrategyRemoves() async {
    let strategy = CopingStrategy(title: "Existing", orderIndex: 0)
    let setup = await Fixture.setup(existing: [strategy], preferences: UserPreferences(copingSeeded: true))
    await setup.viewModel.load()

    await setup.viewModel.deleteStrategy(id: strategy.id)

    #expect(setup.viewModel.strategies.isEmpty)
}

@MainActor
@Test func suggestOneReturnsAStrategyWhenAvailable() async {
    let strategies = [
        CopingStrategy(title: "A", orderIndex: 0),
        CopingStrategy(title: "B", orderIndex: 1)
    ]
    let setup = await Fixture.setup(existing: strategies, preferences: UserPreferences(copingSeeded: true))
    await setup.viewModel.load()

    let suggestion = setup.viewModel.suggestOne()

    #expect(suggestion != nil)
    #expect(["A", "B"].contains(suggestion?.title ?? ""))
}

@MainActor
@Test func suggestOneReturnsNilWhenEmpty() async {
    let setup = await Fixture.setup(preferences: UserPreferences(copingSeeded: true))
    await setup.viewModel.load()

    #expect(setup.viewModel.suggestOne() == nil)
}
