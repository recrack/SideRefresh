import XCTest
@testable import SideRefreshCore

final class RenewalLogTextTests: XCTestCase {
    func testLineCountIncludesAnUnterminatedLastLine() {
        XCTAssertEqual(RenewalLogText.lineCount(in: ""), 0)
        XCTAssertEqual(RenewalLogText.lineCount(in: "first"), 1)
        XCTAssertEqual(RenewalLogText.lineCount(in: "first\n"), 1)
        XCTAssertEqual(
            RenewalLogText.lineCount(in: "first\nsecond"),
            2
        )
        XCTAssertEqual(
            RenewalLogText.lineCount(in: "first\n\n"),
            2
        )
    }

    func testPreviewKeepsTheLatestLinesAndReportsOmission() {
        XCTAssertEqual(
            RenewalLogText.preview(
                of: "one\ntwo\nthree\nfour\n",
                maximumLines: 2
            ),
            "… 이전 2줄 생략\nthree\nfour"
        )
    }

    func testPreviewReturnsPlaceholderForEmptyLog() {
        XCTAssertEqual(
            RenewalLogText.preview(
                of: "",
                maximumLines: 6
            ),
            "실행 로그를 기다리는 중…"
        )
    }

    func testMetricsHandleLinesSplitAcrossAppendChunks() {
        var metrics = RenewalLogMetrics(maximumPreviewLines: 3)

        metrics.append("one\nt")
        metrics.append("wo\n\nthr")
        metrics.append("ee")

        XCTAssertEqual(metrics.lineCount, 4)
        XCTAssertEqual(
            metrics.preview,
            "… 이전 1줄 생략\ntwo\n\nthree"
        )
    }

    func testMetricsResetReplacesExistingState() {
        var metrics = RenewalLogMetrics(maximumPreviewLines: 2)
        metrics.append("one\ntwo\nthree")

        metrics.reset(to: "replacement\n")

        XCTAssertEqual(metrics.lineCount, 1)
        XCTAssertEqual(metrics.preview, "replacement")
    }
}
