import XCTest
@testable import SideRefreshCore

final class TailnetTargetTests: XCTestCase {
    func testTargetResolvesTheCurrentAddressByStableNodeID() throws {
        let target = TailnetTarget(
            tailscaleExecutable: "/Applications/Tailscale",
            nodeID: "iphone-node",
            dnsName: "iphone.example.ts.net."
        )
        let snapshot = TailnetSnapshot(
            devices: [
                device(
                    id: "iphone-node",
                    dnsName: "iphone.example.ts.net.",
                    address: "100.100.100.42",
                    isOnline: true
                ),
            ]
        )

        let resolved = try target.resolve(in: snapshot)

        XCTAssertEqual(resolved.preferredIPAddress, "100.100.100.42")
    }

    func testTargetFallsBackToDNSNameAfterNodeIsReRegistered() throws {
        let target = TailnetTarget(
            tailscaleExecutable: "/Applications/Tailscale",
            nodeID: "old-node",
            dnsName: "iphone.example.ts.net."
        )
        let snapshot = TailnetSnapshot(
            devices: [
                device(
                    id: "new-node",
                    dnsName: "iphone.example.ts.net.",
                    address: "100.100.100.99",
                    isOnline: true
                ),
            ]
        )

        let resolved = try target.resolve(in: snapshot)

        XCTAssertEqual(resolved.id, "new-node")
        XCTAssertEqual(resolved.preferredIPAddress, "100.100.100.99")
    }

    func testTargetRejectsAnOfflineDevice() {
        let target = TailnetTarget(
            tailscaleExecutable: "/Applications/Tailscale",
            nodeID: "iphone-node",
            dnsName: "iphone.example.ts.net."
        )
        let snapshot = TailnetSnapshot(
            devices: [
                device(
                    id: "iphone-node",
                    dnsName: "iphone.example.ts.net.",
                    address: "100.100.100.42",
                    isOnline: false
                ),
            ]
        )

        XCTAssertThrowsError(try target.resolve(in: snapshot)) { error in
            XCTAssertEqual(
                error as? TailnetTargetError,
                .deviceOffline("iphone.example.ts.net.")
            )
        }
    }

    private func device(
        id: String,
        dnsName: String,
        address: String,
        isOnline: Bool
    ) -> TailnetDevice {
        TailnetDevice(
            id: id,
            hostName: "localhost",
            dnsName: dnsName,
            operatingSystem: "iOS",
            addresses: [address],
            preferredIPAddress: address,
            isOnline: isOnline,
            isSelf: false
        )
    }
}
