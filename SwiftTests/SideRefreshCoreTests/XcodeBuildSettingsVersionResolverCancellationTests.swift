import XCTest
@testable import SideRefreshCore

final class XcodeBuildSettingsVersionResolverCancellationTests:
    XCTestCase
{
    func testCancelledWaitingQueryDoesNotStartXcode() async throws {
        let directory = try XcodeBuildSettingsVersionResolverTestSupport
            .makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let countURL = directory.appendingPathComponent("count")
        let startedURL = directory.appendingPathComponent("started")
        let executable = try XcodeBuildSettingsVersionResolverTestSupport
            .makeExecutable(
                """
                #!/bin/sh
                printf x >> '\(countURL.path)'
                touch '\(startedURL.path)'
                sleep 0.3
                printf '%s' '[{"buildSettings":{"CURRENT_PROJECT_VERSION":"1","MARKETING_VERSION":"1.0.0","PRODUCT_BUNDLE_IDENTIFIER":"com.example.app"}}]'
                """,
                in: directory
            )
        let resolver = XcodeBuildSettingsVersionResolver()
        let query = XcodeBuildSettingsVersionResolverTestSupport.query()
        let first = Task {
            try await resolver.resolve(
                query: query,
                xcrunURL: executable
            )
        }
        try await XcodeBuildSettingsVersionResolverTestSupport.waitForFile(
            at: startedURL
        )
        let cancelled = Task {
            try await resolver.resolve(
                query: query,
                xcrunURL: executable
            )
        }
        try await Task.sleep(for: .milliseconds(50))
        cancelled.cancel()

        _ = try await first.value
        await XCTAssertThrowsErrorAsync(try await cancelled.value)
        let count = try String(contentsOf: countURL, encoding: .utf8)
        XCTAssertEqual(count, "x")
    }
}

private func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T
) async {
    do {
        _ = try await expression()
        XCTFail("Expected an error")
    } catch is CancellationError {
    } catch {
        XCTFail("Expected CancellationError, got \(error)")
    }
}
