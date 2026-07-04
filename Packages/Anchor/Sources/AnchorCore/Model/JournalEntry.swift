import Foundation

/// Free journaling. Autosaved, no minimum length, no forced prompts —
/// `promptShown` records an optional gentle prompt if one was offered.
public struct JournalEntry: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public var date: Date
    public var text: String
    public var promptShown: String?
    public let createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        date: Date,
        text: String = "",
        promptShown: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.text = text
        self.promptShown = promptShown
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
