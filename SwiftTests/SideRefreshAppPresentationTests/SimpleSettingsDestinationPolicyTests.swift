@testable import SideRefreshAppPresentation
import XCTest

final class SimpleSettingsDestinationPolicyTests: XCTestCase {
    func testNormalSettingsAndSetupStayInSimpleWorkspace() {
        XCTAssertEqual(
            SimpleSettingsDestinationPolicy.surface(for: .settings),
            .simpleSettings
        )
        XCTAssertEqual(
            SimpleSettingsDestinationPolicy.surface(for: .setup),
            .simpleSettings
        )
    }

    func testTechnicalAndDiagnosticDestinationsRemainExplicit() {
        XCTAssertEqual(
            SimpleSettingsDestinationPolicy.surface(
                for: .advancedSettings
            ),
            .legacySettings
        )
        XCTAssertEqual(
            SimpleSettingsDestinationPolicy.surface(for: .help),
            .legacySettings
        )
        XCTAssertEqual(
            SimpleSettingsDestinationPolicy.surface(for: .diagnostics),
            .diagnostics
        )
    }

    func testSelectionControlsOpenMatchingInWindowPages() {
        XCTAssertEqual(
            SimpleSettingsPagePolicy.page(
                for: .selectApp
            ),
            .appSelection
        )
        XCTAssertEqual(
            SimpleSettingsPagePolicy.page(
                for: .selectIPhone
            ),
            .iPhoneSelection
        )
    }
}
