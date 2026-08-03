import XCTest
@testable import SideRefreshCore

final class TailnetSelectionReconcilerTests: XCTestCase {
    func testSavedTargetFallsBackToDNSAfterNodeIDChanges() {
        let selected = TailnetSelectionReconciler.selectedNodeID(
            savedTarget: TailnetTarget(
                tailscaleExecutable: "/Applications/Tailscale",
                nodeID: "old-node",
                dnsName: "phone.example.ts.net."
            ),
            currentNodeID: nil,
            devices: [
                device(id: "new-node", dnsName: "phone.example.ts.net."),
            ]
        )

        XCTAssertEqual(selected, "new-node")
    }

    func testMissingSavedTargetDoesNotSelectAnotherPhone() {
        let selected = TailnetSelectionReconciler.selectedNodeID(
            savedTarget: TailnetTarget(
                tailscaleExecutable: "/Applications/Tailscale",
                nodeID: "missing-node",
                dnsName: "missing.example.ts.net."
            ),
            currentNodeID: "other-node",
            devices: [
                device(id: "other-node", dnsName: "other.example.ts.net."),
            ]
        )

        XCTAssertNil(selected)
    }

    func testCurrentExplicitSelectionIsPreservedWithoutSavedTarget() {
        let selected = TailnetSelectionReconciler.selectedNodeID(
            savedTarget: nil,
            currentNodeID: "phone-node",
            devices: [
                device(id: "phone-node", dnsName: "phone.example.ts.net."),
            ]
        )

        XCTAssertEqual(selected, "phone-node")
    }

    private func device(id: String, dnsName: String) -> TailnetDevice {
        TailnetDevice(
            id: id,
            hostName: "phone",
            dnsName: dnsName,
            operatingSystem: "iOS",
            addresses: ["100.64.0.9"],
            preferredIPAddress: "100.64.0.9",
            isOnline: true,
            isSelf: false
        )
    }
}
