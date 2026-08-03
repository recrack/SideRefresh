public enum AppPresentationCoordinator {
    public static func route(
        for presentation: RenewalPresentation
    ) -> AppPresentationRoute? {
        guard let action = presentation.nextAction else {
            return nil
        }
        let route = route(for: action)
        if case .destination(let destination) = route,
           !presentation.availableDestinations.contains(destination)
        {
            return nil
        }
        return route
    }

    public static func route(
        for action: RenewalNextAction
    ) -> AppPresentationRoute {
        switch action {
        case .continueSetup, .reviewSuggestedProject:
            return .destination(.setup)
        case .migrateConfiguration:
            return .destination(.advancedSettings)
        case .reviewAndSaveChanges:
            return .confirmation(.saveTargetChanges)
        case .enableAutomaticRenewal:
            return .confirmation(.enableAutomaticRenewal)
        case .openBackgroundSettings:
            return .systemHandoff(.backgroundItemsSettings)
        case .renewNow, .retryRenewal:
            return .confirmation(.installNow)
        case .checkConnection, .restoreConnection:
            return .command(.checkConnection)
        case .fixInXcode:
            return .systemHandoff(.xcode)
        case .inspectInstalledApp:
            return .command(.inspectInstalledApp)
        case .openPermissionSettings:
            return .systemHandoff(.filesAndFoldersSettings)
        case .retryCheck:
            return .command(.refresh)
        case .viewDiagnostics:
            return .destination(.diagnostics)
        }
    }
}
