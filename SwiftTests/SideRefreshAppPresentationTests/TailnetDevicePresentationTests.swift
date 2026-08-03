@testable import SideRefreshAppPresentation
import SideRefreshCore
import XCTest

final class TailnetDevicePresentationTests: XCTestCase {
    func testLocalhostDevicesUseDNSAddressAndIdentifierToStayDistinct() {
        let first = device(
            id: "nExample11AA22NODE",
            dnsName: "personal-iphone.example.ts.net.",
            address: "100.64.0.1"
        )
        let second = device(
            id: "nSample33BB44NODE",
            dnsName: "work-iphone.example.ts.net.",
            address: "100.64.0.2"
        )

        let firstLabel = TailnetDevicePresentation.pickerLabel(for: first)
        let secondLabel = TailnetDevicePresentation.pickerLabel(for: second)

        XCTAssertNotEqual(firstLabel, secondLabel)
        XCTAssertEqual(
            firstLabel,
            "personal-iphone · 100.64.0.1 · 식별자 nExamp…NODE"
        )
        XCTAssertEqual(
            secondLabel,
            "work-iphone · 100.64.0.2 · 식별자 nSampl…NODE"
        )
    }

    func testOnlineStatusExplainsTheNextXcodeStep() {
        let presentation = TailnetDevicePresentation.status(
            for: device(
                id: "node-0001",
                dnsName: "personal-iphone.example.ts.net.",
                address: "100.64.0.1"
            )
        )

        XCTAssertEqual(presentation.title, "Tailscale 주소 확인 완료")
        XCTAssertEqual(
            presentation.detail,
            "위의 ‘Xcode에서 iPhone 확인’을 눌러 설치 기기를 확인하세요."
        )
    }

    private func device(
        id: String,
        dnsName: String,
        address: String
    ) -> TailnetDevice {
        TailnetDevice(
            id: id,
            hostName: "localhost",
            dnsName: dnsName,
            operatingSystem: "iOS",
            addresses: [address],
            preferredIPAddress: address,
            isOnline: true,
            isSelf: false
        )
    }
}
