import Foundation

/// An alexithymia-aware check-in. Every layer is optional: body sensations
/// and energy come first, dimensional sliders and emotion words only if
/// wanted, and "I'm not sure" is a complete, guilt-free answer on its own.
public struct MoodCheckIn: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public var date: Date
    public var bodySensations: [String]
    /// Energy battery 1…5.
    public var energy: Int?
    /// Unpleasant −1 … +1 pleasant.
    public var valence: Double?
    /// Low energy −1 … +1 high energy.
    public var arousal: Double?
    public var emotionWords: [String]
    public var isUnsure: Bool
    public var note: String?
    public let createdAt: Date
    public var modifiedAt: Date

    public init(
        id: UUID = UUID(),
        date: Date,
        bodySensations: [String] = [],
        energy: Int? = nil,
        valence: Double? = nil,
        arousal: Double? = nil,
        emotionWords: [String] = [],
        isUnsure: Bool = false,
        note: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.bodySensations = bodySensations
        self.energy = energy
        self.valence = valence
        self.arousal = arousal
        self.emotionWords = emotionWords
        self.isUnsure = isUnsure
        self.note = note
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

/// Curated body-sensation suggestions for the picker. Literal and concrete;
/// users can always type their own.
public enum BodySensationCatalog {
    public static let suggestions: [String] = [
        "tense shoulders",
        "tired eyes",
        "restless legs",
        "settled stomach",
        "tight chest",
        "heavy limbs",
        "buzzing energy",
        "clenched jaw",
        "slow breathing",
        "warm face",
        "cold hands",
        "empty stomach"
    ]
}
