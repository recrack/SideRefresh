import Foundation
import XCTest
@testable import SideRefreshCore

final class TailscaleStatusParserTests: XCTestCase {
    func testParserFindsTheIPhoneAndPrefersItsIPv4Address() throws {
        let json = """
        {
          "Self": {
            "ID": "self-id",
            "HostName": "studio-mac",
            "DNSName": "studio-mac.example.ts.net.",
            "OS": "macOS",
            "TailscaleIPs": ["100.64.0.1", "fd7a:115c:a1e0::1"],
            "Online": true
          },
          "Peer": {
            "nodekey:iphone": {
              "ID": "iphone-id",
              "HostName": "personal-iphone",
              "DNSName": "personal-iphone.example.ts.net.",
              "OS": "iOS",
              "TailscaleIPs": [
                "fd7a:115c:a1e0::2",
                "100.64.0.2"
              ],
              "Online": true
            },
            "nodekey:server": {
              "ID": "server-id",
              "HostName": "home-server",
              "DNSName": "home-server.example.ts.net.",
              "OS": "linux",
              "TailscaleIPs": ["100.64.0.3"],
              "Online": false
            }
          }
        }
        """

        let snapshot = try TailscaleStatusParser.parse(Data(json.utf8))

        XCTAssertEqual(snapshot.devices.count, 3)
        XCTAssertEqual(
            snapshot.iOSDevices,
            [
                TailnetDevice(
                    id: "iphone-id",
                    hostName: "personal-iphone",
                    dnsName: "personal-iphone.example.ts.net.",
                    operatingSystem: "iOS",
                    addresses: [
                        "fd7a:115c:a1e0::2",
                        "100.64.0.2",
                    ],
                    preferredIPAddress: "100.64.0.2",
                    isOnline: true,
                    isSelf: false
                ),
            ]
        )
    }
}
