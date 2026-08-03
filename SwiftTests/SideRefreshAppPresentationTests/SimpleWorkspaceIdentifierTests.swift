@testable import SideRefreshAppPresentation
import XCTest

final class SimpleWorkspaceIdentifierTests: XCTestCase {
    func testSemanticIdentifiersStayStableAndUnique() {
        XCTAssertEqual(
            SimpleWorkspaceRegion.allCases.map(\.rawValue),
            [
                "simple.brand",
                "simple.navigation",
                "simple.current-app",
                "simple.condition",
                "simple.next-action",
                "simple.relationship",
                "simple.timing",
                "simple.last-verified",
                "simple.progress",
                "simple.recent-result",
            ]
        )
        XCTAssertEqual(
            SimpleWorkspaceControl.allCases.map(\.rawValue),
            [
                "simple.control.next-action",
                "simple.relationship.select-app",
                "simple.relationship.select-iphone",
                "simple.automation.background-settings",
                "simple.automation.connection-settings",
                "simple.secondary.manual-renewal",
                "simple.destination.settings",
                "simple.destination.help",
                "simple.destination.diagnostics",
            ]
        )
        XCTAssertEqual(
            SimpleWorkspaceAccessibility.workspace,
            "simple.workspace"
        )
        XCTAssertEqual(
            SimpleWorkspaceAccessibility.sidebarHome,
            "simple.navigation.home"
        )
        XCTAssertEqual(
            SimpleWorkspaceAccessibility.fixtureRoute,
            "simple.fixture.route"
        )
        let identifiers =
            SimpleWorkspaceRegion.allCases.map(\.rawValue)
            + SimpleWorkspaceControl.allCases.map(\.rawValue)
            + [
                SimpleWorkspaceAccessibility.workspace,
                SimpleWorkspaceAccessibility.sidebarHome,
                SimpleWorkspaceAccessibility.fixtureRoute,
            ]

        XCTAssertEqual(Set(identifiers).count, identifiers.count)
        XCTAssertTrue(identifiers.allSatisfy { $0.hasPrefix("simple.") })
    }
}
