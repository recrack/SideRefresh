@testable import SideRefreshAppPresentation
import XCTest

final class SimpleWorkspacePageLayoutPolicyTests: XCTestCase {
    func testEverySidebarPageUsesTheSameHeaderGeometry() {
        let metrics = SimpleWorkspacePage.allCases.map {
            SimpleWorkspacePageLayoutPolicy.metrics(for: $0)
        }

        XCTAssertEqual(Set(metrics).count, 1)
        XCTAssertEqual(
            metrics.first,
            SimpleWorkspacePageLayoutMetrics(
                horizontalPadding: 32,
                verticalPadding: 18,
                minimumContentHeight: 50,
                maximumContentWidth: 880
            )
        )
    }

    func testEverySidebarPageHasAStableHeaderIdentifier() {
        let identifiers = SimpleWorkspacePage.allCases.map {
            SimpleWorkspacePageLayoutPolicy.headerIdentifier(for: $0)
        }

        XCTAssertEqual(
            identifiers,
            [
                "simple.page-header.home",
                "simple.page-header.settings",
                "simple.page-header.help",
                "simple.page-header.diagnostics",
            ]
        )
        XCTAssertEqual(Set(identifiers).count, identifiers.count)
    }
}
