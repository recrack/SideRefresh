@testable import SideRefreshAppPresentation
import XCTest

final class AppVersionPresentationTests: XCTestCase {
    func testSimpleVersionShowsOnlyTheUserFacingVersion() {
        XCTAssertEqual(
            AppIdentifierPresentation.appVersion(
                marketingVersion: " 1.4.0 "
            ),
            "1.4.0"
        )
        XCTAssertNil(
            AppIdentifierPresentation.appVersion(
                marketingVersion: " "
            )
        )
    }

    func testDetailedVersionLabelsTheBuildNumber() {
        XCTAssertEqual(
            AppIdentifierPresentation.appVersionDetail(
                marketingVersion: " 1.4.0 ",
                buildVersion: " 42 "
            ),
            "1.4.0 · 빌드 42"
        )
        XCTAssertEqual(
            AppIdentifierPresentation.appVersionDetail(
                marketingVersion: "1.4.0",
                buildVersion: " "
            ),
            "1.4.0"
        )
        XCTAssertNil(
            AppIdentifierPresentation.appVersionDetail(
                marketingVersion: " ",
                buildVersion: "42"
            )
        )
    }
}
