@testable import SideRefreshAppPresentation
import XCTest

final class SimpleWorkspaceNavigationPolicyTests: XCTestCase {
    func testPrimaryDestinationsNavigateInsideTheWorkspace() {
        XCTAssertEqual(
            SimpleWorkspaceNavigationPolicy.page(for: .settings),
            .settings
        )
        XCTAssertEqual(
            SimpleWorkspaceNavigationPolicy.page(for: .setup),
            .settings
        )
        XCTAssertEqual(
            SimpleWorkspaceNavigationPolicy.page(for: .help),
            .help
        )
        XCTAssertEqual(
            SimpleWorkspaceNavigationPolicy.page(for: .diagnostics),
            .diagnostics
        )
    }

    func testAdvancedSettingsRemainAnExplicitCompatibilityRoute() {
        XCTAssertNil(
            SimpleWorkspaceNavigationPolicy.page(
                for: .advancedSettings
            )
        )
    }

    func testFixturePreviewNavigationTracksEverySidebarSelection() {
        var navigation = SimpleWorkspaceFixtureNavigation(
            isInteractive: true
        )

        for page in SimpleWorkspacePage.allCases {
            navigation.select(page)
            XCTAssertEqual(navigation.selectedPage, page)
        }
    }

    func testFixtureCaptureNavigationRemainsOnHome() {
        var navigation = SimpleWorkspaceFixtureNavigation(
            isInteractive: false
        )

        navigation.select(.settings)

        XCTAssertEqual(navigation.selectedPage, .home)
    }

    func testAutomatedOutputOverridesInheritedPreviewIdentity() {
        XCTAssertFalse(
            SimpleWorkspaceFixturePresentationPolicy
                .showsPreviewIdentity(
                    previewRequested: true,
                    capturesOutput: true
                )
        )
    }

    func testInteractivePreviewShowsItsIdentity() {
        XCTAssertTrue(
            SimpleWorkspaceFixturePresentationPolicy
                .showsPreviewIdentity(
                    previewRequested: true,
                    capturesOutput: false
            )
        )
    }
}
