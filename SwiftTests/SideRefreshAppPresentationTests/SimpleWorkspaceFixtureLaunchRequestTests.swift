@testable import SideRefreshAppPresentation
import XCTest

final class SimpleWorkspaceFixtureLaunchRequestTests: XCTestCase {
    func testMissingValueUsesNormalLaunch() {
        XCTAssertEqual(
            SimpleWorkspaceFixtureLaunchRequest.resolve(nil),
            .normal
        )
    }

    func testKnownValueUsesRequestedFixture() {
        XCTAssertEqual(
            SimpleWorkspaceFixtureLaunchRequest.resolve("healthy"),
            .fixture(.healthy)
        )
    }

    func testUnknownValueFailsClosed() {
        XCTAssertEqual(
            SimpleWorkspaceFixtureLaunchRequest.resolve("typo"),
            .invalid("typo")
        )
    }

    func testCaptureWithoutFixtureFailsClosed() {
        XCTAssertEqual(
            SimpleWorkspaceFixtureLaunchRequest.resolve(
                nil,
                captureRequested: true
            ),
            .invalid("missing")
        )
    }
}
