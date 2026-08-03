import Foundation
import XCTest
@testable import SideRefreshCore
@testable import SideRefreshMCPServer

final class SideRefreshMCPServerTests: XCTestCase {
    func testToolListExposesHeadlessRenewalOperations() {
        let tools = SideRefreshMCPToolHandler.toolDefinitions.compactMap {
            $0.objectValue?["name"]?.stringValue
        }

        XCTAssertEqual(
            tools,
            [
                "get_status",
                "configure_target",
                "dry_run",
                "renew_now",
                "enable_schedule",
                "disable_schedule",
            ]
        )
    }

    func testConfigureTargetWritesDryRunAgentConfiguration() throws {
        let fixture = makeFixture()

        let result = fixture.handler.call(
            name: "configure_target",
            arguments: configurationArguments(
                configPath: fixture.configuration.path
            )
        )

        XCTAssertFalse(result.isError)
        let configuration = try AgentConfiguration.load(
            from: fixture.configuration
        )
        let profile = try IOSAppRenewalProfile(
            arguments: configuration.command.arguments
        )
        XCTAssertEqual(profile.mode, .dryRun)
        XCTAssertEqual(profile.buildStrategy, .incremental)
        XCTAssertEqual(profile.versionPolicy, .keep)
        XCTAssertEqual(configuration.renewEveryHours, 144)
        XCTAssertEqual(
            configuration.command.executable,
            "/usr/bin/true"
        )
        let status = fixture.handler.call(
            name: "get_status",
            arguments: [
                "config_path": .string(
                    fixture.configuration.path
                ),
            ]
        )
        XCTAssertEqual(
            status.structuredContent.objectValue?[
                "bundle_identifier"
            ]?.stringValue,
            "io.github.example.app"
        )
        XCTAssertEqual(
            status.structuredContent.objectValue?[
                "core_device_identifier"
            ]?.stringValue,
            "00008110-001234567890001E"
        )
    }

    func testConfigureTargetRequiresConfirmationBeforeWriting() {
        let fixture = makeFixture()
        var arguments = configurationArguments(
            configPath: fixture.configuration.path
        )
        arguments.removeValue(forKey: "confirm")

        let result = fixture.handler.call(
            name: "configure_target",
            arguments: arguments
        )

        XCTAssertTrue(result.isError)
        XCTAssertTrue(result.content.contains("confirm=true"))
        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: fixture.configuration.path
            )
        )
    }

    func testExecuteConfigurationRequiresExplicitConfirmation() {
        let fixture = makeFixture()
        var arguments = configurationArguments(
            configPath: fixture.configuration.path
        )
        arguments["mode"] = .string("execute")

        let result = fixture.handler.call(
            name: "configure_target",
            arguments: arguments
        )

        XCTAssertTrue(result.isError)
        XCTAssertTrue(result.content.contains("confirm_execute=true"))
        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: fixture.configuration.path
            )
        )
    }

    func testRenewNowRejectsMissingConfirmationBeforeExecution() {
        let fixture = makeFixture()

        let result = fixture.handler.call(
            name: "renew_now",
            arguments: [
                "config_path": .string(
                    fixture.configuration.path
                ),
            ]
        )

        XCTAssertTrue(result.isError)
        XCTAssertTrue(result.content.contains("confirm=true"))
    }

    func testDryRunForcesSavedExecuteTargetToNonMutatingMode() throws {
        let directory = temporaryDirectory()
        let configurationURL = directory.appendingPathComponent(
            "agent-config.json"
        )
        let profile = try IOSAppRenewalProfile(
            arguments: [
                "--execute",
                "--container",
                "/tmp/App.xcodeproj",
                "--scheme",
                "App",
                "--team",
                "ABCDE12345",
                "--bundle-id",
                "io.github.example.app",
                "--product",
                "App",
                "--device",
                "00008110-001234567890001E",
                "--derived-data",
                "/tmp/DerivedData",
            ]
        )
        try AgentConfiguration(
            stateFileURL: directory.appendingPathComponent("state.json"),
            command: profile.command(
                helperExecutableURL: URL(
                    fileURLWithPath: "/usr/bin/true"
                )
            )
        ).write(to: configurationURL)
        let recorder = CommandRecorder()
        let handler = SideRefreshMCPToolHandler(
            defaultConfigurationFileURL: configurationURL,
            helperExecutableURL: URL(
                fileURLWithPath: "/usr/bin/true"
            ),
            agentExecutableURL: URL(
                fileURLWithPath: "/usr/bin/true"
            ),
            launchAgentFileURL: directory.appendingPathComponent(
                "agent.plist"
            ),
            dependencies: recorder.dependencies
        )

        let result = handler.call(name: "dry_run")

        XCTAssertFalse(result.isError)
        XCTAssertEqual(recorder.commands.count, 1)
        XCTAssertEqual(
            recorder.commands.first?.arguments.first,
            "--dry-run"
        )
    }

    func testProtocolInitializeAndToolListUseCurrentMCPShape() throws {
        let fixture = makeFixture()
        let router = SideRefreshMCPProtocolRouter(
            toolHandler: fixture.handler
        )
        let initialize = Data(
            """
            {"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"test","version":"1"}}}
            """.utf8
        )
        let initializeResponse = try decodedObject(
            XCTUnwrap(router.response(to: initialize))
        )
        let initializeResult = try XCTUnwrap(
            initializeResponse["result"]?.objectValue
        )
        XCTAssertEqual(
            initializeResult["protocolVersion"]?.stringValue,
            "2025-11-25"
        )
        XCTAssertNotNil(
            initializeResult["capabilities"]?
                .objectValue?["tools"]
        )
        XCTAssertEqual(
            initializeResult["serverInfo"]?
                .objectValue?["name"]?.stringValue,
            "siderefresh"
        )
        XCTAssertEqual(
            initializeResult["serverInfo"]?
                .objectValue?["title"]?.stringValue,
            "SideRefresh"
        )

        let list = Data(
            """
            {"jsonrpc":"2.0","id":"tools","method":"tools/list","params":{}}
            """.utf8
        )
        let listResponse = try decodedObject(
            XCTUnwrap(router.response(to: list))
        )
        let listedTools = try XCTUnwrap(
            listResponse["result"]?.objectValue?["tools"]?.arrayValue
        )
        XCTAssertEqual(listedTools.count, 6)
    }

    private func makeFixture() -> Fixture {
        let directory = temporaryDirectory()
        let configuration = directory.appendingPathComponent(
            "agent-config.json"
        )
        return Fixture(
            configuration: configuration,
            handler: SideRefreshMCPToolHandler(
                defaultConfigurationFileURL: configuration,
                helperExecutableURL: URL(
                    fileURLWithPath: "/usr/bin/true"
                ),
                agentExecutableURL: URL(
                    fileURLWithPath: "/usr/bin/true"
                ),
                launchAgentFileURL: directory.appendingPathComponent(
                    "io.github.siderefresh.renewal.plist"
                ),
                dependencies: inactiveDependencies()
            )
        )
    }

    private func configurationArguments(
        configPath: String
    ) -> [String: MCPJSONValue] {
        [
            "confirm": .bool(true),
            "config_path": .string(configPath),
            "container": .string("/tmp/App.xcodeproj"),
            "scheme": .string("App"),
            "team": .string("ABCDE12345"),
            "bundle_id": .string("io.github.example.app"),
            "product": .string("App"),
            "device": .string("00008110-001234567890001E"),
            "derived_data": .string("/tmp/DerivedData"),
        ]
    }

    private func temporaryDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory
    }

    private func decodedObject(
        _ data: Data
    ) throws -> [String: MCPJSONValue] {
        try XCTUnwrap(
            JSONDecoder().decode(
                MCPJSONValue.self,
                from: data
            ).objectValue
        )
    }

    private func inactiveDependencies() -> SideRefreshMCPDependencies {
        SideRefreshMCPDependencies(
            runCommand: { _ in
                fatalError("command must not run in this test")
            },
            runImmediately: { _ in
                fatalError("renewal must not run in this test")
            },
            launchctlExecutor:
                HeadlessLaunchAgentCommandExecutor { _ in
                    ProcessResult(
                        exitCode: 1,
                        standardOutput: "",
                        standardError: "not loaded",
                        standardOutputWasTruncated: false,
                        standardErrorWasTruncated: false,
                        timedOut: false
                    )
                }
        )
    }
}

private struct Fixture {
    let configuration: URL
    let handler: SideRefreshMCPToolHandler
}

private final class CommandRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [RenewalCommand] = []

    var commands: [RenewalCommand] {
        lock.withLock { storage }
    }

    var dependencies: SideRefreshMCPDependencies {
        SideRefreshMCPDependencies(
            runCommand: { [self] command in
                lock.withLock {
                    storage.append(command)
                }
                return ProcessResult(
                    exitCode: 0,
                    standardOutput:
                        #"{"mode":"dry-run","system_changes_performed":false}"#,
                    standardError: "",
                    standardOutputWasTruncated: false,
                    standardErrorWasTruncated: false,
                    timedOut: false
                )
            },
            runImmediately: { _ in
                fatalError("renewal must not run in this test")
            },
            launchctlExecutor:
                HeadlessLaunchAgentCommandExecutor { _ in
                    fatalError("launchctl must not run in this test")
                }
        )
    }
}
