import Foundation
import XCTest
@testable import SideRefreshCore

final class ConfiguredRenewalRunnerTests: XCTestCase {
    func testSideRefreshHelperRequiresAProvisioningReceiptInExecuteMode() {
        let command = RenewalCommand(
            executableURL: URL(
                fileURLWithPath: "/opt/siderefresh/SideRefreshIOSRenewal"
            ),
            arguments: [
                "--execute",
                "--container", "/tmp/App.xcodeproj",
                "--scheme", "App",
                "--team", "ABCDE12345",
                "--bundle-id", "example.app",
                "--product", "App",
                "--device", "device-udid",
                "--derived-data", "/tmp/DerivedData",
            ]
        )

        XCTAssertTrue(
            ConfiguredRenewalRunner
                .requiresProvisioningExpiration(command)
        )
    }

    func testDueRenewalChecksSavedTailnetDeviceBeforeRunning() throws {
        let fixture = try Fixture()
        let updates = RenewalRunUpdateBuffer()
        let runner = ConfiguredRenewalRunner { _ in
            TailnetSnapshot(devices: [
                Self.device(isOnline: true),
            ])
        }

        let result = try runner.runIfDue(
            fixture.configuration,
            progress: updates.append,
            now: fixture.now
        )

        XCTAssertTrue(result.commandWasExecuted)
        XCTAssertTrue(result.succeeded)
        let messages: [String] = updates.drain().compactMap { update in
            guard case .progress(let event) = update else {
                return nil
            }
            return event.message
        }
        XCTAssertTrue(
            messages.contains(
                "Tailscale 주소 확인 완료"
                    + " · phone.example.ts.net."
                    + " · Xcode/CoreDevice 설치를 계속합니다."
            )
        )
        XCTAssertFalse(messages.contains { $0.contains("TailnetDevice(") })
    }

    func testOfflineTailnetDeviceLeavesRenewalDue() throws {
        let fixture = try Fixture()
        let runner = ConfiguredRenewalRunner { _ in
            TailnetSnapshot(devices: [
                Self.device(isOnline: false),
            ])
        }

        XCTAssertThrowsError(
            try runner.runIfDue(
                fixture.configuration,
                now: fixture.now
            )
        ) { error in
            XCTAssertEqual(
                error as? TailnetTargetError,
                .deviceOffline("phone.example.ts.net.")
            )
        }
        XCTAssertTrue(
            try RenewalEngine(
                stateFileURL: fixture.configuration.stateFileURL
            ).status(
                for: fixture.configuration.command,
                now: fixture.now
            ).isDue
        )
    }

    func testNotDueRenewalSkipsTailnetStatusCheck() throws {
        let fixture = try Fixture()
        _ = try RenewalEngine(
            stateFileURL: fixture.configuration.stateFileURL
        ).runIfDue(
            fixture.configuration.command,
            now: fixture.now
        )
        let runner = ConfiguredRenewalRunner { _ in
            throw TestError.unexpectedTailnetRead
        }

        let result = try runner.runIfDue(
            fixture.configuration,
            now: fixture.now.addingTimeInterval(60)
        )

        XCTAssertFalse(result.commandWasExecuted)
        XCTAssertFalse(result.status.isDue)
    }

    func testImmediateRenewalChecksTailnetEvenWhenNotDue() throws {
        let fixture = try Fixture()
        _ = try RenewalEngine(
            stateFileURL: fixture.configuration.stateFileURL
        ).runIfDue(
            fixture.configuration.command,
            now: fixture.now
        )
        let runner = ConfiguredRenewalRunner { _ in
            TailnetSnapshot(devices: [
                Self.device(isOnline: true),
            ])
        }

        let result = try runner.runImmediately(
            fixture.configuration,
            now: fixture.now.addingTimeInterval(60)
        )

        XCTAssertTrue(result.commandWasExecuted)
        XCTAssertTrue(result.succeeded)
    }

    private struct Fixture {
        let configuration: AgentConfiguration
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        init() throws {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent(
                    UUID().uuidString,
                    isDirectory: true
                )
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            configuration = AgentConfiguration(
                stateFileURL: directory.appendingPathComponent("state.json"),
                tailnetTarget: TailnetTarget(
                    tailscaleExecutable: "/usr/bin/true",
                    nodeID: "phone-node",
                    dnsName: "phone.example.ts.net."
                ),
                command: RenewalCommand(
                    executableURL: URL(fileURLWithPath: "/usr/bin/true")
                )
            )
        }
    }

    private enum TestError: Error {
        case unexpectedTailnetRead
    }

    private static func device(isOnline: Bool) -> TailnetDevice {
        TailnetDevice(
            id: "phone-node",
            hostName: "phone",
            dnsName: "phone.example.ts.net.",
            operatingSystem: "iOS",
            addresses: ["100.64.0.9"],
            preferredIPAddress: "100.64.0.9",
            isOnline: isOnline,
            isSelf: false
        )
    }
}
