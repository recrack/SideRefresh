import Darwin
import XCTest
@testable import SideRefreshCore

final class BoundedProcessRunnerTests: XCTestCase {
    func testRunnerStreamsBothOutputChannelsBeforeReturning() throws {
        let output = LockedProcessOutput()
        let result = try BoundedProcessRunner().run(
            RenewalCommand(
                executableURL: URL(fileURLWithPath: "/bin/sh"),
                arguments: [
                    "-c",
                    "printf alpha; printf beta >&2",
                ]
            ),
            onOutput: { chunk in
                output.append(chunk)
            }
        )

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(
            output.text(for: .standardOutput),
            "alpha"
        )
        XCTAssertEqual(
            output.text(for: .standardError),
            "beta"
        )
    }

    func testStreamingUTF8DecoderPreservesSplitCharacters() {
        var decoder = ProcessOutputUTF8Decoder()
        let bytes = Array("경로".utf8)

        let first = decoder.append(Data(bytes.prefix(2)))
        let second = decoder.append(Data(bytes.dropFirst(2)))

        XCTAssertEqual(first, "")
        XCTAssertEqual(second, "경로")
        XCTAssertEqual(decoder.finish(), "")
    }

    func testIsolatedModeMarksTheChildAsExternallyContained() throws {
        let runner = BoundedProcessRunner(processGroupMode: .isolated)
        let result = try runner.run(
            RenewalCommand(
                executableURL: URL(fileURLWithPath: "/bin/sh"),
                arguments: [
                    "-c",
                    "printf %s \"$SIDEREFRESH_PROCESS_GROUP_CONTAINMENT\"",
                ]
            )
        )

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.standardOutput, "isolated")
    }

    func testRunnerProvidesExplicitEnvironmentOverridesToChild() throws {
        let runner = BoundedProcessRunner(
            environmentOverrides: ["SIDEREFRESH_TEST_VALUE": "tailnet"]
        )
        let result = try runner.run(
            RenewalCommand(
                executableURL: URL(fileURLWithPath: "/bin/sh"),
                arguments: [
                    "-c",
                    "printf %s \"$SIDEREFRESH_TEST_VALUE\"",
                ]
            )
        )

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.standardOutput, "tailnet")
    }

    func testInheritedModeKeepsTheParentsProcessGroup() throws {
        let runner = BoundedProcessRunner(processGroupMode: .inherited)
        let result = try runner.run(
            RenewalCommand(
                executableURL: URL(fileURLWithPath: "/bin/sh"),
                arguments: ["-c", "ps -o pgid= -p $$"]
            )
        )

        XCTAssertEqual(result.exitCode, 0)
        let processGroup = result.standardOutput.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        XCTAssertEqual(
            Int(processGroup),
            Int(Darwin.getpgrp())
        )
    }

    func testCommandResultContainsExitCodeAndOutput() throws {
        let runner = BoundedProcessRunner()
        let command = RenewalCommand(
            executableURL: URL(fileURLWithPath: "/usr/bin/printf"),
            arguments: ["swift-side-refresh"]
        )

        let result = try runner.run(command)

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.standardOutput, "swift-side-refresh")
        XCTAssertEqual(result.standardError, "")
        XCTAssertFalse(result.standardOutputWasTruncated)
        XCTAssertFalse(result.standardErrorWasTruncated)
    }

    func testBothOutputStreamsAreBounded() throws {
        let runner = BoundedProcessRunner(maximumOutputBytesPerStream: 1_024)
        let command = RenewalCommand(
            executableURL: URL(fileURLWithPath: "/bin/sh"),
            arguments: [
                "-c",
                """
                i=0
                while [ "$i" -lt 3000 ]; do
                    printf x
                    printf y >&2
                    i=$((i + 1))
                done
                """,
            ]
        )

        let result = try runner.run(command)

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.standardOutputWasTruncated)
        XCTAssertTrue(result.standardErrorWasTruncated)
        XCTAssertTrue(result.standardOutput.hasSuffix(String(repeating: "x", count: 1_024)))
        XCTAssertTrue(result.standardError.hasSuffix(String(repeating: "y", count: 1_024)))
    }

    func testTailBufferPreservesExactSuffixAcrossIncrementalWraps() {
        var buffer = BoundedProcessRunner.TailBuffer(limit: 5)

        buffer.append(Data("abc".utf8))
        buffer.append(Data("defg".utf8))
        buffer.append(Data("h".utf8))

        let rendered = buffer.rendered()

        XCTAssertEqual(
            rendered.text,
            "[3 earlier bytes omitted]\ndefgh"
        )
        XCTAssertTrue(rendered.truncated)
    }

    func testRunnerStopsDrainingAfterTheDirectCommandExits() throws {
        let runner = BoundedProcessRunner(descendantPipeGracePeriod: 0.2)
        let command = RenewalCommand(
            executableURL: URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "(sleep 2) &"]
        )

        let startedAt = Date()
        let result = try runner.run(command)
        let elapsed = Date().timeIntervalSince(startedAt)

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertLessThan(elapsed, 1.5)
    }

    func testHungCommandIsTerminatedAtTheExecutionDeadline() throws {
        let runner = BoundedProcessRunner(
            descendantPipeGracePeriod: 0.2,
            executionTimeout: 0.3,
            terminationGracePeriod: 0.1
        )
        let command = RenewalCommand(
            executableURL: URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "sleep 3"]
        )

        let startedAt = Date()
        let result = try runner.run(command)
        let elapsed = Date().timeIntervalSince(startedAt)

        XCTAssertTrue(result.timedOut)
        XCTAssertEqual(result.exitCode, 124)
        XCTAssertLessThan(elapsed, 1.5)
    }
}

private final class LockedProcessOutput: @unchecked Sendable {
    private let lock = NSLock()
    private var chunks: [ProcessOutputChunk] = []

    func append(_ chunk: ProcessOutputChunk) {
        lock.lock()
        chunks.append(chunk)
        lock.unlock()
    }

    func text(for stream: ProcessOutputStream) -> String {
        lock.lock()
        defer { lock.unlock() }
        return chunks
            .filter { $0.stream == stream }
            .map(\.text)
            .joined()
    }
}
