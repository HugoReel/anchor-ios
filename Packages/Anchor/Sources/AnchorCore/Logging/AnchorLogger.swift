import os

/// Thin wrapper over `os.Logger` so modules never reach for `print`.
/// One instance per module, category named after the module.
public struct AnchorLogger: Sendable {
    private let logger: os.Logger

    public init(category: String) {
        self.logger = os.Logger(subsystem: "com.hugoreel.anchor", category: category)
    }

    public func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    public func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    public func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
