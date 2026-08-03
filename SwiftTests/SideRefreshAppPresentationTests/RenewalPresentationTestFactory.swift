import Foundation
@testable import SideRefreshAppPresentation

enum RenewalPresentationTestFactory {
    static let conditionNow = Date(timeIntervalSince1970: 50_000)

    static func input(
        now: Date,
        progress: RenewalPresentationProgress? = nil,
        failure: RenewalPresentationFailure? = nil,
        evidence: LastVerifiedEvidence? = nil,
        relationship: RenewalRelationship? = nil,
        recentResult: RenewalRecentResult? = nil,
        destinations: Set<RenewalDestination> = []
    ) -> RenewalPresentationInput {
        RenewalPresentationInput(
            now: now,
            hasSavedConfiguration: true,
            hasCompleteTarget: true,
            automation: .enabled,
            connection: .reachable,
            nextRenewalDate: now.addingTimeInterval(500),
            evidence: evidence,
            progress: progress,
            failure: failure,
            savedRelationship: relationship,
            recentResult: recentResult,
            availableDestinations: destinations
        )
    }

    static func conditionInput(
        saved: Bool = true,
        complete: Bool = true,
        dirty: Bool = false,
        automation: BackgroundAutomationState = .enabled,
        due: Bool = false,
        expiration: Date? = nil,
        handoff: Bool = false,
        migration: Bool = false,
        progress: RenewalPresentationProgress? = nil,
        connection: RenewalConnectionState = .reachable,
        failure: RenewalPresentationFailure? = nil
    ) -> RenewalPresentationInput {
        let expiresAt =
            expiration ?? conditionNow.addingTimeInterval(1_000)
        return RenewalPresentationInput(
            now: conditionNow,
            hasSavedConfiguration: saved,
            hasCompleteTarget: complete,
            draftIsDirty: dirty,
            automation: automation,
            connection: connection,
            renewalIsDue: due,
            nextRenewalDate:
                conditionNow.addingTimeInterval(500),
            evidence: LastVerifiedEvidence(
                installedAt: conditionNow.addingTimeInterval(-500),
                expiresAt: expiresAt
            ),
            projectHandoffPending: handoff,
            compatibilityNeedsMigration: migration,
            progress: progress,
            failure: failure
        )
    }
}
