import AnchorCore
import AnchorPersistence
import AnchorPlatform
import SwiftData

/// Composition root container, assembled once at launch. Holds the system
/// clock and the SwiftData-backed store; feature ViewModels receive the
/// repository protocols they need from here in phase 3. Nothing else in the
/// app target holds state or logic.
struct AppDependencies: Sendable {
    let logger: AnchorLogger
    let dateProvider: any DateProviding
    let store: SwiftDataStore

    static func live() -> AppDependencies {
        let logger = AnchorLogger(category: "app")
        let dateProvider = SystemDateProvider()
        let container: ModelContainer
        do {
            container = try ModelContainerFactory.makeContainer()
        } catch {
            // The on-disk store could not open. Rather than crash on launch,
            // fall back to an in-memory store so the app still runs; the
            // failure is logged for diagnosis.
            logger.error("Falling back to in-memory store: \(error.localizedDescription)")
            container = Self.inMemoryFallback()
        }
        let store = SwiftDataStore(modelContainer: container, calendar: dateProvider.calendar)
        return AppDependencies(logger: logger, dateProvider: dateProvider, store: store)
    }

    private static func inMemoryFallback() -> ModelContainer {
        do {
            return try ModelContainerFactory.makeContainer(inMemory: true)
        } catch {
            // An in-memory store failing to open indicates a schema-level
            // programming error, surfaced loudly in development.
            preconditionFailure("in-memory store failed to open: \(error)")
        }
    }
}
