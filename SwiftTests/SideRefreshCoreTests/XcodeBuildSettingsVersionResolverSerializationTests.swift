import XCTest
@testable import SideRefreshCore

final class XcodeBuildSettingsVersionResolverSerializationTests:
    XCTestCase
{
    func testResolverDoesNotOverlapXcodeQueries() async throws {
        let directory = try XcodeBuildSettingsVersionResolverTestSupport
            .makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let lockURL = directory.appendingPathComponent("lock")
        let executable = try XcodeBuildSettingsVersionResolverTestSupport
            .makeExecutable(
                """
                #!/bin/sh
                mkdir '\(lockURL.path)' || exit 91
                sleep 0.2
                rmdir '\(lockURL.path)'
                printf '%s' '[{"buildSettings":{"CURRENT_PROJECT_VERSION":"1","MARKETING_VERSION":"1.0.0","PRODUCT_BUNDLE_IDENTIFIER":"com.example.app"}}]'
                """,
                in: directory
            )
        let resolver = XcodeBuildSettingsVersionResolver()
        let query = XcodeBuildSettingsVersionResolverTestSupport.query()

        async let first = resolver.resolve(
            query: query,
            xcrunURL: executable
        )
        async let second = resolver.resolve(
            query: query,
            xcrunURL: executable
        )

        let versions = try await [first, second]
        XCTAssertEqual(versions.count, 2)
    }
}
