@testable import SideRefreshAppPresentation
import XCTest

final class SimpleSettingsSaveBarPresentationTests: XCTestCase {
    func testDirtySettingsExplainThatSaveAppliesEverySelection() {
        let presentation = SimpleSettingsSaveBarPresentation.resolve(
            hasSavedConfiguration: true,
            configurationIsDirty: true,
            readiness: .complete
        )

        XCTAssertEqual(presentation.title, "저장 필요")
        XCTAssertEqual(
            presentation.detail,
            "선택한 앱·iPhone·연결 방식을 적용하려면 설정을 저장하세요."
        )
        XCTAssertEqual(presentation.actionTitle, "변경사항 저장")
        XCTAssertTrue(presentation.actionIsEnabled)
    }

    func testCleanSettingsShowThatTheyAreAlreadySaved() {
        let presentation = SimpleSettingsSaveBarPresentation.resolve(
            hasSavedConfiguration: true,
            configurationIsDirty: false,
            readiness: .complete
        )

        XCTAssertEqual(presentation.title, "저장됨")
        XCTAssertEqual(
            presentation.detail,
            "현재 앱·iPhone·연결 방식이 저장되어 있습니다."
        )
        XCTAssertEqual(presentation.actionTitle, "설정 저장")
        XCTAssertFalse(presentation.actionIsEnabled)
    }

    func testCompletedFirstSetupCanBeSaved() {
        let presentation = SimpleSettingsSaveBarPresentation.resolve(
            hasSavedConfiguration: false,
            configurationIsDirty: false,
            readiness: .complete
        )

        XCTAssertEqual(presentation.title, "저장 필요")
        XCTAssertEqual(presentation.actionTitle, "설정 저장")
        XCTAssertTrue(presentation.actionIsEnabled)
    }

    func testMissingAppExplainsWhatToDoNext() {
        let presentation = SimpleSettingsSaveBarPresentation.resolve(
            hasSavedConfiguration: false,
            configurationIsDirty: false,
            readiness: .appSelectionRequired
        )

        XCTAssertEqual(presentation.title, "설정 미완료")
        XCTAssertEqual(
            presentation.detail,
            "먼저 설치할 앱을 선택하세요."
        )
        XCTAssertEqual(presentation.actionTitle, "설정 저장")
        XCTAssertFalse(presentation.actionIsEnabled)
    }

    func testMissingIPhoneNamesOnlyTheIPhoneStep() {
        let presentation = SimpleSettingsSaveBarPresentation.resolve(
            hasSavedConfiguration: false,
            configurationIsDirty: false,
            readiness: .iphoneSelectionRequired
        )

        XCTAssertEqual(
            presentation.detail,
            "먼저 설치할 iPhone을 선택하세요."
        )
        XCTAssertFalse(presentation.actionIsEnabled)
    }

    func testIncompleteAppConfigurationNamesXcodeAndSigning() {
        let presentation = SimpleSettingsSaveBarPresentation.resolve(
            hasSavedConfiguration: false,
            configurationIsDirty: false,
            readiness: .appConfigurationRequired
        )

        XCTAssertEqual(
            presentation.detail,
            "선택한 앱의 Xcode 구성과 Apple 서명을 확인하세요."
        )
        XCTAssertFalse(presentation.actionIsEnabled)
    }

    func testIncompleteAutomationNamesTemporaryBuildFolder() {
        let presentation = SimpleSettingsSaveBarPresentation.resolve(
            hasSavedConfiguration: false,
            configurationIsDirty: false,
            readiness: .automationConfigurationRequired
        )

        XCTAssertEqual(
            presentation.detail,
            "자동화의 임시 빌드 폴더를 확인하세요."
        )
        XCTAssertFalse(presentation.actionIsEnabled)
    }

    func testMissingTailscaleInstallationBlocksSaveBeforeSubmission() {
        let presentation = SimpleSettingsSaveBarPresentation.resolve(
            hasSavedConfiguration: false,
            configurationIsDirty: false,
            readiness: .tailscaleInstallationRequired
        )

        XCTAssertEqual(presentation.title, "설정 미완료")
        XCTAssertEqual(
            presentation.detail,
            "먼저 Mac에 Tailscale을 설치하고 로그인하세요."
        )
        XCTAssertFalse(presentation.actionIsEnabled)
    }

    func testMissingTailnetDeviceBlocksSaveBeforeSubmission() {
        let presentation = SimpleSettingsSaveBarPresentation.resolve(
            hasSavedConfiguration: false,
            configurationIsDirty: false,
            readiness: .tailnetDeviceSelectionRequired
        )

        XCTAssertEqual(presentation.title, "설정 미완료")
        XCTAssertEqual(
            presentation.detail,
            "먼저 Tailscale에서 사용할 iPhone을 찾아 선택하세요."
        )
        XCTAssertFalse(presentation.actionIsEnabled)
    }
}
