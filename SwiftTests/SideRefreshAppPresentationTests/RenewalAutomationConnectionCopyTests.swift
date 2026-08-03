import SideRefreshAppPresentation
import XCTest

final class RenewalAutomationConnectionCopyTests: XCTestCase {
    func testXcodeAutomaticConnectionExplainsTransportOwnership() {
        let presentation = makePresentation(connection: .xcodeAutomatic)

        XCTAssertEqual(
            presentation.connectionTitle,
            "Xcode/CoreDevice 자동 연결"
        )
        XCTAssertEqual(
            presentation.connectionDetail,
            "USB 또는 Xcode가 사용할 수 있는 네트워크 경로"
        )
    }

    func testTailnetCopyDoesNotClaimXcodeReachability() {
        let presentation = makePresentation(connection: .tailnet)

        XCTAssertEqual(
            presentation.connectionTitle,
            "Xcode 연결 + Tailscale 주소 확인"
        )
        XCTAssertEqual(
            presentation.connectionDetail,
            "Tailscale 온라인과 Xcode 연결은 별도 확인"
        )
    }

    func testDirectAddressRequiresAnXcodeConnection() {
        let presentation = makePresentation(connection: .directAddress)

        XCTAssertEqual(presentation.connectionTitle, "Xcode 직접 IP 연결")
        XCTAssertEqual(
            presentation.connectionDetail,
            "Xcode에서 IP 주소 연결이 먼저 필요함"
        )
    }

    private func makePresentation(
        connection: RenewalAutomationMethod.Connection
    ) -> RenewalAutomationMethod.Presentation {
        let configuration = RenewalAutomationMethod.Configuration(
            execution: .buildSignAndInstall,
            connection: connection
        )
        return RenewalAutomationMethod.presentation(
            background: .enabled,
            savedConfiguration: configuration,
            draftConfiguration: configuration,
            draftIsDirty: false
        )
    }
}
