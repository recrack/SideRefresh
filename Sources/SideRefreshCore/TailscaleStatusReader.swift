import Foundation

public enum TailscaleStatusReaderError: LocalizedError {
    case commandFailed(exitCode: Int32, message: String)
    case invalidExecutable(String)
    case outputTooLarge

    public var errorDescription: String? {
        switch self {
        case let .commandFailed(exitCode, message):
            if message.isEmpty {
                return "Tailscale status failed with exit code \(exitCode)."
            }
            return "Tailscale status failed: \(message)"
        case let .invalidExecutable(path):
            return "No executable Tailscale CLI was found at \(path)."
        case .outputTooLarge:
            return "Tailscale status exceeded the 4 MiB safety limit."
        }
    }
}

public struct TailscaleStatusReader: Sendable {
    private let runner: BoundedProcessRunner

    public init(
        runner: BoundedProcessRunner = BoundedProcessRunner(
            maximumOutputBytesPerStream: 4 * 1_024 * 1_024,
            environmentOverrides: ["TAILSCALE_BE_CLI": "1"],
            executionTimeout: 30
        )
    ) {
        self.runner = runner
    }

    public func read(
        executableURL: URL
    ) throws -> TailnetSnapshot {
        guard executableURL.isFileURL,
              executableURL.path.hasPrefix("/"),
              FileManager.default.isExecutableFile(
                  atPath: executableURL.path
              )
        else {
            throw TailscaleStatusReaderError.invalidExecutable(
                executableURL.path
            )
        }
        let result = try runner.run(
            RenewalCommand(
                executableURL: executableURL,
                arguments: ["status", "--json"]
            )
        )
        guard !result.standardOutputWasTruncated else {
            throw TailscaleStatusReaderError.outputTooLarge
        }
        guard result.exitCode == 0 else {
            throw TailscaleStatusReaderError.commandFailed(
                exitCode: result.exitCode,
                message: result.standardError
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        return try TailscaleStatusParser.parse(
            Data(result.standardOutput.utf8)
        )
    }
}
