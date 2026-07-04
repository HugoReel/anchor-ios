import SwiftUI

/// User motion preference. Ordered by restrictiveness so the most
/// restrictive of (user choice, system Reduce Motion) always wins.
public enum MotionLevel: String, CaseIterable, Codable, Sendable, Comparable {
    case full
    case reduced
    case off

    public var displayName: String {
        switch self {
        case .full: "Full"
        case .reduced: "Reduced"
        case .off: "None"
        }
    }

    private var restrictiveness: Int {
        switch self {
        case .full: 0
        case .reduced: 1
        case .off: 2
        }
    }

    public static func < (lhs: MotionLevel, rhs: MotionLevel) -> Bool {
        lhs.restrictiveness < rhs.restrictiveness
    }
}

/// Motion tokens. Nothing autoplays; transitions stay at or under 250 ms
/// and animate opacity/position only. Every animation in the app routes
/// through `animation(for:)` so the motion setting always applies.
public enum AnchorMotion {
    public static func effective(user: MotionLevel, systemReduceMotion: Bool) -> MotionLevel {
        let system: MotionLevel = systemReduceMotion ? .reduced : .full
        return max(user, system)
    }

    public static func animation(for level: MotionLevel) -> Animation? {
        switch level {
        case .full: .easeOut(duration: 0.2)
        case .reduced: .easeOut(duration: 0.12)
        case .off: nil
        }
    }
}
