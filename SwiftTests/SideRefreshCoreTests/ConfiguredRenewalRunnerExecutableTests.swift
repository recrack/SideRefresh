import Foundation
import XCTest
@testable import SideRefreshCore

final class ConfiguredRenewalRunnerExecutableTests: XCTestCase {
    func testImmediateAndDueRenewalsRecoverMissingSavedExecutable() throws {
        for immediately in [true, false] {
            let fixture = try Fixture()
            defer { try? FileManager.default.removeItem(at: fixture.directory) }
            let runner = fixture.runner(candidates: [fixture.executable])

            let result = immediately
                ? try runner.runImmediately(fixture.configuration())
                : try runner.runIfDue(fixture.configuration())

            XCTAssertTrue(result.commandWasExecuted)
            XCTAssertTrue(result.succeeded)
        }
    }

    func testExecutableSavedPathIsPreferredOverFallback() throws {
        let fixture = try Fixture()
        defer { try? FileManager.default.removeItem(at: fixture.directory) }
        let fallback = fixture.directory.appendingPathComponent("wrong-tailscale")
        try Data("#!/bin/sh\nexit 42\n".utf8).write(to: fallback)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700], ofItemAtPath: fallback.path
        )

        let result = try fixture.runner(candidates: [fallback]).runImmediately(
            fixture.configuration(savedExecutable: fixture.executable)
        )

        XCTAssertTrue(result.succeeded)
    }

    func testMissingTailscaleStopsRenewalWithSavedPathError() throws {
        let fixture = try Fixture()
        defer { try? FileManager.default.removeItem(at: fixture.directory) }
        let configuration = fixture.configuration()

        XCTAssertThrowsError(
            try fixture.runner(candidates: []).runImmediately(configuration)
        ) { error in
            guard case let .invalidExecutable(path) =
                    error as? TailscaleStatusReaderError else {
                return XCTFail("Expected missing executable error, got \(error)")
            }
            XCTAssertEqual(path, configuration.tailnetTarget?.tailscaleExecutable)
        }
        XCTAssertTrue(try RenewalEngine(
            stateFileURL: configuration.stateFileURL
        ).status(for: configuration.command).isDue)
    }

    private struct Fixture {
        let directory: URL
        let executable: URL

        init() throws {
            directory = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(
                at: directory, withIntermediateDirectories: true
            )
            executable = directory.appendingPathComponent("tailscale")
            let script = """
            #!/bin/sh
            [ "$1" = status ] && [ "$2" = --json ] || exit 41
            [ "$TAILSCALE_BE_CLI" = 1 ] || exit 43
            printf '%s' '{"Peer":{"phone":{"ID":"phone-node","HostName":"phone","DNSName":"phone.example.ts.net.","OS":"iOS","TailscaleIPs":["100.64.0.9"],"Online":true}}}'
            """
            try Data(script.utf8).write(to: executable)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o700], ofItemAtPath: executable.path
            )
        }

        func runner(candidates: [URL]) -> ConfiguredRenewalRunner {
            ConfiguredRenewalRunner(
                executableLocator: TailscaleExecutableLocator(
                    candidateURLs: candidates, applicationURLs: []
                )
            ) { try TailscaleStatusReader().read(executableURL: $0) }
        }

        func configuration(savedExecutable: URL? = nil) -> AgentConfiguration {
            AgentConfiguration(
                stateFileURL: directory.appendingPathComponent("state.json"),
                tailnetTarget: TailnetTarget(
                    tailscaleExecutable: (savedExecutable
                        ?? directory.appendingPathComponent("old/tailscale")).path,
                    nodeID: "phone-node", dnsName: "phone.example.ts.net."
                ),
                command: RenewalCommand(executableURL: URL(fileURLWithPath: "/usr/bin/true"))
            )
        }
    }
}
