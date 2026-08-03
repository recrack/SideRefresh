public enum SimpleSettingsSavePresentationAction:
    Equatable,
    Sendable
{
    case stayOpen
    case closeAndConfirm
}

public enum SimpleSettingsSavePresentationPolicy {
    public static func action(
        saveSucceeded: Bool
    ) -> SimpleSettingsSavePresentationAction {
        saveSucceeded ? .closeAndConfirm : .stayOpen
    }
}
