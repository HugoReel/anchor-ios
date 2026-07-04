import Foundation
import AnchorCore

/// Shared encode/decode for the Codable payloads stored on each model.
/// ISO 8601 dates keep the payload readable and stable across releases.
enum PayloadCoder {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static func encode<Value: Encodable>(_ value: Value) throws -> Data {
        do {
            return try encoder.encode(value)
        } catch {
            throw DomainError.storageFailure("could not encode \(Value.self)")
        }
    }

    static func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw DomainError.storageFailure("could not decode \(Value.self)")
        }
    }
}
