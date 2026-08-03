import XCTest
@testable import SideRefreshCore

final class RenewalProgressTests: XCTestCase {
    func testDecoderSeparatesSplitProgressEventsFromLogs() throws {
        let event = RenewalProgressEvent(
            phase: .building,
            state: .started,
            message: "Xcode build started"
        )
        let wireLine = try RenewalProgressWire.line(for: event)
        let splitIndex = wireLine.index(
            wireLine.startIndex,
            offsetBy: wireLine.count / 2
        )
        let decoder = RenewalProgressStreamDecoder()

        let first = decoder.append(
            "build log\n" + wireLine[..<splitIndex]
        )
        let second = decoder.append(
            String(wireLine[splitIndex...]) + "next log\n"
        )

        XCTAssertEqual(first, [.log("build log\n")])
        XCTAssertEqual(
            second,
            [
                .progress(event),
                .log("next log\n"),
            ]
        )
        XCTAssertTrue(decoder.finish().isEmpty)
    }

    func testDecoderKeepsAnIncompleteFinalLogLine() {
        let decoder = RenewalProgressStreamDecoder()

        XCTAssertTrue(decoder.append("partial").isEmpty)
        XCTAssertEqual(decoder.finish(), [.log("partial")])
    }

    func testDecoderFlushesALongLineBeforeItCanGrowWithoutBound() {
        let decoder = RenewalProgressStreamDecoder(
            maximumPendingCharacters: 16
        )

        let updates = decoder.append(String(repeating: "x", count: 40))

        XCTAssertEqual(
            updates,
            [
                .log(String(repeating: "x", count: 16)),
                .log(String(repeating: "x", count: 16)),
            ]
        )
        XCTAssertEqual(
            decoder.finish(),
            [.log(String(repeating: "x", count: 8))]
        )
    }

    func testUpdateBufferIsBoundedAndPreservesProgressOrder() {
        let buffer = RenewalRunUpdateBuffer(
            maximumLogCharacters: 12
        )
        let started = RenewalProgressEvent(
            phase: .building,
            state: .started,
            message: "Started"
        )
        let finished = RenewalProgressEvent(
            phase: .building,
            state: .succeeded,
            message: "Finished"
        )

        buffer.append(.progress(started))
        buffer.append(.log("1234567890"))
        buffer.append(.log("abcdefghij"))
        buffer.append(.progress(finished))

        XCTAssertEqual(
            buffer.drain(),
            [
                .progress(started),
                .log("90abcdefghij"),
                .progress(finished),
            ]
        )
        XCTAssertTrue(buffer.drain().isEmpty)
    }
}
