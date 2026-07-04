import Foundation
import Observation
import AnchorCore

/// Drives the coping strategy bank. Seeds a few editable examples once so the
/// bank is never empty on first use, and offers a shuffle to suggest one.
@MainActor
@Observable
public final class CopingViewModel {
    public private(set) var strategies: [CopingStrategy] = []
    public private(set) var loadFailed = false

    private let coping: any CopingRepository
    private let preferences: any PreferencesRepository
    private let dateProvider: any DateProviding

    public init(
        coping: any CopingRepository,
        preferences: any PreferencesRepository,
        dateProvider: any DateProviding
    ) {
        self.coping = coping
        self.preferences = preferences
        self.dateProvider = dateProvider
    }

    public func load() async {
        loadFailed = false
        do {
            var prefs = try await preferences.load()
            var current = try await coping.allCoping()
            if prefs.copingSeeded != true {
                if current.isEmpty {
                    for example in CopingSeeds.examples(now: dateProvider.now) {
                        try await coping.upsert(example)
                    }
                    current = try await coping.allCoping()
                }
                prefs.copingSeeded = true
                prefs.modifiedAt = dateProvider.now
                try await preferences.save(prefs)
            }
            strategies = current
        } catch {
            loadFailed = true
        }
    }

    public func addStrategy(title: String, note: String?, category: String?) async {
        let now = dateProvider.now
        let strategy = CopingStrategy(
            title: title,
            note: note,
            category: category,
            orderIndex: (strategies.map(\.orderIndex).max() ?? -1) + 1,
            isSeedExample: false,
            createdAt: now,
            modifiedAt: now
        )
        await save(strategy)
    }

    public func updateStrategy(_ strategy: CopingStrategy) async {
        var updated = strategy
        updated.modifiedAt = dateProvider.now
        await save(updated)
    }

    public func deleteStrategy(id: UUID) async {
        do {
            try await coping.deleteCoping(id: id)
            strategies = try await coping.allCoping()
        } catch {
            loadFailed = true
        }
    }

    /// A random strategy, or nil when the bank is empty.
    public func suggestOne() -> CopingStrategy? {
        strategies.randomElement()
    }

    private func save(_ strategy: CopingStrategy) async {
        do {
            try await coping.upsert(strategy)
            strategies = try await coping.allCoping()
        } catch {
            loadFailed = true
        }
    }
}
