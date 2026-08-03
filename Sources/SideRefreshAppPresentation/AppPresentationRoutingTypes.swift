public enum AppPresentationCommand: Equatable, Sendable {
    case checkConnection
    case refresh
    case inspectInstalledApp
}

public enum AppPresentationConfirmation: Equatable, Sendable {
    case saveTargetChanges
    case enableAutomaticRenewal
    case installNow
}

public enum AppSystemHandoff: Equatable, Sendable {
    case backgroundItemsSettings
    case filesAndFoldersSettings
    case xcode
}

public enum AppPresentationRoute: Equatable, Sendable {
    case command(AppPresentationCommand)
    case confirmation(AppPresentationConfirmation)
    case destination(RenewalDestination)
    case systemHandoff(AppSystemHandoff)
}
