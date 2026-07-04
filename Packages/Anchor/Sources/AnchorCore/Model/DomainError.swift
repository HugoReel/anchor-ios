import Foundation

/// Typed domain errors. User-facing copy stays calm and actionable; the
/// underlying detail is for logs, never for guilt.
public enum DomainError: Error, Sendable, Hashable {
    case notFound(String)
    case invalidInput(String)
    case storageFailure(String)
}

extension DomainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notFound:
            "That item is not here any more. It may have been removed on another screen."
        case .invalidInput(let detail):
            "That did not quite work: \(detail)."
        case .storageFailure:
            "Saving did not work this time. Your other data is safe, and you can try again."
        }
    }
}
