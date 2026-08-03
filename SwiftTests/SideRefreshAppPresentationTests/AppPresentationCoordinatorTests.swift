@testable import SideRefreshAppPresentation
import XCTest

final class AppPresentationCoordinatorTests: XCTestCase {
    func testEveryRenewalActionHasOneSemanticRoute() {
        let cases: [(RenewalNextAction, AppPresentationRoute)] = [
            (.continueSetup, .destination(.setup)),
            (.reviewSuggestedProject, .destination(.setup)),
            (.migrateConfiguration, .destination(.advancedSettings)),
            (
                .reviewAndSaveChanges,
                .confirmation(.saveTargetChanges)
            ),
            (
                .enableAutomaticRenewal,
                .confirmation(.enableAutomaticRenewal)
            ),
            (
                .openBackgroundSettings,
                .systemHandoff(.backgroundItemsSettings)
            ),
            (.renewNow, .confirmation(.installNow)),
            (.retryRenewal, .confirmation(.installNow)),
            (.checkConnection, .command(.checkConnection)),
            (.restoreConnection, .command(.checkConnection)),
            (.fixInXcode, .systemHandoff(.xcode)),
            (.inspectInstalledApp, .command(.inspectInstalledApp)),
            (
                .openPermissionSettings,
                .systemHandoff(.filesAndFoldersSettings)
            ),
            (.retryCheck, .command(.refresh)),
            (.viewDiagnostics, .destination(.diagnostics)),
        ]
        XCTAssertEqual(cases.map(\.0), RenewalNextAction.allCases)

        for (action, expectedRoute) in cases {
            XCTAssertEqual(
                AppPresentationCoordinator.route(for: action),
                expectedRoute
            )
        }
    }

    func testHealthyPresentationHasNoRoute() {
        let presentation = RenewalPresentation(
            condition: .healthy,
            nextAction: nil,
            relationship: nil,
            nextRenewalDate: nil,
            signingExpirationDate: nil,
            evidence: nil,
            progress: nil,
            recentResult: nil,
            availableDestinations: []
        )

        XCTAssertNil(
            AppPresentationCoordinator.route(for: presentation)
        )
    }

}
