import AppKit
import SideRefreshAppPresentation

@MainActor
enum SideRefreshWindowLanguageCoordinator {
    static func refreshOpenWindowTitles() {
        for window in NSApp.windows {
            switch window.identifier?.rawValue {
            case "SideRefreshSimpleWorkspace":
                window.title = SideRefreshLocalization.string("앱 갱신")
            case "SideRefreshSimpleSettings":
                window.title = SideRefreshLocalization.string(
                    "SideRefresh 설정"
                )
            case "SideRefreshRenewalLog":
                window.title = SideRefreshLocalization.string(
                    "SideRefresh 상세 로그"
                )
            default:
                break
            }
        }
    }
}
