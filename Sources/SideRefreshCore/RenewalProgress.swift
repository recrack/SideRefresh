import Darwin
import Foundation

public enum RenewalProgressPhase:
    String,
    Codable,
    CaseIterable,
    Hashable,
    Sendable
{
    case preparing
    case checkingConnection
    case cleaningBuild
    case building
    case validatingApp
    case readingProfile
    case installing
    case recordingReceipt
    case completed
}

public enum RenewalProgressState:
    String,
    Codable,
    Hashable,
    Sendable
{
    case started
    case succeeded
    case failed
}

public struct RenewalProgressEvent: Codable, Equatable, Sendable {
    public let phase: RenewalProgressPhase
    public let state: RenewalProgressState
    public let message: String

    public init(
        phase: RenewalProgressPhase,
        state: RenewalProgressState,
        message: String
    ) {
        self.phase = phase
        self.state = state
        self.message = message
    }
}

public enum RenewalRunUpdate: Equatable, Sendable {
    case progress(RenewalProgressEvent)
    case log(String)
}

public typealias RenewalProgressHandler =
    @Sendable (RenewalRunUpdate) -> Void

public enum RenewalProgressWire {
    public static let prefix = "@@SIDEREFRESH_PROGRESS@@"

    public static func line(
        for event: RenewalProgressEvent
    ) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let payload = try encoder.encode(event)
        return prefix + String(decoding: payload, as: UTF8.self) + "\n"
    }

    public static func write(
        _ event: RenewalProgressEvent,
        to descriptor: Int32 = STDERR_FILENO
    ) {
        guard let line = try? line(for: event) else {
            return
        }
        SideRefreshJSONOutput.writeError("\n" + line, to: descriptor)
    }

    static func decode(_ line: String) -> RenewalProgressEvent? {
        guard line.hasPrefix(prefix) else {
            return nil
        }
        let payload = line.dropFirst(prefix.count)
        return try? JSONDecoder().decode(
            RenewalProgressEvent.self,
            from: Data(payload.utf8)
        )
    }
}

public final class RenewalProgressStreamDecoder:
    @unchecked Sendable
{
    private let lock = NSLock()
    private let maximumPendingCharacters: Int
    private var pendingText = ""

    public init(maximumPendingCharacters: Int = 65_536) {
        self.maximumPendingCharacters = max(
            1,
            maximumPendingCharacters
        )
    }

    public func append(_ text: String) -> [RenewalRunUpdate] {
        lock.lock()
        defer { lock.unlock() }
        pendingText.append(text)
        var updates: [RenewalRunUpdate] = []
        while true {
            if let newline = pendingText.firstIndex(of: "\n"),
               pendingText.distance(
                   from: pendingText.startIndex,
                   to: newline
               ) <= maximumPendingCharacters
            {
                if let update = popLine(endingAt: newline) {
                    updates.append(update)
                }
                continue
            }
            guard pendingText.count > maximumPendingCharacters else {
                break
            }
            let boundary = pendingText.index(
                pendingText.startIndex,
                offsetBy: maximumPendingCharacters
            )
            updates.append(
                .log(String(pendingText[..<boundary]))
            )
            pendingText.removeSubrange(..<boundary)
        }
        return updates
    }

    public func finish() -> [RenewalRunUpdate] {
        lock.lock()
        defer { lock.unlock() }
        var updates = drainCompleteLines()
        if !pendingText.isEmpty {
            updates.append(.log(pendingText))
            pendingText = ""
        }
        return updates
    }

    private func drainCompleteLines() -> [RenewalRunUpdate] {
        var updates: [RenewalRunUpdate] = []
        while let newline = pendingText.firstIndex(of: "\n") {
            if let update = popLine(endingAt: newline) {
                updates.append(update)
            }
        }
        return updates
    }

    private func popLine(
        endingAt newline: String.Index
    ) -> RenewalRunUpdate? {
        let line = String(pendingText[..<newline])
        pendingText.removeSubrange(...newline)
        if let event = RenewalProgressWire.decode(line) {
            return .progress(event)
        }
        return line.isEmpty ? nil : .log(line + "\n")
    }
}

public final class RenewalRunUpdateBuffer:
    @unchecked Sendable
{
    private let lock = NSLock()
    private let maximumLogCharacters: Int
    private var queuedUpdates: [RenewalRunUpdate] = []
    private var queuedLogCharacters = 0

    public init(maximumLogCharacters: Int = 300_000) {
        self.maximumLogCharacters = max(1, maximumLogCharacters)
    }

    public func append(_ update: RenewalRunUpdate) {
        lock.lock()
        defer { lock.unlock() }
        switch update {
        case .progress:
            queuedUpdates.append(update)
        case .log(let text):
            guard !text.isEmpty else {
                return
            }
            queuedUpdates.append(update)
            queuedLogCharacters += text.count
            trimOldestLogs()
        }
    }

    public func drain() -> [RenewalRunUpdate] {
        lock.lock()
        let updates = queuedUpdates
        queuedUpdates = []
        queuedLogCharacters = 0
        lock.unlock()
        return Self.coalescedUpdates(updates)
    }

    private static func coalescedUpdates(
        _ updates: [RenewalRunUpdate]
    ) -> [RenewalRunUpdate] {
        var result: [RenewalRunUpdate] = []
        var pendingLog = ""
        for update in updates {
            switch update {
            case .progress:
                if !pendingLog.isEmpty {
                    result.append(.log(pendingLog))
                    pendingLog = ""
                }
                result.append(update)
            case .log(let text):
                pendingLog.append(text)
            }
        }
        if !pendingLog.isEmpty {
            result.append(.log(pendingLog))
        }
        return result
    }

    private func trimOldestLogs() {
        var overflow =
            queuedLogCharacters - maximumLogCharacters
        var index = 0
        while overflow > 0, index < queuedUpdates.count {
            guard case .log(let text) = queuedUpdates[index] else {
                index += 1
                continue
            }
            if text.count <= overflow {
                overflow -= text.count
                queuedLogCharacters -= text.count
                queuedUpdates.remove(at: index)
                continue
            }
            let retainedStart = text.index(
                text.startIndex,
                offsetBy: overflow
            )
            queuedUpdates[index] =
                .log(String(text[retainedStart...]))
            queuedLogCharacters -= overflow
            overflow = 0
        }
    }
}
