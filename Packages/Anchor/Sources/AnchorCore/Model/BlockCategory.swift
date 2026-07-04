/// The five fixed block categories plus Rest as a first-class category.
/// Rest is never optional extra: rest blocks count as wins and can never
/// be marked missed.
public enum BlockCategory: String, CaseIterable, Codable, Sendable, Hashable {
    case focus
    case care
    case home
    case connect
    case out
    case rest

    public var displayName: String {
        switch self {
        case .focus: "Focus"
        case .care: "Care"
        case .home: "Home"
        case .connect: "Connect"
        case .out: "Out and about"
        case .rest: "Rest"
        }
    }

    public var isRest: Bool {
        self == .rest
    }
}
