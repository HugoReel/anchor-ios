import Foundation

/// An offer to lighten the day. The user always decides; nothing is ever
/// applied automatically.
public struct LighteningSuggestion: Sendable, Hashable {
    public enum Action: Sendable, Hashable {
        case postpone
        case convertToRest
    }

    public let blockID: UUID
    public let action: Action
    public let reason: String

    public init(blockID: UUID, action: Action, reason: String) {
        self.blockID = blockID
        self.action = action
        self.reason = reason
    }
}

public enum EnergyAdvisor {
    /// Up to three suggestions when energy is low (1–2): flexible blocks
    /// first as postponements, then the longest remaining block as a
    /// convert-to-rest offer. Rest blocks and done blocks are never touched.
    public static func suggestions(for plan: DayPlan, energyLevel: Int) -> [LighteningSuggestion] {
        []
    }
}
