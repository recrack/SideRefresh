@testable import SideRefreshAppPresentation
import XCTest

final class AppPresentationDestinationAvailabilityTests: XCTestCase {
    func testEveryDestinationActionRequiresItsDestination() {
        let cases: [(RenewalNextAction, RenewalDestination)] = [
            (.continueSetup, .setup),
            (.reviewSuggestedProject, .setup),
            (.migrateConfiguration, .advancedSettings),
            (.viewDiagnostics, .diagnostics),
        ]
        for (action, destination) in cases {
            XCTAssertNil(
                AppPresentationCoordinator.route(
                    for: presentation(action, destinations: [])
                )
            )
            XCTAssertEqual(
                AppPresentationCoordinator.route(
                    for: presentation(action, destinations: [destination])
                ),
                .destination(destination)
            )
        }
    }

    private func presentation(
        _ action: RenewalNextAction,
        destinations: Set<RenewalDestination>
    ) -> RenewalPresentation {
        RenewalPresentation(
            condition: .checkFailed,
            nextAction: action,
            relationship: nil,
            nextRenewalDate: nil,
            signingExpirationDate: nil,
            evidence: nil,
            progress: nil,
            recentResult: nil,
            availableDestinations: destinations
        )
    }
}
