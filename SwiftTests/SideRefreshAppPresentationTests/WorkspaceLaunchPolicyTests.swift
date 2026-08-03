@testable import SideRefreshAppPresentation
import XCTest

final class WorkspaceLaunchPolicyTests: XCTestCase {
    func testNormalLaunchSelectsSimpleWorkspace() {
        XCTAssertEqual(
            WorkspaceLaunchPolicy.normalLaunchWorkspace,
            .simple
        )
    }

    func testMenuBarPrimaryActionReturnsToSimpleWorkspace() {
        XCTAssertEqual(
            WorkspaceLaunchPolicy.menuBarWorkspace,
            WorkspaceLaunchPolicy.normalLaunchWorkspace
        )
    }
}
