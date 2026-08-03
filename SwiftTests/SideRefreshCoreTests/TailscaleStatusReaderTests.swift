import Foundation
import XCTest
@testable import SideRefreshCore

final class TailscaleStatusReaderTests: XCTestCase {
    func testReaderRunsOnlyStatusJSONWithTheAppStoreCLIEnvironment() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let executable = directory.appendingPathComponent("tailscale")
        let script = """
        #!/bin/sh
        test "$1" = "status" || exit 41
        test "$2" = "--json" || exit 42
        test "$TAILSCALE_BE_CLI" = "1" || exit 43
        printf '%s' '{"Peer":{"phone":{"ID":"phone-node","HostName":"phone","DNSName":"phone.example.ts.net.","OS":"iOS","TailscaleIPs":["100.64.0.9"],"Online":true}}}'
        """
        try Data(script.utf8).write(to: executable)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: executable.path
        )

        let snapshot = try TailscaleStatusReader().read(
            executableURL: executable
        )

        XCTAssertEqual(snapshot.iOSDevices.count, 1)
        XCTAssertEqual(snapshot.iOSDevices.first?.id, "phone-node")
    }

    func testReaderRejectsMissingExecutable() {
        XCTAssertThrowsError(
            try TailscaleStatusReader().read(
                executableURL: URL(
                    fileURLWithPath: "/definitely/missing/tailscale"
                )
            )
        ) { error in
            guard case .invalidExecutable =
                    error as? TailscaleStatusReaderError
            else {
                return XCTFail("Expected invalidExecutable, got \(error)")
            }
        }
    }

    func testReaderReportsNonzeroExitAndStandardError() throws {
        let executable = try makeExecutable(
            """
            #!/bin/sh
            printf '%s' 'backend unavailable' >&2
            exit 17
            """
        )

        XCTAssertThrowsError(
            try TailscaleStatusReader().read(executableURL: executable)
        ) { error in
            guard case let .commandFailed(exitCode, message) =
                    error as? TailscaleStatusReaderError
            else {
                return XCTFail("Expected commandFailed, got \(error)")
            }
            XCTAssertEqual(exitCode, 17)
            XCTAssertEqual(message, "backend unavailable")
        }
    }

    func testReaderRejectsMalformedJSON() throws {
        let executable = try makeExecutable(
            """
            #!/bin/sh
            printf '%s' 'not-json'
            """
        )

        XCTAssertThrowsError(
            try TailscaleStatusReader().read(executableURL: executable)
        )
    }

    func testReaderRejectsOversizedOutput() throws {
        let executable = try makeExecutable(
            """
            #!/bin/sh
            /usr/bin/yes x | /usr/bin/head -c 4194305
            """
        )

        XCTAssertThrowsError(
            try TailscaleStatusReader().read(executableURL: executable)
        ) { error in
            guard case .outputTooLarge =
                    error as? TailscaleStatusReaderError
            else {
                return XCTFail("Expected outputTooLarge, got \(error)")
            }
        }
    }

    private func makeExecutable(_ script: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let executable = directory.appendingPathComponent("tailscale")
        try Data(script.utf8).write(to: executable)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: executable.path
        )
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return executable
    }
}
