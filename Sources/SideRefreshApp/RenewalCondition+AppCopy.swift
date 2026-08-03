import SideRefreshAppPresentation

extension RenewalCondition {
    var sideRefreshTitle: String {
        switch self {
        case .initialSetupIncomplete:
            return "설정을 완료하세요"
        case .projectHandoffPending:
            return "제안된 프로젝트 검토 필요"
        case .compatibilityMigrationRequired:
            return "기존 설정 이전 필요"
        case .targetChangesUnsaved:
            return "변경사항 저장 필요"
        case .automaticRenewalDisabled:
            return "자동 갱신 꺼짐"
        case .backgroundApprovalRequired:
            return "macOS 백그라운드 실행 허용 필요"
        case .backgroundServiceUnavailable:
            return "백그라운드 상태 확인 필요"
        case .healthy:
            return "자동 갱신 준비됨"
        case .due:
            return "갱신 필요"
        case .expired:
            return "서명 만료됨"
        case .running:
            return "갱신 중"
        case .checkingConnection:
            return "iPhone 연결 확인 중"
        case .connectionFailure:
            return "iPhone 연결 확인 필요"
        case .buildOrSigningFailure:
            return "빌드 또는 서명 확인 필요"
        case .installationFailure:
            return "iPhone 설치 실패"
        case .installationEvidenceMissing:
            return "서명 만료일 확인 필요"
        case .permissionRequired:
            return "macOS 권한 필요"
        case .checkFailed:
            return "현재 상태 확인 실패"
        }
    }
}
