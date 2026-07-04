import Foundation
import AnchorCore

/// The live clock. A zero-logic passthrough to the system, so that
/// everything else can inject `DateProviding` and stay testable. All real
/// scheduling decisions live in AnchorCore, tested with `FixedDateProvider`.
public struct SystemDateProvider: DateProviding {
    public init() {}

    public var now: Date { Date() }
    public var calendar: Calendar { Calendar.current }
}
