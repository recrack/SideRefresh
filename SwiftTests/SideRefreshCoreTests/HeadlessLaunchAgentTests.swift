import Foundation
import XCTest
@testable import SideRefreshCore

final class HeadlessLaunchAgentTests: XCTestCase {
    func testPropertyListRunsAgentAtSixHourCalendarIntervals() throws {
        let controller = HeadlessLaunchAgentController(
            agentExecutableURL: URL(
                fileURLWithPath: "/opt/siderefresh/SideRefreshAgent"
            ),
            configurationFileURL: URL(
                fileURLWithPath: "/tmp/agent-config.json"
            ),
            launchAgentFileURL: URL(
                fileURLWithPath: "/tmp/io.github.siderefresh.renewal.plist"
            ),
            userIdentifier: 501
        )

        let propertyList = try XCTUnwrap(
            PropertyListSerialization.propertyList(
                from: try controller.propertyListData(),
                format: nil
            ) as? [String: Any]
        )

        XCTAssertEqual(
            propertyList["Label"] as? String,
            "io.github.siderefresh.renewal"
        )
        XCTAssertEqual(
            propertyList["ProgramArguments"] as? [String],
            [
                "/opt/siderefresh/SideRefreshAgent",
                "--config",
                "/tmp/agent-config.json",
            ]
        )
        XCTAssertEqual(propertyList["RunAtLoad"] as? Bool, true)
        let intervals = try XCTUnwrap(
            propertyList["StartCalendarInterval"]
                as? [[String: Int]]
        )
        XCTAssertEqual(intervals.map { $0["Hour"] }, [0, 6, 12, 18])
        XCTAssertEqual(intervals.map { $0["Minute"] }, [0, 0, 0, 0])
    }

    func testEnableWritesPrivatePlistAndBootstrapsUserAgent() throws {
        let directory = temporaryDirectory()
        let agent = directory.appendingPathComponent("SideRefreshAgent")
        let config = directory.appendingPathComponent("agent-config.json")
        let plist = directory.appendingPathComponent("LaunchAgents")
            .appendingPathComponent(
                "io.github.siderefresh.renewal.plist"
            )
        try Data().write(to: agent)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: agent.path
        )
        try AgentConfiguration(
            stateFileURL: directory.appendingPathComponent("state.json"),
            command: RenewalCommand(
                executableURL: URL(fileURLWithPath: "/usr/bin/true")
            )
        ).write(to: config)
        let recorder = LaunchctlRecorder()
        let controller = HeadlessLaunchAgentController(
            agentExecutableURL: agent,
            configurationFileURL: config,
            launchAgentFileURL: plist,
            userIdentifier: 502,
            commandExecutor: recorder.executor
        )

        let status = try controller.enable()

        XCTAssertEqual(status.state, .enabled)
        XCTAssertEqual(status.configurationPath, config.path)
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: plist.path)
        )
        let permissions = try XCTUnwrap(
            FileManager.default.attributesOfItem(atPath: plist.path)[
                .posixPermissions
            ] as? NSNumber
        )
        XCTAssertEqual(permissions.intValue, 0o600)
        XCTAssertEqual(
            recorder.commands.map(\.arguments),
            [
                [
                    "print",
                    "gui/502/io.github.siderefresh.renewal",
                ],
                [
                    "bootout",
                    "gui/502/io.github.siderefresh.renewal",
                ],
                [
                    "bootstrap",
                    "gui/502",
                    plist.path,
                ],
            ]
        )
    }

    func testDisableBootsOutAndRemovesOnlyLaunchAgentPlist() throws {
        let directory = temporaryDirectory()
        let plist = directory.appendingPathComponent(
            "io.github.siderefresh.renewal.plist"
        )
        try Data("installed".utf8).write(to: plist)
        let recorder = LaunchctlRecorder()
        let controller = HeadlessLaunchAgentController(
            agentExecutableURL:
                directory.appendingPathComponent("SideRefreshAgent"),
            configurationFileURL:
                directory.appendingPathComponent("agent-config.json"),
            launchAgentFileURL: plist,
            userIdentifier: 503,
            commandExecutor: recorder.executor
        )

        let status = try controller.disable()

        XCTAssertEqual(status.state, .disabled)
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: plist.path)
        )
        XCTAssertEqual(
            recorder.commands.map(\.arguments),
            [[
                "print",
                "gui/503/io.github.siderefresh.renewal",
            ], [
                "bootout",
                "gui/503/io.github.siderefresh.renewal",
            ]]
        )
    }

    func testDisableBootsOutAServiceWhenItsPlistIsAlreadyMissing() throws {
        let directory = temporaryDirectory()
        let recorder = LaunchctlRecorder()
        let controller = HeadlessLaunchAgentController(
            agentExecutableURL:
                directory.appendingPathComponent("SideRefreshAgent"),
            configurationFileURL:
                directory.appendingPathComponent("agent-config.json"),
            launchAgentFileURL:
                directory.appendingPathComponent("missing.plist"),
            userIdentifier: 504,
            commandExecutor: recorder.executor
        )

        let status = try controller.disable()

        XCTAssertEqual(status.state, .disabled)
        XCTAssertEqual(
            recorder.commands.map(\.arguments),
            [[
                "print",
                "gui/504/io.github.siderefresh.renewal",
            ], [
                "bootout",
                "gui/504/io.github.siderefresh.renewal",
            ]]
        )
    }

    func testDisableKeepsPlistWhenBootoutFails() throws {
        let directory = temporaryDirectory()
        let plist = directory.appendingPathComponent(
            "io.github.siderefresh.renewal.plist"
        )
        try Data("installed".utf8).write(to: plist)
        let recorder = LaunchctlRecorder(
            actionExitCodes: ["bootout": 5]
        )
        let controller = HeadlessLaunchAgentController(
            agentExecutableURL:
                directory.appendingPathComponent("SideRefreshAgent"),
            configurationFileURL:
                directory.appendingPathComponent("agent-config.json"),
            launchAgentFileURL: plist,
            userIdentifier: 506,
            commandExecutor: recorder.executor
        )

        XCTAssertThrowsError(try controller.disable()) { error in
            XCTAssertEqual(
                error as? HeadlessLaunchAgentError,
                .launchctlFailed(
                    action: "bootout",
                    message: "exit code 5"
                )
            )
        }
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: plist.path)
        )
    }

    func testEnableKeepsExistingPlistWhenBootoutFails() throws {
        let directory = temporaryDirectory()
        let agent = directory.appendingPathComponent("SideRefreshAgent")
        let config = directory.appendingPathComponent("agent-config.json")
        let plist = directory.appendingPathComponent(
            "io.github.siderefresh.renewal.plist"
        )
        try Data().write(to: agent)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: agent.path
        )
        try AgentConfiguration(
            stateFileURL: directory.appendingPathComponent("state.json"),
            command: RenewalCommand(
                executableURL: URL(fileURLWithPath: "/usr/bin/true")
            )
        ).write(to: config)
        let originalPlist = Data("original".utf8)
        try originalPlist.write(to: plist)
        let recorder = LaunchctlRecorder(
            actionExitCodes: ["bootout": 5]
        )
        let controller = HeadlessLaunchAgentController(
            agentExecutableURL: agent,
            configurationFileURL: config,
            launchAgentFileURL: plist,
            userIdentifier: 508,
            commandExecutor: recorder.executor
        )

        XCTAssertThrowsError(try controller.enable())
        XCTAssertEqual(try Data(contentsOf: plist), originalPlist)
    }

    func testStatusFindsALoadedServiceWithoutAPlist() throws {
        let directory = temporaryDirectory()
        let recorder = LaunchctlRecorder(exitCode: 0)
        let controller = HeadlessLaunchAgentController(
            agentExecutableURL:
                directory.appendingPathComponent("SideRefreshAgent"),
            configurationFileURL:
                directory.appendingPathComponent("agent-config.json"),
            launchAgentFileURL:
                directory.appendingPathComponent("missing.plist"),
            userIdentifier: 505,
            commandExecutor: recorder.executor
        )

        let status = try controller.status()

        XCTAssertEqual(status.state, .enabled)
        XCTAssertNil(status.configurationPath)
        XCTAssertEqual(
            recorder.commands.map(\.arguments),
            [[
                "print",
                "gui/505/io.github.siderefresh.renewal",
            ]]
        )
    }

    func testStatusReportsConfigurationStoredInAnUnloadedPlist()
        throws
    {
        let directory = temporaryDirectory()
        let plist = directory.appendingPathComponent(
            "io.github.siderefresh.renewal.plist"
        )
        let configuration = directory.appendingPathComponent(
            "agent-config.json"
        )
        let recorder = LaunchctlRecorder(exitCode: 1)
        let controller = HeadlessLaunchAgentController(
            agentExecutableURL:
                directory.appendingPathComponent("SideRefreshAgent"),
            configurationFileURL: configuration,
            launchAgentFileURL: plist,
            userIdentifier: 507,
            commandExecutor: recorder.executor
        )
        try controller.propertyListData().write(to: plist)

        let status = try controller.status()

        XCTAssertEqual(status.state, .installedNotLoaded)
        XCTAssertEqual(
            status.configurationPath,
            configuration.path
        )
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
}

private final class LaunchctlRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [RenewalCommand] = []
    private let exitCode: Int32
    private let actionExitCodes: [String: Int32]

    init(
        exitCode: Int32 = 0,
        actionExitCodes: [String: Int32] = [:]
    ) {
        self.exitCode = exitCode
        self.actionExitCodes = actionExitCodes
    }

    var commands: [RenewalCommand] {
        lock.withLock { storage }
    }

    var executor: HeadlessLaunchAgentCommandExecutor {
        HeadlessLaunchAgentCommandExecutor { [self] command in
            lock.withLock {
                storage.append(command)
            }
            return ProcessResult(
                exitCode:
                    command.arguments.first.flatMap {
                        actionExitCodes[$0]
                    } ?? exitCode,
                standardOutput: "",
                standardError: "",
                standardOutputWasTruncated: false,
                standardErrorWasTruncated: false,
                timedOut: false
            )
        }
    }
}
