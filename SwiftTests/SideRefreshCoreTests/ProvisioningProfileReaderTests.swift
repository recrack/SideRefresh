import Foundation
import XCTest
@testable import SideRefreshCore

final class ProvisioningProfileReaderTests: XCTestCase {
    func testParsesProfileIdentityAndExpiration() throws {
        let payload: [String: Any] = [
            "UUID": "PROFILE-UUID",
            "Name": "iOS Team Provisioning Profile",
            "CreationDate": Date(
                timeIntervalSince1970: 1_700_000_000
            ),
            "ExpirationDate": Date(
                timeIntervalSince1970: 1_700_604_800
            ),
            "AppIDName": "Sample App",
            "TeamIdentifier": ["ABCDE12345"],
            "TeamName": "Sample Team",
            "ProvisionedDevices": [
                "00008110-001234567890001E",
            ],
            "Platform": ["iOS"],
            "TimeToLive": 7,
            "LocalProvision": true,
            "Entitlements": [
                "application-identifier":
                    "ABCDE12345.com.example.app",
                "get-task-allow": true,
            ],
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: payload,
            format: .xml,
            options: 0
        )

        let metadata = try ProvisioningProfileReader.parsePayload(data)

        XCTAssertEqual(metadata.identifier, "PROFILE-UUID")
        XCTAssertEqual(
            metadata.expirationDate,
            Date(timeIntervalSince1970: 1_700_604_800)
        )
        XCTAssertEqual(
            metadata.applicationIdentifier,
            "ABCDE12345.com.example.app"
        )
        XCTAssertEqual(metadata.teamIdentifiers, ["ABCDE12345"])
        XCTAssertEqual(metadata.appIdentifierName, "Sample App")
        XCTAssertEqual(metadata.timeToLiveDays, 7)
        XCTAssertEqual(
            metadata.entitlementKeys,
            ["application-identifier", "get-task-allow"]
        )
    }

    func testRejectsProfileWithoutExpiration() throws {
        let data = try PropertyListSerialization.data(
            fromPropertyList: ["UUID": "PROFILE-UUID"],
            format: .xml,
            options: 0
        )

        XCTAssertThrowsError(
            try ProvisioningProfileReader.parsePayload(data)
        ) { error in
            XCTAssertEqual(
                error as? ProvisioningProfileReaderError,
                .expirationMissing
            )
        }
    }

    func testMatchesProfilesByTeamPrefixedApplicationIdentifier() {
        let matching = ProvisioningProfileMetadata(
            identifier: "MATCH",
            name: "Matching",
            creationDate: nil,
            expirationDate: Date(),
            applicationIdentifier:
                "ABCDE12345.com.example.app"
        )
        let other = ProvisioningProfileMetadata(
            identifier: "OTHER",
            name: "Other",
            creationDate: nil,
            expirationDate: Date(),
            applicationIdentifier:
                "ABCDE12345.com.example.other"
        )

        XCTAssertEqual(
            DeviceProvisioningProfileReader.profiles(
                matching: "com.example.app",
                in: [matching, other]
            ).map(\.identifier),
            ["MATCH"]
        )
    }
}
