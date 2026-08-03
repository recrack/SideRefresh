@testable import SideRefreshAppPresentation
import XCTest

final class SimpleSettingsClosePolicyTests: XCTestCase {
    func testUnsavedCompatibilityMigrationRestoresSavedConfiguration() {
        XCTAssertEqual(
            SimpleSettingsClosePolicy.action(
                beganCompatibilityMigration: true,
                configurationIsDirty: true
            ),
            .restoreSavedConfiguration
        )
    }

    func testSavedMigrationAndNormalDraftsAreNotRolledBack() {
        XCTAssertEqual(
            SimpleSettingsClosePolicy.action(
                beganCompatibilityMigration: true,
                configurationIsDirty: false
            ),
            .keepDraft
        )
        XCTAssertEqual(
            SimpleSettingsClosePolicy.action(
                beganCompatibilityMigration: false,
                configurationIsDirty: true
            ),
            .keepDraft
        )
    }

    func testSavedMigrationThenNewDraftStaysAvailableOnClose() {
        var lifecycle = SimpleSettingsMigrationLifecycle()
        lifecycle.begin()
        lifecycle.completeIfSaved(
            hasGuidedTarget: true,
            configurationIsDirty: false
        )

        XCTAssertEqual(
            lifecycle.closeAction(configurationIsDirty: true),
            .keepDraft
        )
    }

    func testRestoredMigrationDoesNotRollbackTheNextSettingsDraft() {
        var lifecycle = SimpleSettingsMigrationLifecycle()
        lifecycle.begin()

        XCTAssertEqual(
            lifecycle.takeCloseAction(configurationIsDirty: true),
            .restoreSavedConfiguration
        )
        XCTAssertEqual(
            lifecycle.takeCloseAction(configurationIsDirty: true),
            .keepDraft
        )
    }
}
