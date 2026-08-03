import XCTest
@testable import SideRefreshAppPresentation

final class AppVersionResolutionRequestTests: XCTestCase {
    func testRequestNeedsNoTeamOrIPhone() throws {
        let request = try XCTUnwrap(makeRequest())

        XCTAssertEqual(request.buildSettingOverrides, [])
        XCTAssertEqual(request.query.scheme, "Runner")
    }

    func testChangedBuildIdentityDoesNotMatchAnOlderRequest() throws {
        let original = try XCTUnwrap(makeRequest())
        let changed = try [
            XCTUnwrap(makeRequest(containerPath: "/Projects/Other.xcworkspace")),
            XCTUnwrap(makeRequest(scheme: "Runner Staging")),
            XCTUnwrap(makeRequest(configuration: "Debug")),
            XCTUnwrap(makeRequest(bundleIdentifier: "com.example.other")),
            XCTUnwrap(makeRequest(developmentTeam: "ABCDE12345")),
        ]

        changed.forEach { XCTAssertNotEqual(original, $0) }
    }

    func testRequestNormalizesFieldsAndBuildsTheTeamOverride() throws {
        let request = try XCTUnwrap(
            makeRequest(
                containerPath: "/Projects/Folder/../Runner.xcworkspace",
                scheme: " Runner ",
                configuration: " Release ",
                bundleIdentifier: " com.example.app ",
                developmentTeam: " ABCDE12345 "
            )
        )

        XCTAssertEqual(request.query.scheme, "Runner")
        XCTAssertEqual(request.query.configuration, "Release")
        XCTAssertEqual(request.query.bundleIdentifier, "com.example.app")
        XCTAssertEqual(
            request.query.containerURL.path,
            "/Projects/Runner.xcworkspace"
        )
        XCTAssertEqual(
            request.buildSettingOverrides,
            ["DEVELOPMENT_TEAM=ABCDE12345"]
        )
    }

    func testBlankRequiredFieldsCannotCreateARequest() {
        XCTAssertNil(makeRequest(scheme: " "))
        XCTAssertNil(makeRequest(configuration: " "))
        XCTAssertNil(makeRequest(bundleIdentifier: " "))
    }

    private func makeRequest(
        containerPath: String = "/Projects/Runner.xcworkspace",
        scheme: String = "Runner",
        configuration: String = "Release",
        bundleIdentifier: String = "com.example.app",
        developmentTeam: String = ""
    ) -> AppVersionResolutionRequest? {
        AppVersionResolutionRequest(
            containerURL: URL(
                fileURLWithPath: containerPath
            ),
            scheme: scheme,
            configuration: configuration,
            bundleIdentifier: bundleIdentifier,
            derivedDataURL: URL(
                fileURLWithPath: "/tmp/SideRefresh"
            ),
            developmentTeam: developmentTeam
        )
    }
}
