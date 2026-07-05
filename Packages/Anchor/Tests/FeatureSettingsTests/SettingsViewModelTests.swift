import Foundation
import Testing
import AnchorCore
import AnchorDesign
@testable import FeatureSettings

/// Counts wipes so the two-step delete can be verified without a real store.
private actor SpyDataWiper: DataWiping {
    private(set) var wipes = 0
    func wipeAll() async throws { wipes += 1 }
}

@MainActor
private func makeViewModel(
    preferences: InMemoryPreferencesRepository = InMemoryPreferencesRepository(),
    wiper: any DataWiping = SpyDataWiper()
) -> SettingsViewModel {
    let calendar = Calendar(identifier: .gregorian)
    let exporter = DataExporter(
        dayPlans: InMemoryDayPlanRepository(),
        templates: InMemoryTemplateRepository(),
        goals: InMemoryGoalRepository(),
        reflections: InMemoryReflectionRepository(calendar: calendar),
        energy: InMemoryEnergyRepository(),
        wins: InMemoryWinRepository(calendar: calendar),
        coping: InMemoryCopingRepository(),
        preferences: preferences
    )
    let provider = FixedDateProvider(now: Date(timeIntervalSince1970: 1_700_000_000), calendar: calendar)
    return SettingsViewModel(preferences: preferences, exporter: exporter, wiper: wiper, dateProvider: provider)
}

@MainActor
@Test func soundDefaultsOff() async {
    let viewModel = makeViewModel()
    await viewModel.load()
    #expect(viewModel.soundEnabled == false)
}

@MainActor
@Test func settingsPersistAcrossReload() async {
    let prefs = InMemoryPreferencesRepository()
    let viewModel = makeViewModel(preferences: prefs)
    await viewModel.load()

    await viewModel.update(theme: .warm)
    await viewModel.setSound(true)

    let reloaded = makeViewModel(preferences: prefs)
    await reloaded.load()
    #expect(reloaded.theme == .warm)
    #expect(reloaded.soundEnabled)
}

@MainActor
@Test func exportProducesDecodableJSON() async throws {
    let viewModel = makeViewModel()
    await viewModel.load()

    let data = await viewModel.exportData()
    let json = try #require(data)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let payload = try decoder.decode(ExportPayload.self, from: json)
    #expect(payload.schemaVersion == 1)
}

@MainActor
@Test func deleteRequiresTwoConfirmations() async {
    let spy = SpyDataWiper()
    let viewModel = makeViewModel(wiper: spy)
    await viewModel.load()

    // A lone confirm, without arming, does nothing.
    await viewModel.confirmDelete()
    let afterLone = await spy.wipes
    #expect(afterLone == 0)
    #expect(viewModel.didDeleteEverything == false)

    // Arm first, then confirm: exactly one wipe.
    viewModel.armDelete()
    await viewModel.confirmDelete()
    let afterArmed = await spy.wipes
    #expect(afterArmed == 1)
    #expect(viewModel.didDeleteEverything)
}
