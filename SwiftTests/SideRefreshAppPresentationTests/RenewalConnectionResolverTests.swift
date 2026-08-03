import SideRefreshAppPresentation
import XCTest

final class RenewalConnectionResolverTests: XCTestCase {
    func testCheckingNeverClaimsAnAvailableConnection() {
        XCTAssertEqual(
            RenewalConnectionResolver.resolve(
                isChecking: true,
                knownReachability: true,
                canAttemptWithoutProbe: true
            ),
            .checking
        )
    }

    func testKnownReachabilityWinsWhenNotChecking() {
        XCTAssertEqual(
            RenewalConnectionResolver.resolve(
                isChecking: false,
                knownReachability: true,
                canAttemptWithoutProbe: false
            ),
            .reachable
        )
        XCTAssertEqual(
            RenewalConnectionResolver.resolve(
                isChecking: false,
                knownReachability: false,
                canAttemptWithoutProbe: true
            ),
            .unreachable
        )
    }

    func testDirectlyAttemptableRouteRemainsTruthful() {
        XCTAssertEqual(
            RenewalConnectionResolver.resolve(
                isChecking: false,
                knownReachability: nil,
                canAttemptWithoutProbe: true
            ),
            .availableForAttempt
        )
    }

    func testAvailableRouteDoesNotClaimVerifiedReachability() {
        XCTAssertEqual(
            RenewalConnectionResolver.resolve(
                isChecking: false,
                evidence: .routeAvailable
            ),
            .availableForAttempt
        )
    }
}
