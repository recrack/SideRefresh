import SideRefreshAppPresentation

@MainActor
struct SideRefreshAppRouteHandlers {
    let confirmSave: () -> Void
    let confirmAutomaticRenewal: () -> Void
    let confirmInstall: () -> Void
    let openDestination: (RenewalDestination) -> Void
}

@MainActor
enum SideRefreshAppRouteExecutor {
    static func perform(
        _ route: AppPresentationRoute,
        model: SideRefreshViewModel,
        handlers: SideRefreshAppRouteHandlers
    ) {
        switch route {
        case .confirmation(.saveTargetChanges):
            handlers.confirmSave()
        case .confirmation(.enableAutomaticRenewal):
            handlers.confirmAutomaticRenewal()
        case .confirmation(.installNow):
            handlers.confirmInstall()
        case .command(.checkConnection):
            model.prepareConnectionCheck()
            switch model.connectionRoute {
            case .automatic:
                model.discoverCoreDevices()
            case .tailnet:
                model.discoverTailnetDevices()
            case .custom:
                handlers.openDestination(.advancedSettings)
            }
        case .command(.refresh):
            model.refresh()
        case .command(.inspectInstalledApp):
            model.inspectInstalledApp()
        case .destination(let destination):
            handlers.openDestination(destination)
        case .systemHandoff(.backgroundItemsSettings):
            model.openLoginItemSettings()
        case .systemHandoff(.filesAndFoldersSettings):
            model.openFilesAndFoldersPrivacySettings()
        case .systemHandoff(.xcode):
            model.openXcode()
        }
    }
}
