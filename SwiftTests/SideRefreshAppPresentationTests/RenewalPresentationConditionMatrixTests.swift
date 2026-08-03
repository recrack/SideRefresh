import Foundation
@testable import SideRefreshAppPresentation
import XCTest

final class RenewalPresentationConditionMatrixTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 20_000)

    func testAdditionalConditionsResolveToOneAction() {
        let cases: [(RenewalPresentationInput, RenewalCondition, RenewalNextAction)] = [
            (input(projectHandoffPending: true), .projectHandoffPending, .reviewSuggestedProject),
            (input(compatibilityNeedsMigration: true), .compatibilityMigrationRequired, .migrateConfiguration),
            (input(failure: .connection), .connectionFailure, .restoreConnection),
            (input(failure: .installation), .installationFailure, .viewDiagnostics),
            (input(failure: .permission), .permissionRequired, .openPermissionSettings),
            (input(failure: .unknown), .checkFailed, .retryCheck),
        ]

        for (input, condition, action) in cases {
            let result = RenewalPresentationResolver.resolve(input)
            XCTAssertEqual(result.condition, condition)
            XCTAssertEqual(result.nextAction, action)
        }
    }

    func testDirtyDraftKeepsSavedTargetEvidenceButRequiresReview() {
        let evidence = LastVerifiedEvidence(
            installedAt: now.addingTimeInterval(-100),
            expiresAt: now.addingTimeInterval(1_000)
        )
        let result = RenewalPresentationResolver.resolve(
            input(draftIsDirty: true, evidence: evidence)
        )

        XCTAssertEqual(result.condition, .targetChangesUnsaved)
        XCTAssertEqual(result.nextAction, .reviewAndSaveChanges)
        XCTAssertEqual(result.evidence, evidence)
    }

    private func input(
        projectHandoffPending: Bool = false,
        compatibilityNeedsMigration: Bool = false,
        draftIsDirty: Bool = false,
        failure: RenewalPresentationFailure? = nil,
        evidence: LastVerifiedEvidence? = nil
    ) -> RenewalPresentationInput {
        RenewalPresentationInput(
            now: now,
            hasSavedConfiguration: true,
            hasCompleteTarget: true,
            draftIsDirty: draftIsDirty,
            automation: .enabled,
            connection: .reachable,
            nextRenewalDate: now.addingTimeInterval(500),
            evidence: evidence,
            projectHandoffPending: projectHandoffPending,
            compatibilityNeedsMigration: compatibilityNeedsMigration,
            failure: failure
        )
    }
}
