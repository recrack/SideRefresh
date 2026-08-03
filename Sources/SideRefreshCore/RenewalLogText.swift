public enum RenewalLogText {
    public static func lineCount(in text: String) -> Int {
        var metrics = RenewalLogMetrics()
        metrics.append(text)
        return metrics.lineCount
    }

    public static func preview(
        of text: String,
        maximumLines: Int
    ) -> String {
        var metrics = RenewalLogMetrics(
            maximumPreviewLines: maximumLines
        )
        metrics.append(text)
        return metrics.preview
    }
}

public struct RenewalLogMetrics: Sendable {
    public private(set) var lineCount = 0

    private let maximumPreviewLines: Int
    private var completedLineCount = 0
    private var recentCompletedLines: [String] = []
    private var pendingLine = ""

    public init(maximumPreviewLines: Int = 8) {
        self.maximumPreviewLines = max(1, maximumPreviewLines)
    }

    public var preview: String {
        guard lineCount > 0 else {
            return "실행 로그를 기다리는 중…"
        }

        var latestLines = recentCompletedLines
        if !pendingLine.isEmpty {
            latestLines.append(pendingLine)
        }
        if latestLines.count > maximumPreviewLines {
            latestLines.removeFirst(
                latestLines.count - maximumPreviewLines
            )
        }

        let omittedLineCount = max(
            0,
            lineCount - latestLines.count
        )
        let visibleText = latestLines.joined(separator: "\n")
        guard omittedLineCount > 0 else {
            return visibleText
        }
        return "… 이전 \(omittedLineCount)줄 생략\n\(visibleText)"
    }

    public mutating func append(_ text: String) {
        guard !text.isEmpty else {
            return
        }

        let segments = text.split(
            separator: "\n",
            omittingEmptySubsequences: false
        )
        guard segments.count > 1 else {
            pendingLine.append(text)
            updateLineCount()
            return
        }

        appendCompletedLine(
            pendingLine + String(segments[0])
        )
        for segment in segments.dropFirst().dropLast() {
            appendCompletedLine(String(segment))
        }
        pendingLine = String(segments.last ?? "")
        updateLineCount()
    }

    public mutating func reset(to text: String = "") {
        completedLineCount = 0
        recentCompletedLines.removeAll(keepingCapacity: true)
        pendingLine = ""
        lineCount = 0
        append(text)
    }

    private mutating func appendCompletedLine(_ line: String) {
        completedLineCount += 1
        recentCompletedLines.append(line)
        if recentCompletedLines.count > maximumPreviewLines {
            recentCompletedLines.removeFirst(
                recentCompletedLines.count - maximumPreviewLines
            )
        }
    }

    private mutating func updateLineCount() {
        lineCount =
            completedLineCount + (pendingLine.isEmpty ? 0 : 1)
    }
}
