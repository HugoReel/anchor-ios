/// A block is either not started yet or done. There is deliberately no
/// "missed" state anywhere in the model: falling behind schedule is never
/// represented as failure, and rest can never be marked missed because the
/// state does not exist.
public enum BlockState: String, Codable, Sendable {
    case notStarted
    case done
}
