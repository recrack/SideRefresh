import SideRefreshAppPresentation

extension RenewalCondition {
    var sideRefreshDetail: String {
        switch self {
        case .initialSetupIncomplete:
            return "갱신할 앱과 iPhone 설정을 완료하세요."
        case .projectHandoffPending:
            return "에이전트가 제안한 Xcode 프로젝트를 검토하세요."
        case .compatibilityMigrationRequired:
            return "기존 실행 명령을 iOS 앱 자동 갱신으로 이전하세요."
        case .targetChangesUnsaved:
            return "저장 전까지 이전 앱과 iPhone 설정을 사용합니다."
        case .automaticRenewalDisabled:
            return "저장한 대상의 백그라운드 갱신을 켜세요."
        case .backgroundApprovalRequired:
            return "macOS 설정에서 SideRefresh 실행을 허용하세요."
        case .backgroundServiceUnavailable:
            return "백그라운드 실행 파일과 상태를 확인하세요."
        case .healthy:
            return "만료 전에 선택한 앱을 다시 설치합니다."
        case .due:
            return "안전한 사용을 위해 앱을 다시 설치할 시점입니다."
        case .expired:
            return "Personal Team 서명이 만료되어 다시 설치해야 합니다."
        case .running:
            return "현재 갱신 단계를 완료할 때까지 기다려 주세요."
        case .checkingConnection:
            return "Xcode의 기기 목록 또는"
                + " 저장된 Tailscale 주소를 확인하고 있습니다."
        case .connectionFailure:
            return "선택한 iPhone의 연결을 복구한 뒤 다시 시도하세요."
        case .buildOrSigningFailure:
            return "Xcode에서 프로젝트와 Personal Team 서명을 확인하세요."
        case .installationFailure:
            return "실패 단계와 설치 로그를 확인하세요."
        case .installationEvidenceMissing:
            return "설치는 끝났지만 실제 서명 만료일을 확인하지 못했습니다."
        case .permissionRequired:
            return "필요한 macOS 접근 권한을 허용하세요."
        case .checkFailed:
            return "진단 로그를 확인하거나 상태 확인을 다시 시도하세요."
        }
    }
}
