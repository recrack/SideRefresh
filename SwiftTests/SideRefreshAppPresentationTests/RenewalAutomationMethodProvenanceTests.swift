@testable import SideRefreshAppPresentation
import XCTest

final class RenewalAutomationMethodProvenanceTests: XCTestCase {
    func testDirtyDetailsArePendingEvenWhenSummaryRowsAreUnchanged() {
        let configuration = RenewalAutomationMethod.Configuration(
            execution: .buildSignAndInstall,
            connection: .tailnet
        )

        let presentation = RenewalAutomationMethod.presentation(
            background: .enabled,
            savedConfiguration: configuration,
            draftConfiguration: configuration,
            draftIsDirty: true
        )

        XCTAssertEqual(
            presentation.provenance,
            .savedWithPendingDraft
        )
        XCTAssertEqual(
            presentation.provenanceNotice,
            "변경사항은 저장 후 반영됩니다."
        )
    }
}
