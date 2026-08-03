public extension RenewalAutomationMethod.Presentation {
    var backgroundTitle: String {
        switch background {
        case .enabled:
            return "백그라운드 켜짐"
        case .notRegistered:
            return "백그라운드 꺼짐"
        case .approvalRequired:
            return "승인 필요"
        case .helperMissing:
            return "실행 불가"
        case .unknown:
            return "확인 필요"
        }
    }

    var backgroundDetail: String? {
        switch background {
        case .enabled, .notRegistered:
            return nil
        case .approvalRequired:
            return "macOS에서 백그라운드 실행을 허용하세요"
        case .helperMissing:
            return "백그라운드 도구를 찾을 수 없습니다"
        case .unknown:
            return "백그라운드 상태를 확인할 수 없습니다"
        }
    }

    var executionTitle: String {
        switch configuration.execution {
        case .buildSignAndInstall:
            return "Xcode로 빌드·서명·설치"
        case .validationOnly:
            return "설정만 확인"
        }
    }

    var executionDetail: String? {
        configuration.execution == .validationOnly
            ? "빌드·서명·설치하지 않음"
            : nil
    }

    var connectionTitle: String {
        switch configuration.connection {
        case .xcodeAutomatic:
            return "Xcode/CoreDevice 자동 연결"
        case .tailnet:
            return "Xcode 연결 + Tailscale 주소 확인"
        case .directAddress:
            return "Xcode 직접 IP 연결"
        }
    }

    var connectionDetail: String {
        switch configuration.connection {
        case .xcodeAutomatic:
            return "USB 또는 Xcode가 사용할 수 있는 네트워크 경로"
        case .tailnet:
            return "Tailscale 온라인과 Xcode 연결은 별도 확인"
        case .directAddress:
            return "Xcode에서 IP 주소 연결이 먼저 필요함"
        }
    }

    var provenanceNotice: String? {
        switch provenance {
        case .saved:
            return nil
        case .savedWithPendingDraft:
            return "변경사항은 저장 후 반영됩니다."
        case .draftOnly:
            return "아직 저장되지 않은 방식입니다."
        }
    }
}
