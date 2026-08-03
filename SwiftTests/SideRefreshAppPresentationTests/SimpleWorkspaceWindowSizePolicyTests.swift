@testable import SideRefreshAppPresentation
import XCTest

final class SimpleWorkspaceWindowSizePolicyTests: XCTestCase {
    func testOldNarrowFrameExpandsForTheFixedSidebar() {
        XCTAssertEqual(
            SimpleWorkspaceWindowSizePolicy.sizeAfterRestore(
                width: 680,
                height: 560
            ),
            SimpleWorkspaceWindowContentSize(
                width: 860,
                height: 560
            )
        )
    }

    func testLargerSavedFrameIsPreserved() {
        XCTAssertEqual(
            SimpleWorkspaceWindowSizePolicy.sizeAfterRestore(
                width: 1180,
                height: 820
            ),
            SimpleWorkspaceWindowContentSize(
                width: 1180,
                height: 820
            )
        )
    }
}
