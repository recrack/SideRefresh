import SideRefreshAppPresentation

extension RenewalRelationship {
    var simpleWorkspaceAccessibilityLabel: String {
        var app = appName
        if let identifier = AppIdentifierPresentation.detail(
            bundleIdentifier
        ) {
            app = SideRefreshLocalization.format(
                "%@, 앱 식별자 %@",
                app,
                identifier
            )
        }
        if let appVersion {
            app = SideRefreshLocalization.format(
                "%@, 버전 %@",
                app,
                appVersion
            )
        }
        var iPhone = iPhoneName
        if let version = AppIdentifierPresentation.iPhoneDetail(
            operatingSystemVersion: iPhoneOperatingSystemVersion
        ) {
            iPhone += ", \(version)"
        }
        return SideRefreshLocalization.format(
            "%@ 앱을 %@에 빌드, 서명, 설치하여 유지합니다.",
            app,
            iPhone
        )
    }
}
