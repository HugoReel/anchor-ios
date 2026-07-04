import Foundation

/// One gentle win. The stream is append-only: nothing ever resets, decays
/// or deletes a win, and days without wins are simply never mentioned.
public struct WinEvent: Sendable, Hashable, Codable, Identifiable {
    public enum WinKind: String, CaseIterable, Codable, Sendable {
        case blockDone
        case stepDone
        case goalStepDone
        case checkIn
        case journal
        case rest
        case showedUp
    }

    public let id: UUID
    public let date: Date
    public let kind: WinKind
    public let label: String?
    public let sourceID: UUID?
    public let createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        date: Date,
        kind: WinKind,
        label: String? = nil,
        sourceID: UUID? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.kind = kind
        self.label = label
        self.sourceID = sourceID
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
