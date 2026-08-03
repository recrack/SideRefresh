import XCTest
@testable import SideRefreshAppPresentation

final class RenewalPresentationResolverTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testHealthyRenewalHasNoNextAction() {
        let input = RenewalPresentationInput(
            now: now,
            hasSavedConfiguration: true,
            hasCompleteTarget: true,
            automation: .enabled,
            nextRenewalDate: now.addingTimeInterval(86_400),
            evidence: .init(
                installedAt: now.addingTimeInterval(-3_600),
                expiresAt: now.addingTimeInterval(6 * 86_400)
            )
        )

        let result = RenewalPresentationResolver.resolve(input)

        XCTAssertEqual(result.condition, .healthy)
        XCTAssertNil(result.nextAction)
    }

    func testMissingConfigurationContinuesSetup() {
        let result = RenewalPresentationResolver.resolve(
            RenewalPresentationInput(now: now)
        )

        XCTAssertEqual(result.condition, .initialSetupIncomplete)
        XCTAssertEqual(result.nextAction, .continueSetup)
    }

    func testUnavailableBackgroundServiceOpensDiagnostics() {
        let result = RenewalPresentationResolver.resolve(
            readyInput(automation: .helperMissing)
        )

        XCTAssertEqual(result.condition, .backgroundServiceUnavailable)
        XCTAssertEqual(result.nextAction, .viewDiagnostics)
    }

    func testDueReachableTargetRenewsNow() {
        let result = RenewalPresentationResolver.resolve(
            readyInput(connection: .reachable, renewalIsDue: true)
        )

        XCTAssertEqual(result.condition, .due)
        XCTAssertEqual(result.nextAction, .renewNow)
    }

    private func readyInput(
        automation: BackgroundAutomationState = .enabled,
        connection: RenewalConnectionState = .unknown,
        renewalIsDue: Bool = false
    ) -> RenewalPresentationInput {
        RenewalPresentationInput(
            now: now,
            hasSavedConfiguration: true,
            hasCompleteTarget: true,
            automation: automation,
            connection: connection,
            renewalIsDue: renewalIsDue,
            nextRenewalDate: now.addingTimeInterval(86_400),
            evidence: LastVerifiedEvidence(
                installedAt: now,
                expiresAt: now.addingTimeInterval(6 * 86_400)
            )
        )
    }
}
