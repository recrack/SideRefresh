import SideRefreshAppPresentation

extension RenewalNextAction {
    var sideRefreshTitle: String {
        switch self {
        case .continueSetup:
            return "설정 계속"
        case .reviewSuggestedProject:
            return "제안된 프로젝트 검토"
        case .migrateConfiguration:
            return "설정 이전"
        case .reviewAndSaveChanges:
            return "변경사항 검토 및 저장"
        case .enableAutomaticRenewal:
            return "자동 갱신 켜기"
        case .openBackgroundSettings:
            return "백그라운드 실행 허용"
        case .renewNow:
            return "지금 갱신"
        case .retryRenewal:
            return "다시 빌드 및 설치"
        case .checkConnection:
            return "연결 확인"
        case .restoreConnection:
            return "연결 복구"
        case .fixInXcode:
            return "Xcode에서 수정"
        case .inspectInstalledApp:
            return "설치된 앱 확인"
        case .openPermissionSettings:
            return "macOS 권한 열기"
        case .retryCheck:
            return "상태 다시 확인"
        case .viewDiagnostics:
            return "진단 로그 보기"
        }
    }
}
