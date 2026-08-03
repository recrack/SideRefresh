import XCTest
@testable import SideRefreshAppPresentation

final class AppVersionReloadPolicyTests: XCTestCase {
    func testUnchangedBuildIdentityKeepsTheCurrentVersion() throws {
        let request = try XCTUnwrap(makeRequest())

        XCTAssertEqual(
            AppVersionReloadPolicy.action(
                previous: request,
                current: request
            ),
            .keep
        )
    }

    func testChangedBuildIdentityClearsAndResolvesAgain() throws {
        let previous = try XCTUnwrap(makeRequest())
        let current = try XCTUnwrap(makeRequest(scheme: "Other"))

        XCTAssertEqual(
            AppVersionReloadPolicy.action(
                previous: previous,
                current: current
            ),
            .clearAndResolve(current)
        )
    }

    func testIncompleteBuildIdentityClearsWithoutResolving() throws {
        let previous = try XCTUnwrap(makeRequest())

        XCTAssertEqual(
            AppVersionReloadPolicy.action(
                previous: previous,
                current: nil
            ),
            .clear
        )
    }

    func testFirstCompleteBuildIdentityResolves() throws {
        let current = try XCTUnwrap(makeRequest())

        XCTAssertEqual(
            AppVersionReloadPolicy.action(
                previous: nil,
                current: current
            ),
            .clearAndResolve(current)
        )
    }

    func testStillIncompleteBuildIdentityDoesNotChurn() {
        XCTAssertEqual(
            AppVersionReloadPolicy.action(
                previous: nil,
                current: nil
            ),
            .keep
        )
    }

    private func makeRequest(
        scheme: String = "Runner"
    ) -> AppVersionResolutionRequest? {
        AppVersionResolutionRequest(
            containerURL: URL(
                fileURLWithPath: "/Projects/Runner.xcworkspace"
            ),
            scheme: scheme,
            configuration: "Release",
            bundleIdentifier: "com.example.app",
            derivedDataURL: URL(
                fileURLWithPath: "/tmp/SideRefresh"
            ),
            developmentTeam: ""
        )
    }
}
