import Foundation
import SideRefreshAppPresentation
import SideRefreshCore
import XCTest

final class ProjectSearchAccessSummaryTests: XCTestCase {
    func testReadySummaryCountsSearchableLocations() {
        let summary = ProjectSearchAccessSummary(
            locations: [
                location(.allowed, index: 0),
                location(.allowed, index: 1),
                location(.selectionRequired, index: 2),
                location(.missing, index: 3),
            ]
        )

        XCTAssertEqual(summary.state, .ready)
        XCTAssertEqual(summary.searchableCount, 2)
        XCTAssertEqual(summary.actionRequiredCount, 0)
        XCTAssertEqual(summary.optionalLocationCount, 1)
        XCTAssertEqual(summary.blockedCount, 0)
    }

    func testCheckingTakesPriorityOverReady() {
        let summary = ProjectSearchAccessSummary(
            locations: [
                location(.allowed, index: 0),
                location(.checking, index: 1),
            ]
        )

        XCTAssertEqual(summary.state, .checking)
        XCTAssertEqual(summary.checkingCount, 1)
    }

    func testActionRequiredTakesPriorityOverChecking() {
        let summary = ProjectSearchAccessSummary(
            locations: [
                location(.checking, index: 0),
                location(.selectionRequired, index: 1),
                location(.verificationRequired, index: 2),
                location(.partiallyBlocked, index: 3),
            ]
        )

        XCTAssertEqual(summary.state, .actionRequired)
        XCTAssertEqual(summary.actionRequiredCount, 2)
        XCTAssertEqual(summary.optionalLocationCount, 1)
    }

    func testBlockedTakesHighestPriority() {
        let summary = ProjectSearchAccessSummary(
            locations: [
                location(.checking, index: 0),
                location(.selectionRequired, index: 1),
                location(.blocked, index: 2),
            ]
        )

        XCTAssertEqual(summary.state, .blocked)
        XCTAssertEqual(summary.blockedCount, 1)
    }

    func testUnavailableWhenNoLocationCanBeSearched() {
        let summary = ProjectSearchAccessSummary(
            locations: [
                location(.missing, index: 0),
                location(.selectionRequired, index: 1),
            ]
        )

        XCTAssertEqual(summary.state, .unavailable)
        XCTAssertEqual(summary.searchableCount, 0)
        XCTAssertEqual(summary.optionalLocationCount, 1)
        XCTAssertEqual(summary.actionRequiredCount, 0)
    }

    func testEmptyLocationsAreUnavailable() {
        let summary = ProjectSearchAccessSummary(locations: [])

        XCTAssertEqual(summary.state, .unavailable)
        XCTAssertEqual(summary.totalCount, 0)
    }

    private func location(
        _ status: ProjectSearchAccessStatus,
        index: Int
    ) -> ProjectSearchLocationAccess {
        ProjectSearchLocationAccess(
            kind: index == 0 ? .home : .custom,
            url: URL(fileURLWithPath: "/tmp/location-\(index)"),
            status: status
        )
    }
}
