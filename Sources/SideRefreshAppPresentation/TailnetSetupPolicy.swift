public enum TailnetSetupRequirement: Equatable, Sendable {
    case installationRequired
    case deviceSelectionRequired

    public var userMessage: String {
        switch self {
        case .installationRequired:
            return "Mac에서 사용할 수 있는 Tailscale 앱 또는 CLI를 찾지 못했습니다. Tailscale을 설치하고 로그인한 뒤 다시 확인하세요."
        case .deviceSelectionRequired:
            return "Tailscale에서 설치할 iPhone을 먼저 찾아 선택하세요."
        }
    }
}

public enum TailnetSetupPolicy {
    public static func requirement(
        executableIsAvailable: Bool,
        hasSelectedDevice: Bool,
        canReuseSavedDevice: Bool
    ) -> TailnetSetupRequirement? {
        guard executableIsAvailable else {
            return .installationRequired
        }
        guard hasSelectedDevice || canReuseSavedDevice else {
            return .deviceSelectionRequired
        }
        return nil
    }
}
