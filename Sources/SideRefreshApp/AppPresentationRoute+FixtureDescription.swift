#if DEBUG
import SideRefreshAppPresentation

extension AppPresentationRoute {
    var fixtureDescription: String {
        switch self {
        case .command(.checkConnection):
            return "command.check-connection"
        case .command(.refresh):
            return "command.refresh"
        case .command(.inspectInstalledApp):
            return "command.inspect-installed-app"
        case .confirmation(.saveTargetChanges):
            return "confirmation.save-target"
        case .confirmation(.enableAutomaticRenewal):
            return "confirmation.enable-automation"
        case .confirmation(.installNow):
            return "confirmation.install-now"
        case .destination(.setup):
            return "destination.setup"
        case .destination(.settings):
            return "destination.settings"
        case .destination(.advancedSettings):
            return "destination.advanced-settings"
        case .destination(.diagnostics):
            return "destination.diagnostics"
        case .destination(.help):
            return "destination.help"
        case .systemHandoff(.backgroundItemsSettings):
            return "system.background-items"
        case .systemHandoff(.filesAndFoldersSettings):
            return "system.files-and-folders"
        case .systemHandoff(.xcode):
            return "system.xcode"
        }
    }
}
#endif
