import Foundation

/// An implementation intention: "If [trigger], then I will [step]".
/// Time-triggered plans surface on Today at the right moment;
/// situation-triggered plans are reminders in words only.
public struct IfThenPlan: Sendable, Hashable, Codable, Identifiable {
    public enum TriggerKind: String, Codable, Sendable {
        case time
        case situation
    }

    public let id: UUID
    public var triggerKind: TriggerKind
    public var situationText: String?
    /// Minutes from midnight, local time, for time triggers.
    public var triggerMinutes: Int?
    public var isActive: Bool
    public let createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        triggerKind: TriggerKind,
        situationText: String? = nil,
        triggerMinutes: Int? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.triggerKind = triggerKind
        self.situationText = situationText
        self.triggerMinutes = triggerMinutes
        self.isActive = isActive
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
