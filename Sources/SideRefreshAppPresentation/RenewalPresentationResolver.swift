public enum RenewalPresentationResolver {
    public static func resolve(
        _ input: RenewalPresentationInput
    ) -> RenewalPresentation {
        RenewalPresentation(
            condition: condition(for: input),
            nextAction: nextAction(for: input),
            relationship:
                input.savedRelationship ?? input.draftRelationship,
            nextRenewalDate: input.nextRenewalDate,
            signingExpirationDate: input.evidence?.expiresAt,
            evidence: input.evidence,
            progress: input.progress,
            recentResult: input.recentResult,
            availableDestinations: input.availableDestinations
        )
    }

    private static func condition(
        for input: RenewalPresentationInput
    ) -> RenewalCondition {
        if input.progress != nil {
            return .running
        }
        if input.connection == .checking {
            return .checkingConnection
        }
        if let expiration = input.evidence?.expiresAt,
           expiration <= input.now
        {
            return .expired
        }
        if let failure = input.failure {
            return condition(for: failure)
        }
        if input.renewalIsDue {
            return input.connection == .unknown
                || input.connection == .unreachable
                ? .connectionFailure
                : .due
        }
        if input.projectHandoffPending {
            return .projectHandoffPending
        }
        if input.compatibilityNeedsMigration {
            return .compatibilityMigrationRequired
        }
        guard input.hasSavedConfiguration else {
            return .initialSetupIncomplete
        }
        guard input.hasCompleteTarget else {
            return .initialSetupIncomplete
        }
        if input.draftIsDirty {
            return .targetChangesUnsaved
        }
        guard input.executionIsEnabled else {
            return .initialSetupIncomplete
        }
        switch input.automation {
        case .notRegistered:
            return .automaticRenewalDisabled
        case .approvalRequired:
            return .backgroundApprovalRequired
        case .helperMissing, .unknown:
            return .backgroundServiceUnavailable
        case .enabled:
            break
        }
        if input.nextRenewalDate != nil,
           let evidence = input.evidence,
           evidence.expiresAt > input.now
        {
            return .healthy
        }
        return .due
    }
}
