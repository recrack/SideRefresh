import XCTest
@testable import SideRefreshAppPresentation

final class RenewalPresentationPrecedenceTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testExpiredDirtyTargetReviewsChangesFirst() {
        let result = RenewalPresentationResolver.resolve(
            input(
                draftIsDirty: true,
                expiresAt: now.addingTimeInterval(-1)
            )
        )

        XCTAssertEqual(result.condition, .expired)
        XCTAssertEqual(result.nextAction, .reviewAndSaveChanges)
    }

    func testDueUnreachableTargetChecksConnection() {
        let result = RenewalPresentationResolver.resolve(
            input(
                connection: .unreachable,
                renewalIsDue: true
            )
        )

        XCTAssertEqual(result.condition, .connectionFailure)
        XCTAssertEqual(result.nextAction, .checkConnection)
    }

    func testBackgroundApprovalOpensSystemSettings() {
        let result = RenewalPresentationResolver.resolve(
            input(automation: .approvalRequired)
        )

        XCTAssertEqual(result.condition, .backgroundApprovalRequired)
        XCTAssertEqual(result.nextAction, .openBackgroundSettings)
    }

    func testDisabledAutomationCanBeEnabled() {
        let result = RenewalPresentationResolver.resolve(
            input(automation: .notRegistered)
        )

        XCTAssertEqual(result.condition, .automaticRenewalDisabled)
        XCTAssertEqual(result.nextAction, .enableAutomaticRenewal)
    }

    func testDueRenewalPrecedesBackgroundConfiguration() {
        for automation: BackgroundAutomationState in [
            .notRegistered, .approvalRequired,
        ] {
            let result = RenewalPresentationResolver.resolve(
                input(
                    automation: automation,
                    renewalIsDue: true
                )
            )
            XCTAssertEqual(result.condition, .due)
            XCTAssertEqual(result.nextAction, .renewNow)
        }
    }

    private func input(
        draftIsDirty: Bool = false,
        automation: BackgroundAutomationState = .enabled,
        connection: RenewalConnectionState = .reachable,
        renewalIsDue: Bool = false,
        expiresAt: Date? = nil
    ) -> RenewalPresentationInput {
        let expiration = expiresAt
            ?? now.addingTimeInterval(6 * 86_400)
        return RenewalPresentationInput(
            now: now,
            hasSavedConfiguration: true,
            hasCompleteTarget: true,
            draftIsDirty: draftIsDirty,
            automation: automation,
            connection: connection,
            renewalIsDue: renewalIsDue,
            nextRenewalDate: now.addingTimeInterval(86_400),
            evidence: .init(
                installedAt: now.addingTimeInterval(-3_600),
                expiresAt: expiration
            )
        )
    }
}
