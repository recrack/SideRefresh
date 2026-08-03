public enum SimpleSettingsSaveBarStatus: Equatable, Sendable {
    case incomplete
    case needsSave
    case saved
}

public enum SimpleSettingsSaveReadiness: Equatable, Sendable {
    case complete
    case appSelectionRequired
    case appConfigurationRequired
    case iphoneSelectionRequired
    case automationConfigurationRequired
    case tailscaleInstallationRequired
    case tailnetDeviceSelectionRequired

    var incompleteDetail: String? {
        switch self {
        case .complete:
            nil
        case .appSelectionRequired:
            "먼저 설치할 앱을 선택하세요."
        case .appConfigurationRequired:
            "선택한 앱의 Xcode 구성과 Apple 서명을 확인하세요."
        case .iphoneSelectionRequired:
            "먼저 설치할 iPhone을 선택하세요."
        case .automationConfigurationRequired:
            "자동화의 임시 빌드 폴더를 확인하세요."
        case .tailscaleInstallationRequired:
            "먼저 Mac에 Tailscale을 설치하고 로그인하세요."
        case .tailnetDeviceSelectionRequired:
            "먼저 Tailscale에서 사용할 iPhone을 찾아 선택하세요."
        }
    }
}

public struct SimpleSettingsSaveBarPresentation:
    Equatable,
    Sendable
{
    public let status: SimpleSettingsSaveBarStatus
    public let title: String
    public let detail: String
    public let actionTitle: String
    public let actionIsEnabled: Bool

    public static func resolve(
        hasSavedConfiguration: Bool,
        configurationIsDirty: Bool,
        readiness: SimpleSettingsSaveReadiness
    ) -> SimpleSettingsSaveBarPresentation {
        if let detail = readiness.incompleteDetail {
            return SimpleSettingsSaveBarPresentation(
                status: .incomplete,
                title: "설정 미완료",
                detail: detail,
                actionTitle: "설정 저장",
                actionIsEnabled: false
            )
        }
        if configurationIsDirty || !hasSavedConfiguration {
            return SimpleSettingsSaveBarPresentation(
                status: .needsSave,
                title: "저장 필요",
                detail: "선택한 앱·iPhone·연결 방식을 적용하려면 설정을 저장하세요.",
                actionTitle: hasSavedConfiguration
                    ? "변경사항 저장"
                    : "설정 저장",
                actionIsEnabled: true
            )
        }
        return SimpleSettingsSaveBarPresentation(
            status: .saved,
            title: "저장됨",
            detail: "현재 앱·iPhone·연결 방식이 저장되어 있습니다.",
            actionTitle: "설정 저장",
            actionIsEnabled: false
        )
    }
}
