import XCTest
import SideRefreshCore
@testable import SideRefreshAppPresentation

final class AppVersionResolutionPolicyTests: XCTestCase {
    func testResolvedXcodeVersionWinsOverProjectMetadata() throws {
        let projectMetadata = try XCTUnwrap(IOSAppVersion(
            marketingVersion: "0.9.0",
            buildVersion: "9"
        ))
        let resolved = try XCTUnwrap(IOSAppVersion(
            marketingVersion: "1.0.0",
            buildVersion: "1"
        ))

        XCTAssertEqual(
            AppVersionResolutionPolicy.resolve(
                xcode: resolved,
                projectMetadata: projectMetadata
            ),
            resolved
        )
    }

    func testResolvedXcodeVersionWorksWithoutProjectMetadata() throws {
        let resolved = try XCTUnwrap(IOSAppVersion(
            marketingVersion: "1.0.0",
            buildVersion: "1"
        ))

        XCTAssertEqual(
            AppVersionResolutionPolicy.resolve(
                xcode: resolved,
                projectMetadata: nil
            ),
            resolved
        )
    }

    func testProjectMetadataRemainsTheFallback() throws {
        let projectMetadata = try XCTUnwrap(IOSAppVersion(
            marketingVersion: "2.4.1",
            buildVersion: "73"
        ))

        XCTAssertEqual(
            AppVersionResolutionPolicy.resolve(
                xcode: nil,
                projectMetadata: projectMetadata
            ),
            projectMetadata
        )
    }

    func testMissingSourcesHaveNoVersion() {
        XCTAssertNil(
            AppVersionResolutionPolicy.resolve(
                xcode: nil,
                projectMetadata: nil
            )
        )
    }
}
