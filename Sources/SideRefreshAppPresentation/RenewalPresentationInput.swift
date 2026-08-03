import Foundation

public struct RenewalPresentationInput: Equatable, Sendable {
    public let now: Date
    public let hasSavedConfiguration: Bool
    public let hasCompleteTarget: Bool
    public let executionIsEnabled: Bool
    public let draftIsDirty: Bool
    public let automation: BackgroundAutomationState
    public let connection: RenewalConnectionState
    public let renewalIsDue: Bool
    public let nextRenewalDate: Date?
    public let evidence: LastVerifiedEvidence?
    public let projectHandoffPending: Bool
    public let compatibilityNeedsMigration: Bool
    public let progress: RenewalPresentationProgress?
    public let failure: RenewalPresentationFailure?
    public let savedRelationship: RenewalRelationship?
    public let draftRelationship: RenewalRelationship?
    public let recentResult: RenewalRecentResult?
    public let availableDestinations: Set<RenewalDestination>

    public init(
        now: Date,
        hasSavedConfiguration: Bool = false,
        hasCompleteTarget: Bool = false,
        executionIsEnabled: Bool = true,
        draftIsDirty: Bool = false,
        automation: BackgroundAutomationState = .notRegistered,
        connection: RenewalConnectionState = .unknown,
        renewalIsDue: Bool = false,
        nextRenewalDate: Date? = nil,
        evidence: LastVerifiedEvidence? = nil,
        projectHandoffPending: Bool = false,
        compatibilityNeedsMigration: Bool = false,
        progress: RenewalPresentationProgress? = nil,
        failure: RenewalPresentationFailure? = nil,
        savedRelationship: RenewalRelationship? = nil,
        draftRelationship: RenewalRelationship? = nil,
        recentResult: RenewalRecentResult? = nil,
        availableDestinations: Set<RenewalDestination> = []
    ) {
        self.now = now
        self.hasSavedConfiguration = hasSavedConfiguration
        self.hasCompleteTarget = hasCompleteTarget
        self.executionIsEnabled = executionIsEnabled
        self.draftIsDirty = draftIsDirty
        self.automation = automation
        self.connection = connection
        self.renewalIsDue = renewalIsDue
        self.nextRenewalDate = nextRenewalDate
        self.evidence = evidence
        self.projectHandoffPending = projectHandoffPending
        self.compatibilityNeedsMigration = compatibilityNeedsMigration
        self.progress = progress
        self.failure = failure
        self.savedRelationship = savedRelationship
        self.draftRelationship = draftRelationship
        self.recentResult = recentResult
        self.availableDestinations = availableDestinations
    }
}
