import Foundation

public struct IOSAppRenewalEvidence: Codable, Equatable, Sendable {
    public let identifier: String
    public let renewedAt: Date

    public init() {
        self.init(renewedAt: Date(), uuid: UUID())
    }

    public init(renewedAt: Date, uuid: UUID) {
        let compactUUID = uuid.uuidString
            .replacingOccurrences(of: "-", with: "")
            .prefix(12)
            .uppercased()
        identifier = "SR-\(compactUUID)"
        self.renewedAt = renewedAt
    }

    public var renewedAtBuildSetting: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: renewedAt)
    }
}
