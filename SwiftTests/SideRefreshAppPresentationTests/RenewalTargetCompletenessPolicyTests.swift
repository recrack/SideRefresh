@testable import SideRefreshAppPresentation
import XCTest

final class RenewalTargetCompletenessPolicyTests: XCTestCase {
    func testDirtyConfigurationProjectsDraftCompleteness() {
        XCTAssertTrue(
            RenewalTargetCompletenessPolicy.isComplete(
                configurationIsDirty: true,
                draftIsComplete: true,
                savedIsComplete: false
            )
        )
        XCTAssertFalse(
            RenewalTargetCompletenessPolicy.isComplete(
                configurationIsDirty: true,
                draftIsComplete: false,
                savedIsComplete: true
            )
        )
    }

    func testCleanConfigurationProjectsSavedCompleteness() {
        XCTAssertTrue(
            RenewalTargetCompletenessPolicy.isComplete(
                configurationIsDirty: false,
                draftIsComplete: false,
                savedIsComplete: true
            )
        )
    }
}
