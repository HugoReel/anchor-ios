import AnchorCore

/// Composition root container, assembled once at launch.
/// Grows repositories and system adapters in phase 2; nothing else in the
/// app target should hold state or logic.
struct AppDependencies: Sendable {
    let logger: AnchorLogger

    static func live() -> AppDependencies {
        AppDependencies(logger: AnchorLogger(category: "app"))
    }
}
