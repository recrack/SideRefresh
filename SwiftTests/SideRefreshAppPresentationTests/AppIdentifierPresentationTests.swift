@testable import SideRefreshAppPresentation
import XCTest

final class AppIdentifierPresentationTests: XCTestCase {
    func testAppDetailShowsIdentifierAndVersionWithoutABundleIDLabel() {
        XCTAssertEqual(
            AppIdentifierPresentation.appDetail(
                bundleIdentifier: "  com.example.agentapp  ",
                appVersion: "1.4.0"
            ),
            "com.example.agentapp\n버전 1.4.0"
        )
    }

    func testIPhoneDetailShowsTheOperatingSystemVersion() {
        XCTAssertEqual(
            AppIdentifierPresentation.iPhoneDetail(
                operatingSystemVersion: " 26.5 "
            ),
            "iOS 26.5"
        )
    }

    func testDetailsHideMissingValuesWithoutDanglingSeparators() {
        XCTAssertEqual(
            AppIdentifierPresentation.appDetail(
                bundleIdentifier: "com.example.app",
                appVersion: nil
            ),
            "com.example.app"
        )
        XCTAssertEqual(
            AppIdentifierPresentation.appDetail(
                bundleIdentifier: nil,
                appVersion: "1.4.0"
            ),
            "버전 1.4.0"
        )
        XCTAssertEqual(
            AppIdentifierPresentation.appDetail(
                bundleIdentifier: "com.example.app",
                appVersion: "  "
            ),
            "com.example.app"
        )
        XCTAssertNil(
            AppIdentifierPresentation.appDetail(
                bundleIdentifier: nil,
                appVersion: nil
            )
        )
        XCTAssertNil(
            AppIdentifierPresentation.iPhoneDetail(
                operatingSystemVersion: "  "
            )
        )
    }
}
