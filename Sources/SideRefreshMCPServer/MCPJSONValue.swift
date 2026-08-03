import Foundation

public enum MCPJSONValue: Equatable, Sendable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([MCPJSONValue])
    case object([String: MCPJSONValue])

    public var boolValue: Bool? {
        guard case .bool(let value) = self else {
            return nil
        }
        return value
    }

    public var intValue: Int? {
        guard case .int(let value) = self else {
            return nil
        }
        return value
    }

    public var stringValue: String? {
        guard case .string(let value) = self else {
            return nil
        }
        return value
    }

    public var objectValue: [String: MCPJSONValue]? {
        guard case .object(let value) = self else {
            return nil
        }
        return value
    }

    public var arrayValue: [MCPJSONValue]? {
        guard case .array(let value) = self else {
            return nil
        }
        return value
    }

    public init<T: Encodable>(encoding value: T) throws {
        let data = try JSONEncoder.sideRefreshMCP.encode(value)
        self = try JSONDecoder().decode(MCPJSONValue.self, from: data)
    }

    public func jsonData(prettyPrinted: Bool = false) throws -> Data {
        let encoder = JSONEncoder.sideRefreshMCP
        if prettyPrinted {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        return try encoder.encode(self)
    }

    public func jsonString(prettyPrinted: Bool = false) throws -> String {
        String(
            decoding: try jsonData(prettyPrinted: prettyPrinted),
            as: UTF8.self
        )
    }
}

extension MCPJSONValue: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(
            [MCPJSONValue].self
        ) {
            self = .array(value)
        } else if let value = try? container.decode(
            [String: MCPJSONValue].self
        ) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported JSON value."
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
}

extension JSONEncoder {
    static var sideRefreshMCP: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
