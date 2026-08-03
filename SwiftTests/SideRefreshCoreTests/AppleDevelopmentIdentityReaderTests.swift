import Security
import XCTest
@testable import SideRefreshCore

final class AppleDevelopmentIdentityReaderTests: XCTestCase {
    func testExtractsTeamIdentifierFromAppleDevelopmentCertificate() {
        XCTAssertEqual(
            AppleDevelopmentIdentityReader.teamIdentifier(
                commonName: "Apple Development: Example User (ABCDE12345)",
                organizationalUnits: ["ABCDE12345"]
            ),
            "ABCDE12345"
        )
    }

    func testSupportsLegacyIPhoneDeveloperCertificate() {
        XCTAssertEqual(
            AppleDevelopmentIdentityReader.teamIdentifier(
                commonName: "iPhone Developer: Example User (ABCDE12345)",
                organizationalUnits: ["ABCDE12345"]
            ),
            "ABCDE12345"
        )
    }

    func testRejectsUnrelatedCertificateAndMalformedTeamIdentifier() {
        XCTAssertNil(
            AppleDevelopmentIdentityReader.teamIdentifier(
                commonName: "Apple Distribution: Example User",
                organizationalUnits: ["ABCDE12345"]
            )
        )
        XCTAssertNil(
            AppleDevelopmentIdentityReader.teamIdentifier(
                commonName: "Apple Development: Example User",
                organizationalUnits: ["NOT-A-TEAM"]
            )
        )
    }

    func testSelectsFirstValidOrganizationalUnit() {
        XCTAssertEqual(
            AppleDevelopmentIdentityReader.teamIdentifier(
                commonName: "Apple Development: Example User",
                organizationalUnits: ["invalid", "ABCDE12345", "SECOND0001"]
            ),
            "ABCDE12345"
        )
    }

    func testReadsScalarAndArrayOrganizationalUnitValues() {
        XCTAssertEqual(
            AppleDevelopmentIdentityReader.organizationalUnits(
                from: "ABCDE12345"
            ),
            ["ABCDE12345"]
        )

        let values: [[CFString: Any]] = [
            [kSecPropertyKeyValue: "ABCDE12345"],
            [kSecPropertyKeyValue: "SECOND0001"],
        ]
        XCTAssertEqual(
            AppleDevelopmentIdentityReader.organizationalUnits(
                from: values
            ),
            ["ABCDE12345", "SECOND0001"]
        )
    }
}
