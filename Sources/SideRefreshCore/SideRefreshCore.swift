import Foundation

public struct RenewalStatus: Codable, Equatable, Sendable {
    public let isDue: Bool
    public let lastSuccessfulRenewal: Date?
    public let nextDue: Date?
    public let provisioningExpirationDate: Date?
    public let provisioningProfileIdentifier: String?
}

public struct RenewalSchedule: Sendable {
    private let interval: RenewalInterval

    public init(
        interval: RenewalInterval = .personalTeamDefault
    ) {
        self.interval = interval
    }

    public func status(
        lastSuccessfulRenewal: Date?,
        provisioningExpirationDate: Date? = nil,
        provisioningProfileIdentifier: String? = nil,
        now: Date = Date()
    ) -> RenewalStatus {
        guard let lastSuccessfulRenewal else {
            return RenewalStatus(
                isDue: true,
                lastSuccessfulRenewal: nil,
                nextDue: nil,
                provisioningExpirationDate:
                    provisioningExpirationDate,
                provisioningProfileIdentifier:
                    provisioningProfileIdentifier
            )
        }

        var nextDue = lastSuccessfulRenewal.addingTimeInterval(
            interval.timeInterval
        )
        if let provisioningExpirationDate {
            let renewBeforeExpiration =
                provisioningExpirationDate.addingTimeInterval(
                    -24 * 60 * 60
                )
            nextDue = min(nextDue, renewBeforeExpiration)
        }
        return RenewalStatus(
            isDue: now >= nextDue,
            lastSuccessfulRenewal: lastSuccessfulRenewal,
            nextDue: nextDue,
            provisioningExpirationDate:
                provisioningExpirationDate,
            provisioningProfileIdentifier:
                provisioningProfileIdentifier
        )
    }
}
