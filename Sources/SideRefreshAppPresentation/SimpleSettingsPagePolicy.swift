public enum SimpleSettingsPage: Equatable, Sendable {
    case overview
    case appSelection
    case iPhoneSelection
}

public enum SimpleSettingsPagePolicy {
    public static func page(
        for control: SimpleWorkspaceControl
    ) -> SimpleSettingsPage {
        switch control {
        case .selectApp:
            return .appSelection
        case .selectIPhone:
            return .iPhoneSelection
        default:
            return .overview
        }
    }
}
