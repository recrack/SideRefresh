import XCTest
@testable import SideRefreshAppPresentation

final class SimpleAppSelectionCompletionPolicyTests: XCTestCase {
    func testWorkspaceConfirmationPreparesSavesAndReturnsHome() {
        XCTAssertEqual(
            SimpleAppSelectionCompletionPolicy.action(
                origin: .workspace,
                result: .confirmed
            ),
            .prepareThenSaveAndReturnHome
        )
    }

    func testWorkspaceCancellationRestoresPreviousAppAndReturnsHome() {
        XCTAssertEqual(
            SimpleAppSelectionCompletionPolicy.action(
                origin: .workspace,
                result: .cancelled
            ),
            .restoreAndReturnHome
        )
    }

    func testSettingsConfirmationAcceptsDraftAndReturnsToSettings() {
        XCTAssertEqual(
            SimpleAppSelectionCompletionPolicy.action(
                origin: .settings,
                result: .confirmed
            ),
            .acceptAndReturnToSettings
        )
    }

    func testSettingsCancellationRestoresDraftAndReturnsToSettings() {
        XCTAssertEqual(
            SimpleAppSelectionCompletionPolicy.action(
                origin: .settings,
                result: .cancelled
            ),
            .restoreAndReturnToSettings
        )
    }
}

final class SimpleAppSelectionTeamPolicyTests: XCTestCase {
    func testDetectedTeamWins() {
        XCTAssertEqual(
            SimpleAppSelectionTeamPolicy.resolve(
                detected: "DETECTED01",
                current: "CURRENT001",
                remembered: "REMEMBER01"
            ),
            "DETECTED01"
        )
    }

    func testCurrentValidTeamIsUsedWhenProjectOmitsTeam() {
        XCTAssertEqual(
            SimpleAppSelectionTeamPolicy.resolve(
                detected: "",
                current: "CURRENT001",
                remembered: "REMEMBER01"
            ),
            "CURRENT001"
        )
    }

    func testRememberedValidTeamIsUsedAfterInvalidValues() {
        XCTAssertEqual(
            SimpleAppSelectionTeamPolicy.resolve(
                detected: "missing",
                current: "",
                remembered: " REMEMBER01 "
            ),
            "REMEMBER01"
        )
    }

    func testNoInvalidTeamIsReused() {
        XCTAssertEqual(
            SimpleAppSelectionTeamPolicy.resolve(
                detected: "missing",
                current: "too-short",
                remembered: ""
            ),
            ""
        )
    }
}
