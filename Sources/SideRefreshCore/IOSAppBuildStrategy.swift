public enum IOSAppBuildStrategy:
    String,
    Codable,
    CaseIterable,
    Equatable,
    Sendable
{
    case incremental
    case cleanRebuild = "clean-rebuild"

    var xcodebuildActions: [String] {
        switch self {
        case .incremental:
            return ["build"]
        case .cleanRebuild:
            return ["clean", "build"]
        }
    }
}
