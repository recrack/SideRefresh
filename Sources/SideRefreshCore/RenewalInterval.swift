import Foundation

public enum RenewalIntervalError: LocalizedError, Equatable {
    case outsideSupportedRange(Int)

    public var errorDescription: String? {
        switch self {
        case .outsideSupportedRange(let hours):
            return "Renewal interval \(hours) is outside the supported 1...168 hour range."
        }
    }
}

public struct RenewalInterval: Codable, Equatable, Sendable {
    public static let supportedHours = 1...168
    public static let personalTeamDefault = RenewalInterval(
        validatedHours: 144
    )

    public let hours: Int

    public init(hours: Int) throws {
        guard Self.supportedHours.contains(hours) else {
            throw RenewalIntervalError.outsideSupportedRange(hours)
        }
        self.hours = hours
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(hours: container.decode(Int.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(hours)
    }

    public var timeInterval: TimeInterval {
        TimeInterval(hours) * 60 * 60
    }

    private init(validatedHours: Int) {
        hours = validatedHours
    }
}
