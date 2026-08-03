import SideRefreshAppPresentation

extension SideRefreshSimpleWorkspaceHost {
    func launchAction(
        for destination: RenewalDestination,
        control: SimpleWorkspaceControl
    ) -> SimpleSettingsLaunchAction {
        if destination == .settings {
            switch control {
            case .automationSettings:
                return .editAutomation
            case .connectionSettings:
                return .editConnection
            default:
                return .none
            }
        }
        guard destination == .setup else {
            return .none
        }
        switch control {
        case .selectApp:
            return .chooseApp
        case .selectIPhone:
            return .chooseIPhone
        default:
            return .setupAction(for: model)
        }
    }
}
