import SideRefreshAppPresentation
import XCTest

final class RenewalAutomationMethodPresentationTests: XCTestCase {
    func testSavedMethodStaysActiveWhileDraftWaitsForSave() {
        let saved = RenewalAutomationMethod.Configuration(
            execution: .buildSignAndInstall,
            connection: .tailnet
        )
        let draft = RenewalAutomationMethod.Configuration(
            execution: .validationOnly,
            connection: .directAddress
        )

        let presentation = RenewalAutomationMethod.presentation(
            background: .enabled,
            savedConfiguration: saved,
            draftConfiguration: draft,
            draftIsDirty: true
        )

        XCTAssertEqual(presentation.background, .enabled)
        XCTAssertEqual(presentation.configuration, saved)
        XCTAssertEqual(
            presentation.provenance,
            .savedWithPendingDraft
        )
        XCTAssertEqual(presentation.backgroundTitle, "백그라운드 켜짐")
        XCTAssertEqual(presentation.executionTitle, "Xcode로 빌드·서명·설치")
        XCTAssertEqual(
            presentation.provenanceNotice,
            "변경사항은 저장 후 반영됩니다."
        )
    }

    func testUnsavedMethodExplainsThatItIsOnlyADraft() {
        let draft = RenewalAutomationMethod.Configuration(
            execution: .validationOnly,
            connection: .xcodeAutomatic
        )

        let presentation = RenewalAutomationMethod.presentation(
            background: .notRegistered,
            savedConfiguration: nil,
            draftConfiguration: draft,
            draftIsDirty: true
        )

        XCTAssertEqual(presentation.configuration, draft)
        XCTAssertEqual(presentation.provenance, .draftOnly)
        XCTAssertEqual(presentation.backgroundTitle, "백그라운드 꺼짐")
        XCTAssertEqual(presentation.executionTitle, "설정만 확인")
        XCTAssertEqual(
            presentation.provenanceNotice,
            "아직 저장되지 않은 방식입니다."
        )
    }

    func testUnchangedSavedMethodNeedsNoNotice() {
        let configuration = RenewalAutomationMethod.Configuration(
            execution: .buildSignAndInstall,
            connection: .directAddress
        )

        let presentation = RenewalAutomationMethod.presentation(
            background: .approvalRequired,
            savedConfiguration: configuration,
            draftConfiguration: configuration,
            draftIsDirty: false
        )

        XCTAssertEqual(presentation.provenance, .saved)
        XCTAssertEqual(presentation.backgroundTitle, "승인 필요")
        XCTAssertEqual(presentation.backgroundDetail, "macOS에서 백그라운드 실행을 허용하세요")
        XCTAssertNil(presentation.provenanceNotice)
    }
}
