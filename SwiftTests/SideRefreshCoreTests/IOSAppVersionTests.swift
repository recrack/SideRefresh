import XCTest
@testable import SideRefreshCore

final class IOSAppVersionTests: XCTestCase {
    func testIncrementPreservesTheAppsVersionShape() throws {
        let examples = [
            ("1", "7", "2", "8"),
            ("1.0", "12.0", "1.1", "12.1"),
            ("1.0.0", "45", "1.0.1", "46"),
            ("1.2.9", "1.2.99", "1.2.10", "1.2.100"),
        ]

        for (
            marketingVersion,
            buildVersion,
            expectedMarketingVersion,
            expectedBuildVersion
        ) in examples {
            let version = try XCTUnwrap(
                IOSAppVersion(
                    marketingVersion: marketingVersion,
                    buildVersion: buildVersion
                )
            )

            XCTAssertEqual(
                version.incremented(),
                IOSAppVersion(
                    marketingVersion: expectedMarketingVersion,
                    buildVersion: expectedBuildVersion
                )
            )
        }
    }

    func testNextVersionContinuesFromTheInstalledApp() throws {
        let source = try XCTUnwrap(
            IOSAppVersion(
                marketingVersion: "1.0",
                buildVersion: "1"
            )
        )
        let installed = try XCTUnwrap(
            IOSAppVersion(
                marketingVersion: "1.1",
                buildVersion: "2"
            )
        )

        XCTAssertEqual(
            IOSAppVersion.next(
                source: source,
                installed: installed
            ),
            IOSAppVersion(
                marketingVersion: "1.2",
                buildVersion: "3"
            )
        )
    }

    func testNextVersionNeverDropsBelowANewerSourceVersion() throws {
        let source = try XCTUnwrap(
            IOSAppVersion(
                marketingVersion: "2.0",
                buildVersion: "50"
            )
        )
        let installed = try XCTUnwrap(
            IOSAppVersion(
                marketingVersion: "1.12.9",
                buildVersion: "48"
            )
        )

        XCTAssertEqual(
            IOSAppVersion.next(
                source: source,
                installed: installed
            ),
            IOSAppVersion(
                marketingVersion: "2.1",
                buildVersion: "51"
            )
        )
    }

    func testResolvedBaseCanCombineANewerMarketingAndBuildVersion() throws {
        let source = try XCTUnwrap(
            IOSAppVersion(
                marketingVersion: "2.0",
                buildVersion: "40"
            )
        )
        let installed = try XCTUnwrap(
            IOSAppVersion(
                marketingVersion: "1.9",
                buildVersion: "45"
            )
        )

        XCTAssertEqual(
            IOSAppVersion.resolvedBase(
                source: source,
                installed: installed
            ),
            IOSAppVersion(
                marketingVersion: "2.0",
                buildVersion: "45"
            )
        )
    }

    func testVersionRejectsValuesThatCannotBeSafelyIncremented() {
        let invalidValues = [
            "",
            "1.2.3.4",
            "1.beta",
            "-1",
            "$(MARKETING_VERSION)",
            String(UInt.max) + "0",
        ]

        for value in invalidValues {
            XCTAssertNil(
                IOSAppVersion(
                    marketingVersion: value,
                    buildVersion: "1"
                ),
                value
            )
            XCTAssertNil(
                IOSAppVersion(
                    marketingVersion: "1.0",
                    buildVersion: value
                ),
                value
            )
        }
    }
}
