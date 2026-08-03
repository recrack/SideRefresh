@testable import SideRefreshAppPresentation
import XCTest

final class SimpleSettingsSavePresentationPolicyTests: XCTestCase {
    func testSuccessfulSaveClosesSettingsAndConfirmsOnHome() {
        XCTAssertEqual(
            SimpleSettingsSavePresentationPolicy.action(
                saveSucceeded: true
            ),
            .closeAndConfirm
        )
    }

    func testFailedSaveKeepsSettingsOpenForCorrection() {
        XCTAssertEqual(
            SimpleSettingsSavePresentationPolicy.action(
                saveSucceeded: false
            ),
            .stayOpen
        )
    }
}
