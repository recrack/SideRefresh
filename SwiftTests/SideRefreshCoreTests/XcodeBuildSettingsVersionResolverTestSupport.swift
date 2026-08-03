import Foundation
@testable import SideRefreshCore

enum XcodeBuildSettingsVersionResolverTestSupport {
    enum Error: Swift.Error {
        case processDidNotStart
    }

    static func query() -> XcodeBuildSettingsQuery {
        XcodeBuildSettingsQuery(
            containerURL: URL(
                fileURLWithPath: "/Projects/App.xcodeproj"
            ),
            scheme: "App",
            configuration: "Release",
            bundleIdentifier: "com.example.app",
            derivedDataURL: URL(
                fileURLWithPath: "/tmp/app-derived-data"
            )
        )
    }

    static func makeDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory
    }

    static func makeExecutable(
        _ script: String,
        in directory: URL
    ) throws -> URL {
        let executable = directory.appendingPathComponent("xcrun")
        try Data(script.utf8).write(to: executable)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: executable.path
        )
        return executable
    }

    static func waitForFile(at url: URL) async throws {
        for _ in 0..<100 {
            if FileManager.default.fileExists(atPath: url.path) {
                return
            }
            try await Task.sleep(for: .milliseconds(10))
        }
        throw Error.processDidNotStart
    }
}
