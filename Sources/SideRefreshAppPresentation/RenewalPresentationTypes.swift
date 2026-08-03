public enum BackgroundAutomationState: Equatable, Sendable {
    case notRegistered
    case enabled
    case approvalRequired
    case helperMissing
    case unknown
}

public enum RenewalConnectionState: Equatable, Sendable {
    case unknown
    case checking
    case reachable
    case unreachable
    case availableForAttempt
}

public enum RenewalConnectionEvidence: Equatable, Sendable {
    case absent
    case verifiedReachable
    case verifiedUnreachable
    case routeAvailable
}

public enum RenewalCondition: CaseIterable, Equatable, Sendable {
    case initialSetupIncomplete
    case projectHandoffPending
    case compatibilityMigrationRequired
    case targetChangesUnsaved
    case automaticRenewalDisabled
    case backgroundApprovalRequired
    case backgroundServiceUnavailable
    case healthy
    case due
    case expired
    case running
    case checkingConnection
    case connectionFailure
    case buildOrSigningFailure
    case installationFailure
    case installationEvidenceMissing
    case permissionRequired
    case checkFailed
}

public enum RenewalNextAction: CaseIterable, Equatable, Sendable {
    case continueSetup
    case reviewSuggestedProject
    case migrateConfiguration
    case reviewAndSaveChanges
    case enableAutomaticRenewal
    case openBackgroundSettings
    case renewNow
    case retryRenewal
    case checkConnection
    case restoreConnection
    case fixInXcode
    case inspectInstalledApp
    case openPermissionSettings
    case retryCheck
    case viewDiagnostics
}

public enum RenewalPresentationFailure: Equatable, Sendable {
    case connection
    case buildOrSigning
    case installation
    case unverifiedInstallation
    case permission
    case unknown
}

public enum RenewalRecentOutcome: Equatable, Sendable {
    case verified
    case failed(RenewalPresentationFailure)
}

public enum RenewalDestination: CaseIterable, Hashable, Sendable {
    case setup
    case settings
    case advancedSettings
    case diagnostics
    case help
}
