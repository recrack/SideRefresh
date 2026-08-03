@testable import SideRefreshAppPresentation
import XCTest

final class SimpleSettingsAutomationPolicyTests: XCTestCase {
    func testEnabledAutomationCanBeDisabled() {
        XCTAssertEqual(
            SimpleSettingsAutomationPolicy.actions(
                for: .enabled,
                canRegister: true
            ),
            [.disable]
        )
    }

    func testApprovalOpensMacOSSettingsInsteadOfDisabling() {
        XCTAssertEqual(
            SimpleSettingsAutomationPolicy.actions(
                for: .approvalRequired,
                canRegister: true
            ),
            [.disable, .openApproval]
        )
    }

    func testUnsavedConfigurationMustBeSavedBeforeEnabling() {
        XCTAssertEqual(
            SimpleSettingsAutomationPolicy.actions(
                for: .notRegistered,
                canRegister: false
            ),
            [.saveFirst]
        )
        XCTAssertEqual(
            SimpleSettingsAutomationPolicy.actions(
                for: .notRegistered,
                canRegister: true
            ),
            [.enable]
        )
    }

    func testUnavailableHelperRoutesToDiagnostics() {
        for state in [
            BackgroundAutomationState.helperMissing,
            .unknown,
        ] {
            XCTAssertEqual(
                SimpleSettingsAutomationPolicy.actions(
                    for: state,
                    canRegister: true
                ),
                [.viewDiagnostics]
            )
        }
    }
}
