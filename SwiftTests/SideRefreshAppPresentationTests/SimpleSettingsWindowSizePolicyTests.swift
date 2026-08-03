import SideRefreshAppPresentation
import XCTest

final class SimpleSettingsWindowSizePolicyTests: XCTestCase {
    func testCollapsedSavedSizeUsesTheCanonicalSettingsSize() {
        XCTAssertEqual(
            SimpleSettingsWindowSizePolicy.sizeAfterRestore(
                width: 317,
                height: 32
            ),
            SimpleSettingsWindowContentSize(
                width: 760,
                height: 720
            )
        )
    }

    func testFormerMinimumIsUpgradedToTheCanonicalSettingsSize() {
        XCTAssertEqual(
            SimpleSettingsWindowSizePolicy.sizeAfterRestore(
                width: 640,
                height: 560
            ),
            SimpleSettingsWindowContentSize(
                width: 760,
                height: 720
            )
        )
    }

    func testUsableSavedSizeIsPreserved() {
        XCTAssertEqual(
            SimpleSettingsWindowSizePolicy.sizeAfterRestore(
                width: 920,
                height: 760
            ),
            SimpleSettingsWindowContentSize(
                width: 920,
                height: 760
            )
        )
    }
}
