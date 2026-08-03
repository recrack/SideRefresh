@testable import SideRefreshAppPresentation
import XCTest

final class SimpleWorkspaceSemanticModelTests: XCTestCase {
    func testHealthyFixtureHasFixedOrderWithoutNextAction() {
        let semantics = semantics(for: .healthy)

        XCTAssertEqual(
            semantics.orderedRegions,
            [.condition, .relationship, .timing, .evidence, .recentResult]
        )
        XCTAssertNil(semantics.nextActionRoute)
        XCTAssertEqual(
            semantics.manualRenewalRoute,
            .confirmation(.installNow)
        )
        XCTAssertEqual(
            semantics.focusOrder,
            [
                .selectApp,
                .selectIPhone,
                .automationSettings,
                .connectionSettings,
                .manualRenewal,
                .settings,
                .help,
                .diagnostics,
            ]
        )
    }

    func testActionableFixtureFocusesItsSemanticRouteFirst() {
        let semantics = semantics(for: .due)

        XCTAssertEqual(
            semantics.nextActionRoute,
            .confirmation(.installNow)
        )
        XCTAssertNil(semantics.manualRenewalRoute)
        XCTAssertEqual(semantics.focusOrder.first, .nextAction)
        XCTAssertEqual(
            semantics.orderedRegions.prefix(2),
            [.condition, .nextAction]
        )
    }

    func testProgressOwnsTheActivitySlot() {
        let semantics = semantics(for: .running)

        XCTAssertTrue(semantics.orderedRegions.contains(.progress))
        XCTAssertFalse(semantics.orderedRegions.contains(.recentResult))
        XCTAssertNil(semantics.nextActionRoute)
    }

    func testFixtureRoutesUseTheProductionCoordinatorContract() {
        let expected: [SimpleWorkspaceFixture: AppPresentationRoute?] = [
            .healthy: nil,
            .initialSetup: .destination(.setup),
            .dirtyTarget: .confirmation(.saveTargetChanges),
            .due: .confirmation(.installNow),
            .running: nil,
            .failureWithEvidence: .confirmation(.installNow),
        ]

        for fixture in SimpleWorkspaceFixture.allCases {
            let presentation =
                SimpleWorkspaceFixtureAdapter.presentation(for: fixture)
            XCTAssertEqual(
                SimpleWorkspaceSemanticModel(
                    presentation
                ).nextActionRoute,
                expected[fixture]!
            )
            XCTAssertEqual(
                SimpleWorkspaceSemanticModel(
                    presentation
                ).nextActionRoute,
                AppPresentationCoordinator.route(for: presentation)
            )
        }
    }

    private func semantics(
        for fixture: SimpleWorkspaceFixture
    ) -> SimpleWorkspaceSemanticModel {
        SimpleWorkspaceSemanticModel(
            SimpleWorkspaceFixtureAdapter.presentation(for: fixture)
        )
    }
}
