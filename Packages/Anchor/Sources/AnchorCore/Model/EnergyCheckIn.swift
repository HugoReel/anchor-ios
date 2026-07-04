import Foundation

/// The daily capacity check-in: one battery level per day, optional note.
/// Skippable, and only ever used to offer — never impose — a lighter day.
public struct EnergyCheckIn: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public var day: DayDate
    /// Battery 1…5.
    public var level: Int
    public var note: String?
    public let createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        day: DayDate,
        level: Int,
        note: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.day = day
        self.level = level
        self.note = note
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
