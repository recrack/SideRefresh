import SideRefreshAppPresentation
import XCTest

final class TailnetSetupPolicyTests: XCTestCase {
    func testMissingTailscaleBlocksAPreviouslySavedDevice() {
        XCTAssertEqual(
            TailnetSetupPolicy.requirement(
                executableIsAvailable: false,
                hasSelectedDevice: false,
                canReuseSavedDevice: true
            ),
            .installationRequired
        )
    }
}
