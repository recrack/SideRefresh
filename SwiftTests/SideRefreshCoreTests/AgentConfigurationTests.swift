import XCTest
@testable import SideRefreshCore

final class AgentConfigurationTests: XCTestCase {
    func testAgentConfigurationCanBeSavedAndLoaded() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let configurationFile = directory.appendingPathComponent("agent.json")
        let stateFile = directory.appendingPathComponent("renewal-state.json")
        let configuration = AgentConfiguration(
            stateFileURL: stateFile,
            tailnetTarget: TailnetTarget(
                tailscaleExecutable: "/Applications/Tailscale",
                nodeID: "iphone-node",
                dnsName: "iphone.example.ts.net."
            ),
            command: RenewalCommand(
                executableURL: URL(fileURLWithPath: "/usr/bin/true")
            )
        )

        try configuration.write(to: configurationFile)
        let loaded = try AgentConfiguration.load(from: configurationFile)

        XCTAssertEqual(loaded, configuration)
    }

    func testAgentConfigurationRejectsANonPositiveRenewalInterval() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let configurationFile = directory.appendingPathComponent("agent.json")
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let json = """
        {
          "state_file": "/tmp/renewal-state.json",
          "renew_every_hours": 0,
          "command": {
            "executable": "/usr/bin/true",
            "arguments": []
          }
        }
        """
        try Data(json.utf8).write(to: configurationFile)

        XCTAssertThrowsError(
            try AgentConfiguration.load(from: configurationFile)
        ) { error in
            XCTAssertEqual(
                error as? RenewalIntervalError,
                .outsideSupportedRange(0)
            )
        }
    }

    func testLegacyConfigurationWithoutTailnetTargetStillLoads() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let configurationFile = directory.appendingPathComponent("agent.json")
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let json = """
        {
          "state_file": "/tmp/renewal-state.json",
          "renew_every_hours": 144,
          "command": {
            "executable": "/usr/bin/true",
            "arguments": []
          }
        }
        """
        try Data(json.utf8).write(to: configurationFile)

        let configuration = try AgentConfiguration.load(
            from: configurationFile
        )

        XCTAssertNil(configuration.tailnetTarget)
    }

    func testAgentConfigurationRejectsAnIntervalBeyondOneWeek() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let configurationFile = directory.appendingPathComponent("agent.json")
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let json = """
        {
          "state_file": "/tmp/renewal-state.json",
          "renew_every_hours": 169,
          "command": {
            "executable": "/usr/bin/true",
            "arguments": []
          }
        }
        """
        try Data(json.utf8).write(to: configurationFile)

        XCTAssertThrowsError(
            try AgentConfiguration.load(from: configurationFile)
        ) { error in
            XCTAssertEqual(
                error as? RenewalIntervalError,
                .outsideSupportedRange(169)
            )
        }
    }
}
