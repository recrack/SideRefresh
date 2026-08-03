enum SimpleSettingsLaunchAction: Equatable {
    case none
    case chooseApp
    case chooseIPhone
    case editAutomation
    case editConnection

    @MainActor
    static func setupAction(
        for model: SideRefreshViewModel
    ) -> SimpleSettingsLaunchAction {
        guard model.hasGuidedTarget else {
            return .chooseApp
        }
        switch model.missingTargetRequiredField?.setupArea {
        case .app:
            return .chooseApp
        case .iphone:
            return .chooseIPhone
        case .automation, nil:
            return .none
        }
    }
}

enum SimpleSettingsSection: String, Hashable {
    case automation
    case connection
}

extension SimpleSettingsLaunchAction {
    var settingsSection: SimpleSettingsSection? {
        switch self {
        case .editAutomation:
            return .automation
        case .editConnection:
            return .connection
        case .none, .chooseApp, .chooseIPhone:
            return nil
        }
    }
}

struct SimpleSettingsLaunchRequest: Equatable {
    let action: SimpleSettingsLaunchAction
    let generation: Int
}
