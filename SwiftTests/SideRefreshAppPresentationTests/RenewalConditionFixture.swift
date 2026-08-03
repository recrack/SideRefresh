@testable import SideRefreshAppPresentation

enum RenewalConditionFixture {
    typealias Scenario = (
        input: RenewalPresentationInput,
        action: RenewalNextAction?
    )

    static func scenario(for condition: RenewalCondition) -> Scenario {
        typealias Factory = RenewalPresentationTestFactory
        switch condition {
        case .initialSetupIncomplete:
            return (Factory.conditionInput(saved: false), .continueSetup)
        case .projectHandoffPending:
            return (
                Factory.conditionInput(handoff: true),
                .reviewSuggestedProject
            )
        case .compatibilityMigrationRequired:
            return (
                Factory.conditionInput(migration: true),
                .migrateConfiguration
            )
        case .targetChangesUnsaved:
            return (
                Factory.conditionInput(dirty: true),
                .reviewAndSaveChanges
            )
        case .automaticRenewalDisabled:
            return (
                Factory.conditionInput(automation: .notRegistered),
                .enableAutomaticRenewal
            )
        case .backgroundApprovalRequired:
            return (
                Factory.conditionInput(automation: .approvalRequired),
                .openBackgroundSettings
            )
        case .backgroundServiceUnavailable:
            return (
                Factory.conditionInput(automation: .helperMissing),
                .viewDiagnostics
            )
        case .healthy:
            return (Factory.conditionInput(), nil)
        case .due:
            return (Factory.conditionInput(due: true), .renewNow)
        case .expired:
            return (
                Factory.conditionInput(
                    expiration:
                        Factory.conditionNow
                            .addingTimeInterval(-1)
                ),
                .renewNow
            )
        case .running:
            return (
                Factory.conditionInput(
                    progress: RenewalPresentationProgress(
                        phase: .building,
                        message: "Building"
                    )
                ),
                nil
            )
        case .checkingConnection:
            return (
                Factory.conditionInput(connection: .checking),
                nil
            )
        case .connectionFailure:
            return (
                Factory.conditionInput(failure: .connection),
                .restoreConnection
            )
        case .buildOrSigningFailure:
            return (
                Factory.conditionInput(failure: .buildOrSigning),
                .retryRenewal
            )
        case .installationFailure:
            return (
                Factory.conditionInput(failure: .installation),
                .viewDiagnostics
            )
        case .installationEvidenceMissing:
            return (
                Factory.conditionInput(failure: .unverifiedInstallation),
                .inspectInstalledApp
            )
        case .permissionRequired:
            return (
                Factory.conditionInput(failure: .permission),
                .openPermissionSettings
            )
        case .checkFailed:
            return (
                Factory.conditionInput(failure: .unknown),
                .retryCheck
            )
        }
    }
}
