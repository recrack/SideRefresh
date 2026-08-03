import XCTest
@testable import SideRefreshCore

final class RenewalEngineTests: XCTestCase {
    func testImmediateRunStreamsHelperProgressAndLogs() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let stateFile = directory.appendingPathComponent("state.json")
        let event = RenewalProgressEvent(
            phase: .building,
            state: .started,
            message: "Building the app"
        )
        let wireLine = try RenewalProgressWire.line(for: event)
        let updates = LockedRenewalUpdates()
        let command = RenewalCommand(
            executableURL: URL(fileURLWithPath: "/bin/sh"),
            arguments: [
                "-c",
                """
                printf '%s' "$1" >&2
                printf '%s\\n' 'live build output' >&2
                printf '%s\\n' '{"provisioning_expiration_date":"2026-08-01T12:00:00Z"}'
                """,
                "side-refresh-progress-test",
                wireLine,
            ]
        )

        let result = try RenewalEngine(
            stateFileURL: stateFile
        ).runImmediately(
            command,
            progress: { update in
                updates.append(update)
            }
        )

        XCTAssertTrue(result.succeeded)
        XCTAssertTrue(updates.values.contains(.progress(event)))
        XCTAssertTrue(
            updates.values.contains(.log("live build output\n"))
        )
        XCTAssertTrue(
            updates.values.contains {
                guard case .progress(let event) = $0 else {
                    return false
                }
                return event.phase == .recordingReceipt
                    && event.state == .succeeded
            }
        )
    }

    func testSuccessfulCommandIsSkippedUntilRenewalIsDueAgain() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let stateFile = directory.appendingPathComponent("renewal-state.json")
        let markerFile = directory.appendingPathComponent("renewed")
        let engine = RenewalEngine(stateFileURL: stateFile)
        let command = RenewalCommand(
            executableURL: URL(fileURLWithPath: "/usr/bin/touch"),
            arguments: [markerFile.path]
        )
        let firstAttempt = Date(timeIntervalSince1970: 1_700_000_000)

        let first = try engine.runIfDue(command, now: firstAttempt)
        let second = try engine.runIfDue(
            command,
            now: firstAttempt.addingTimeInterval(60 * 60)
        )

        XCTAssertTrue(first.commandWasExecuted)
        XCTAssertTrue(first.succeeded)
        XCTAssertTrue(first.stateWasUpdated)
        XCTAssertTrue(FileManager.default.fileExists(atPath: markerFile.path))
        XCTAssertFalse(second.commandWasExecuted)
        XCTAssertFalse(second.status.isDue)
    }

    func testFailedCommandRemainsDueForTheNextAttempt() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let stateFile = directory.appendingPathComponent("renewal-state.json")
        let engine = RenewalEngine(stateFileURL: stateFile)
        let command = RenewalCommand(
            executableURL: URL(fileURLWithPath: "/usr/bin/false")
        )
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let first = try engine.runIfDue(command, now: now)
        let second = try engine.runIfDue(command, now: now)

        XCTAssertTrue(first.commandWasExecuted)
        XCTAssertFalse(first.succeeded)
        XCTAssertFalse(first.stateWasUpdated)
        XCTAssertTrue(second.commandWasExecuted)
        XCTAssertTrue(second.status.isDue)
    }

    func testChangingTheCommandMakesRenewalDueImmediately() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let stateFile = directory.appendingPathComponent("renewal-state.json")
        let engine = RenewalEngine(stateFileURL: stateFile)
        let dryRun = RenewalCommand(
            executableURL: URL(fileURLWithPath: "/usr/bin/true"),
            arguments: ["--dry-run"]
        )
        let execute = RenewalCommand(
            executableURL: URL(fileURLWithPath: "/usr/bin/true"),
            arguments: ["--execute"]
        )
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let first = try engine.runIfDue(dryRun, now: now)
        let second = try engine.runIfDue(
            execute,
            now: now.addingTimeInterval(60)
        )

        XCTAssertTrue(first.succeeded)
        XCTAssertTrue(second.commandWasExecuted)
        XCTAssertTrue(second.succeeded)
    }

    func testImmediateRunDoesNotWaitForSchedule() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let stateFile = directory.appendingPathComponent("renewal-state.json")
        let markerFile = directory.appendingPathComponent("renewed")
        let engine = RenewalEngine(stateFileURL: stateFile)
        let command = RenewalCommand(
            executableURL: URL(fileURLWithPath: "/usr/bin/touch"),
            arguments: [markerFile.path]
        )
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        _ = try engine.runIfDue(command, now: now)
        try FileManager.default.removeItem(at: markerFile)

        let result = try engine.runImmediately(
            command,
            now: now.addingTimeInterval(60)
        )

        XCTAssertTrue(result.commandWasExecuted)
        XCTAssertTrue(result.succeeded)
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: markerFile.path)
        )
    }

    func testSuccessfulHelperOutputStoresProvisioningExpiration() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let stateFile = directory.appendingPathComponent("renewal-state.json")
        let engine = RenewalEngine(stateFileURL: stateFile)
        let expiration = "2026-08-01T12:00:00Z"
        let command = RenewalCommand(
            executableURL: URL(fileURLWithPath: "/bin/echo"),
            arguments: [
                "{\"provisioning_expiration_date\":\"\(expiration)\",\"provisioning_profile_identifier\":\"PROFILE-UUID\"}",
            ]
        )

        let result = try engine.runIfDue(command)

        XCTAssertNotNil(result.provisioningExpirationDate)
        XCTAssertEqual(
            result.provisioningProfileIdentifier,
            "PROFILE-UUID"
        )
        XCTAssertEqual(
            result.status.provisioningExpirationDate,
            result.provisioningExpirationDate
        )
    }

    func testExpirationIsRecoveredFromTruncatedHelperOutput() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let stateFile = directory.appendingPathComponent("renewal-state.json")
        let engine = RenewalEngine(stateFileURL: stateFile)
        let command = RenewalCommand(
            executableURL: URL(fileURLWithPath: "/bin/sh"),
            arguments: [
                "-c",
                """
                printf '"provisioning_expiration_date":"2020-01-01T00:00:00Z"\\n'
                yes x | head -c 70000
                printf '"provisioning_expiration_date":"2026-08-01T12:00:00Z","provisioning_profile_identifier":"PROFILE-UUID"}\\n'
                """,
            ]
        )

        let result = try engine.runIfDue(command)

        XCTAssertNotNil(result.provisioningExpirationDate)
        XCTAssertEqual(
            result.provisioningProfileIdentifier,
            "PROFILE-UUID"
        )
    }

    func testRequiredExpirationIsNotRecordedWhenReceiptIsMissing() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let stateFile = directory.appendingPathComponent("renewal-state.json")
        let engine = RenewalEngine(stateFileURL: stateFile)
        let command = RenewalCommand(
            executableURL: URL(fileURLWithPath: "/usr/bin/true")
        )

        XCTAssertThrowsError(
            try engine.runIfDue(
                command,
                requiresProvisioningExpiration: true
            )
        ) { error in
            XCTAssertEqual(
                error as? RenewalEngineError,
                .provisioningExpirationMissing
            )
        }
        XCTAssertTrue(
            try engine.status(for: command).isDue
        )
    }
}

private final class LockedRenewalUpdates: @unchecked Sendable {
    private let lock = NSLock()
    private var storedValues: [RenewalRunUpdate] = []

    var values: [RenewalRunUpdate] {
        lock.lock()
        defer { lock.unlock() }
        return storedValues
    }

    func append(_ update: RenewalRunUpdate) {
        lock.lock()
        storedValues.append(update)
        lock.unlock()
    }
}
