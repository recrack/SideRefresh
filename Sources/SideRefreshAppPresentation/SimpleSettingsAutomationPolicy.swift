public enum SimpleSettingsAutomationAction: Equatable, Hashable, Sendable {
    case enable
    case disable
    case openApproval
    case saveFirst
    case viewDiagnostics
}

public enum SimpleSettingsAutomationPolicy {
    public static func actions(
        for state: BackgroundAutomationState,
        canRegister: Bool
    ) -> [SimpleSettingsAutomationAction] {
        switch state {
        case .enabled:
            return [.disable]
        case .approvalRequired:
            return [.disable, .openApproval]
        case .notRegistered:
            return canRegister ? [.enable] : [.saveFirst]
        case .helperMissing, .unknown:
            return [.viewDiagnostics]
        }
    }
}
