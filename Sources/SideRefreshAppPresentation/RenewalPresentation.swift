import Foundation

public struct RenewalPresentation: Equatable, Sendable {
    public let condition: RenewalCondition
    public let nextAction: RenewalNextAction?
    public let relationship: RenewalRelationship?
    public let nextRenewalDate: Date?
    public let signingExpirationDate: Date?
    public let evidence: LastVerifiedEvidence?
    public let progress: RenewalPresentationProgress?
    public let recentResult: RenewalRecentResult?
    public let availableDestinations: Set<RenewalDestination>

    public init(
        condition: RenewalCondition,
        nextAction: RenewalNextAction?,
        relationship: RenewalRelationship?,
        nextRenewalDate: Date?,
        signingExpirationDate: Date?,
        evidence: LastVerifiedEvidence?,
        progress: RenewalPresentationProgress?,
        recentResult: RenewalRecentResult?,
        availableDestinations: Set<RenewalDestination>
    ) {
        self.condition = condition
        self.nextAction = nextAction
        self.relationship = relationship
        self.nextRenewalDate = nextRenewalDate
        self.signingExpirationDate = signingExpirationDate
        self.evidence = evidence
        self.progress = progress
        self.recentResult = recentResult
        self.availableDestinations = availableDestinations
    }
}
