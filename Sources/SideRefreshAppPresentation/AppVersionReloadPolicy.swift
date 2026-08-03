public enum AppVersionReloadAction: Equatable, Sendable {
    case keep
    case clear
    case clearAndResolve(AppVersionResolutionRequest)
}

public enum AppVersionReloadPolicy {
    public static func action(
        previous: AppVersionResolutionRequest?,
        current: AppVersionResolutionRequest?
    ) -> AppVersionReloadAction {
        guard previous != current else {
            return .keep
        }
        guard let current else {
            return .clear
        }
        return .clearAndResolve(current)
    }
}
