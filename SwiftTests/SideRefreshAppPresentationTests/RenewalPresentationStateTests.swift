import Foundation
import SideRefreshCore
@testable import SideRefreshAppPresentation
import XCTest

final class RenewalPresentationStateTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 10_000)

    func testEveryRunningPhaseOwnsThePresentation() {
        for phase in RenewalProgressPhase.allCases {
            let progress = RenewalPresentationProgress(
                phase: phase,
                message: "Working"
            )
            let result = RenewalPresentationResolver.resolve(
                RenewalPresentationTestFactory.input(
                    now: now,
                    progress: progress,
                    failure: .connection
                )
            )

            XCTAssertEqual(result.condition, .running)
            XCTAssertNil(result.nextAction)
            XCTAssertEqual(result.progress, progress)
        }
    }

    func testFailurePreservesOlderVerifiedEvidence() {
        let evidence = LastVerifiedEvidence(
            installedAt: now.addingTimeInterval(-1_000),
            expiresAt: now.addingTimeInterval(1_000)
        )
        let result = RenewalPresentationResolver.resolve(
            RenewalPresentationTestFactory.input(
                now: now,
                failure: .buildOrSigning,
                evidence: evidence
            )
        )

        XCTAssertEqual(result.condition, .buildOrSigningFailure)
        XCTAssertEqual(result.nextAction, .retryRenewal)
        XCTAssertEqual(result.evidence, evidence)
    }

    func testUnverifiedInstallationRoutesToInspection() {
        let evidence = LastVerifiedEvidence(
            installedAt: now.addingTimeInterval(-1_000),
            expiresAt: now.addingTimeInterval(1_000)
        )
        let result = RenewalPresentationResolver.resolve(
            RenewalPresentationTestFactory.input(
                now: now,
                failure: .unverifiedInstallation,
                evidence: evidence
            )
        )

        XCTAssertEqual(result.condition, .installationEvidenceMissing)
        XCTAssertEqual(result.nextAction, .inspectInstalledApp)
        XCTAssertEqual(result.evidence, evidence)
    }

    func testVerifiedSuccessSettlesToHealthyWithContext() {
        let evidence = LastVerifiedEvidence(
            installedAt: now,
            expiresAt: now.addingTimeInterval(2_000)
        )
        let relationship = RenewalRelationship(
            appName: "TrailNote",
            iPhoneName: "Minsu’s iPhone"
        )
        let recentResult = RenewalRecentResult(
            outcome: .verified,
            completedAt: now,
            summary: "Installed"
        )
        let destinations: Set<RenewalDestination> = [
            .settings, .diagnostics,
        ]
        let result = RenewalPresentationResolver.resolve(
            RenewalPresentationTestFactory.input(
                now: now,
                evidence: evidence,
                relationship: relationship,
                recentResult: recentResult,
                destinations: destinations
            )
        )

        XCTAssertEqual(result.condition, .healthy)
        XCTAssertEqual(result.relationship, relationship)
        XCTAssertEqual(result.nextRenewalDate, now.addingTimeInterval(500))
        XCTAssertEqual(result.signingExpirationDate, evidence.expiresAt)
        XCTAssertEqual(result.recentResult, recentResult)
        XCTAssertEqual(result.availableDestinations, destinations)
    }
}
