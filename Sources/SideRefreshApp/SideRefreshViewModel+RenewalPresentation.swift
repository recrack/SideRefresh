import Foundation
import SideRefreshAppPresentation

extension SideRefreshViewModel {
    var renewalPresentation: RenewalPresentation {
        let now = Date()
        return RenewalPresentationResolver.resolve(
            RenewalPresentationInput(
                now: now,
                hasSavedConfiguration: isConfigured,
                hasCompleteTarget: RenewalTargetCompletenessPolicy
                    .isComplete(
                        configurationIsDirty: configurationIsDirty,
                        draftIsComplete: target.isComplete,
                        savedIsComplete:
                            savedRenewalTarget?.isComplete == true
                    ),
                executionIsEnabled: renewalMode == .execute,
                draftIsDirty: configurationIsDirty,
                automation: backgroundAutomationPresentationState,
                connection: renewalPresentationConnection,
                renewalIsDue: isConfigured
                    && savedRenewalTarget?.isComplete == true
                    && !configurationIsDirty
                    && (
                        nextRenewalDate.map { $0 <= now }
                            ?? (lastSuccessfulRenewal == nil)
                    ),
                nextRenewalDate: nextRenewalDate,
                evidence: renewalPresentationEvidence,
                compatibilityNeedsMigration:
                    isConfigured && !hasGuidedTarget,
                progress: renewalPresentationProgress,
                failure: renewalPresentationFailure,
                savedRelationship: renewalPresentationRelationship,
                draftRelationship: renewalDraftRelationship,
                recentResult: renewalPresentationRecentResult,
                availableDestinations: renewalPresentationDestinations
            )
        )
    }

    var renewalPresentationDestinations: Set<RenewalDestination> {
        [.setup, .settings, .advancedSettings, .diagnostics, .help]
    }

    var renewalPresentationEvidence: LastVerifiedEvidence? {
        guard let installedAt = lastSuccessfulRenewal,
              let expiresAt = provisioningExpirationDate
        else {
            return nil
        }
        return LastVerifiedEvidence(
            installedAt: installedAt,
            expiresAt: expiresAt
        )
    }

}
