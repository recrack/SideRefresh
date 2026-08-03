import Foundation
@testable import SideRefreshAppPresentation
import XCTest

final class RenewalPresentationTargetTests: XCTestCase {
    func testFirstSetupProjectsTheSelectedDraftApp() {
        let draft = RenewalRelationship(
            appName: "SideRefreshSample",
            iPhoneName: "iPhone 미선택"
        )

        let result = RenewalPresentationResolver.resolve(
            RenewalPresentationInput(
                now: Date(timeIntervalSince1970: 1_000),
                draftIsDirty: true,
                draftRelationship: draft
            )
        )

        XCTAssertEqual(result.relationship, draft)
    }

    func testDirtyDraftKeepsSavedRelationshipWithSavedEvidence() {
        let saved = RenewalRelationship(
            appName: "TrailNote",
            iPhoneName: "Saved iPhone"
        )
        let draft = RenewalRelationship(
            appName: "New App",
            iPhoneName: "New iPhone"
        )
        let result = RenewalPresentationResolver.resolve(
            RenewalPresentationInput(
                now: Date(timeIntervalSince1970: 1_000),
                hasSavedConfiguration: true,
                hasCompleteTarget: true,
                draftIsDirty: true,
                automation: .enabled,
                nextRenewalDate: Date(timeIntervalSince1970: 2_000),
                evidence: LastVerifiedEvidence(
                    installedAt: Date(timeIntervalSince1970: 500),
                    expiresAt: Date(timeIntervalSince1970: 3_000)
                ),
                savedRelationship: saved,
                draftRelationship: draft
            )
        )

        XCTAssertEqual(result.condition, .targetChangesUnsaved)
        XCTAssertEqual(result.relationship, saved)
        XCTAssertNotEqual(result.relationship, draft)
    }
}
