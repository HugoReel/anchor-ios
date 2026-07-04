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
    public static let maxSuggestions = 3
    public static let lowEnergyThreshold = 2
    public static let longBlockMinutes = 60

    /// Up to three suggestions when energy is low (1–2): flexible blocks
    /// first as postponements, then the longest remaining block as a
    /// convert-to-rest offer. Rest blocks and done blocks are never touched.
    public static func suggestions(for plan: DayPlan, energyLevel: Int) -> [LighteningSuggestion] {
        guard energyLevel <= lowEnergyThreshold else { return [] }
        let candidates = plan.sortedBlocks.filter { $0.state == .notStarted && !$0.isRest }

        var result: [LighteningSuggestion] = []
        for block in candidates where block.isFlexible {
            result.append(
                LighteningSuggestion(blockID: block.id, action: .postpone, reason: Copy.postponeSuggestion(title: block.title))
            )
        }

        let alreadySuggested = Set(result.map(\.blockID))
        let remaining = candidates.filter { !alreadySuggested.contains($0.id) }
        if let longest = remaining.max(by: { ($0.durationMinutes ?? 0) < ($1.durationMinutes ?? 0) }),
           (longest.durationMinutes ?? 0) >= longBlockMinutes {
            result.append(
                LighteningSuggestion(blockID: longest.id, action: .convertToRest, reason: Copy.convertToRestSuggestion(title: longest.title))
            )
        }

        return Array(result.prefix(maxSuggestions))
    }
}
