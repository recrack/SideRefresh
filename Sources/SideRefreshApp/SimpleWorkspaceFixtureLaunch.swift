#if DEBUG
import Foundation
import SideRefreshAppPresentation

@MainActor
enum SimpleWorkspaceFixtureLaunch {
    static let environmentKey = "SIDEREFRESH_UI_FIXTURE"

    static var request: SimpleWorkspaceFixtureLaunchRequest {
        SimpleWorkspaceFixtureLaunchRequest.resolve(
            ProcessInfo.processInfo.environment[environmentKey],
            captureRequested: SimpleWorkspaceFixtureCapture.isRequested
        )
    }
}
#endif
