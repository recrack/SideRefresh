@testable import SideRefreshAppPresentation
import XCTest

final class RenewalAutomationMethodTests: XCTestCase {
    func testDueDateIsDescribedAsEligibilityNotAnExactRunTime() {
        XCTAssertEqual(
            RenewalAutomationMethod.nextEligibilityTitle,
            "다음 갱신 가능 시각"
        )
    }
}
