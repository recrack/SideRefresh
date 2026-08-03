import Foundation
@testable import SideRefreshAppPresentation
import XCTest

final class RenewalPresentationSafetyTests: XCTestCase {
    func testConnectionCheckOwnsTheHomeUntilItCompletes() {
        let result = RenewalPresentationResolver.resolve(
            RenewalPresentationInput(
                now: Date(timeIntervalSince1970: 1_000),
                hasSavedConfiguration: true,
                hasCompleteTarget: true,
                executionIsEnabled: true,
                automation: .enabled,
                connection: .checking,
                renewalIsDue: true
            )
        )

        XCTAssertEqual(result.condition, .checkingConnection)
        XCTAssertNil(result.nextAction)
    }

    func testIncompleteDirtyMigrationContinuesSetup() {
        let result = RenewalPresentationResolver.resolve(
            RenewalPresentationInput(
                now: Date(timeIntervalSince1970: 1_000),
                hasSavedConfiguration: true,
                hasCompleteTarget: false,
                executionIsEnabled: true,
                draftIsDirty: true
            )
        )

        XCTAssertEqual(result.condition, .initialSetupIncomplete)
        XCTAssertEqual(result.nextAction, .continueSetup)
    }

    func testCompleteDirtyTargetCanSaveAnExecutionModeChange() {
        let result = RenewalPresentationResolver.resolve(
            RenewalPresentationInput(
                now: Date(timeIntervalSince1970: 1_000),
                hasSavedConfiguration: true,
                hasCompleteTarget: true,
                executionIsEnabled: false,
                draftIsDirty: true
            )
        )

        XCTAssertEqual(result.condition, .targetChangesUnsaved)
        XCTAssertEqual(result.nextAction, .reviewAndSaveChanges)
    }

    private let now = Date(timeIntervalSince1970: 30_000)

    func testDisabledExecutionCannotBeHealthy() {
        let result = RenewalPresentationResolver.resolve(
            input(executionIsEnabled: false)
        )

        XCTAssertEqual(result.condition, .initialSetupIncomplete)
        XCTAssertEqual(result.nextAction, .continueSetup)
    }

    func testMissingEvidenceIsDueAndActionable() {
        let result = RenewalPresentationResolver.resolve(
            input(evidence: nil)
        )

        XCTAssertEqual(result.condition, .due)
        XCTAssertEqual(result.nextAction, .renewNow)
    }

    func testDueUnknownConnectionNeedsConnectionCheck() {
        let result = RenewalPresentationResolver.resolve(
            input(connection: .unknown, renewalIsDue: true)
        )
        XCTAssertEqual(result.condition, .connectionFailure)
        XCTAssertEqual(result.nextAction, .checkConnection)
    }

    func testUnavailableDestinationDoesNotProduceRoute() {
        let presentation = presentation(
            action: .viewDiagnostics,
            destinations: []
        )
        XCTAssertNil(
            AppPresentationCoordinator.route(for: presentation)
        )
        XCTAssertEqual(
            AppPresentationCoordinator.route(
                for: self.presentation(
                    action: .viewDiagnostics,
                    destinations: [.diagnostics]
                )
            ),
            .destination(.diagnostics)
        )
    }

    private func input(
        executionIsEnabled: Bool = true,
        connection: RenewalConnectionState = .reachable,
        renewalIsDue: Bool = false,
        evidence: LastVerifiedEvidence? = .init(
            installedAt: Date(timeIntervalSince1970: 29_000),
            expiresAt: Date(timeIntervalSince1970: 40_000)
        )
    ) -> RenewalPresentationInput {
        RenewalPresentationInput(
            now: now,
            hasSavedConfiguration: true,
            hasCompleteTarget: true,
            executionIsEnabled: executionIsEnabled,
            automation: .enabled,
            connection: connection,
            renewalIsDue: renewalIsDue,
            nextRenewalDate: now.addingTimeInterval(500),
            evidence: evidence
        )
    }

    private func presentation(
        action: RenewalNextAction,
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
