import AppKit

extension SideRefreshViewModel {
    var errorAlertTitle: String {
        guard case let .productKey(localizationKey)? =
                simpleErrorMessageContent
        else {
            return "오류"
        }
        if localizationKey.hasPrefix("Xcode에 Apple Account") {
            return "Xcode 로그인 필요"
        }
        if localizationKey.hasPrefix("이 앱의 iOS Development") {
            return "서명 프로필 준비 필요"
        }
        return "오류"
    }

    var errorOffersXcodeRecovery: Bool {
        errorAlertTitle != "오류"
    }

    func openXcode() {
        guard let xcodeURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: "com.apple.dt.Xcode"
        ) else {
            presentProductError("Xcode를 찾을 수 없습니다.")
            return
        }
        let configuration = NSWorkspace.OpenConfiguration()
        let containerPath = target.containerPath.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if FileManager.default.fileExists(atPath: containerPath) {
            NSWorkspace.shared.open(
                [URL(fileURLWithPath: containerPath)],
                withApplicationAt: xcodeURL,
                configuration: configuration,
                completionHandler: nil
            )
        } else {
            NSWorkspace.shared.openApplication(
                at: xcodeURL,
                configuration: configuration,
                completionHandler: nil
            )
        }
    }
}
