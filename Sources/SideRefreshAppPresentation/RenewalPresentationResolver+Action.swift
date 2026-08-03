extension RenewalPresentationResolver {
    static func nextAction(
        for input: RenewalPresentationInput
    ) -> RenewalNextAction? {
        if input.progress != nil {
            return nil
        }
        if input.connection == .checking {
            return nil
        }
        if input.projectHandoffPending {
            return .reviewSuggestedProject
        }
        if input.compatibilityNeedsMigration {
            return .migrateConfiguration
        }
        if !input.hasSavedConfiguration {
            return .continueSetup
        }
        if !input.hasCompleteTarget {
            return .continueSetup
        }
        if input.draftIsDirty {
            return .reviewAndSaveChanges
        }
        if !input.executionIsEnabled {
            return .continueSetup
        }
        if let failure = input.failure {
            return nextAction(for: failure)
        }
        if input.renewalIsDue
            || input.evidence == nil
            || input.nextRenewalDate == nil
            || (input.evidence?.expiresAt ?? .distantFuture) <= input.now
        {
            return input.connection == .reachable
                || input.connection == .availableForAttempt
                ? .renewNow
                : .checkConnection
        }
        switch input.automation {
        case .notRegistered:
            return .enableAutomaticRenewal
        case .approvalRequired:
            return .openBackgroundSettings
        case .helperMissing, .unknown:
            return .viewDiagnostics
        case .enabled:
            break
        }
        return nil
    }

    private static func nextAction(
        for failure: RenewalPresentationFailure
    ) -> RenewalNextAction {
        switch failure {
        case .connection:
            return .restoreConnection
        case .buildOrSigning:
            return .retryRenewal
        case .installation:
            return .viewDiagnostics
        case .unverifiedInstallation:
            return .inspectInstalledApp
        case .permission:
            return .openPermissionSettings
        case .unknown:
            return .retryCheck
        }
    }
}
