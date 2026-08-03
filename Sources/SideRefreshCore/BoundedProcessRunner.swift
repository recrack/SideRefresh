import Darwin
import Foundation

public struct RenewalCommand: Codable, Equatable, Sendable {
    public let executable: String
    public let arguments: [String]

    public init(executableURL: URL, arguments: [String] = []) {
        executable = executableURL.standardizedFileURL.path
        self.arguments = arguments
    }

    public var executableURL: URL {
        URL(fileURLWithPath: executable)
    }
}

public struct ProcessResult: Codable, Equatable, Sendable {
    public let exitCode: Int32
    public let standardOutput: String
    public let standardError: String
    public let standardOutputWasTruncated: Bool
    public let standardErrorWasTruncated: Bool
    public let timedOut: Bool
}

public enum ProcessOutputStream: String, Codable, Sendable {
    case standardOutput
    case standardError
}

public struct ProcessOutputChunk: Equatable, Sendable {
    public let stream: ProcessOutputStream
    public let text: String

    public init(stream: ProcessOutputStream, text: String) {
        self.stream = stream
        self.text = text
    }
}

public typealias ProcessOutputHandler =
    @Sendable (ProcessOutputChunk) -> Void

struct ProcessOutputUTF8Decoder {
    private var pendingBytes = Data()

    mutating func append(_ data: Data) -> String {
        pendingBytes.append(data)
        let suffixLength = incompleteSuffixLength(in: pendingBytes)
        let completeCount = pendingBytes.count - suffixLength
        guard completeCount > 0 else {
            return ""
        }
        let text = String(
            decoding: pendingBytes.prefix(completeCount),
            as: UTF8.self
        )
        if suffixLength == 0 {
            pendingBytes.removeAll(keepingCapacity: true)
        } else {
            pendingBytes = Data(
                pendingBytes.suffix(suffixLength)
            )
        }
        return text
    }

    mutating func finish() -> String {
        defer { pendingBytes.removeAll(keepingCapacity: false) }
        return String(decoding: pendingBytes, as: UTF8.self)
    }

    private func incompleteSuffixLength(in data: Data) -> Int {
        guard !data.isEmpty else {
            return 0
        }
        var index = data.index(before: data.endIndex)
        var continuationCount = 0
        while data[index] >= 0x80,
              data[index] <= 0xBF,
              continuationCount < 3
        {
            continuationCount += 1
            guard index != data.startIndex else {
                return 0
            }
            index = data.index(before: index)
        }

        let expectedLength: Int
        switch data[index] {
        case 0xC2...0xDF:
            expectedLength = 2
        case 0xE0...0xEF:
            expectedLength = 3
        case 0xF0...0xF4:
            expectedLength = 4
        default:
            return 0
        }
        let availableLength = data.distance(
            from: index,
            to: data.endIndex
        )
        return availableLength < expectedLength
            ? availableLength
            : 0
    }
}

public enum ProcessGroupMode: Sendable {
    case isolated
    case inherited
}

public struct BoundedProcessRunner: Sendable {
    public static let containmentEnvironmentKey =
        "SIDEREFRESH_PROCESS_GROUP_CONTAINMENT"
    public static let containmentEnvironmentValue = "isolated"

    private struct SpawnedProcess {
        let processID: pid_t
        let standardOutputDescriptor: Int32
        let standardErrorDescriptor: Int32
    }

    private struct FilePipe {
        var readDescriptor: Int32
        var writeDescriptor: Int32
    }

    struct TailBuffer {
        let limit: Int
        var storage: [UInt8]
        var startIndex = 0
        var retainedByteCount = 0
        var totalBytes = 0

        init(limit: Int) {
            self.limit = limit
            storage = []
        }

        mutating func append(_ chunk: Data) {
            guard !chunk.isEmpty else {
                return
            }
            totalBytes += chunk.count

            if chunk.count >= limit {
                storage = Array(chunk.suffix(limit))
                startIndex = 0
                retainedByteCount = limit
                return
            }

            var retainedChunk = chunk[...]
            if storage.count < limit {
                let appendedCount = min(
                    retainedChunk.count,
                    limit - storage.count
                )
                storage.append(
                    contentsOf:
                        retainedChunk.prefix(appendedCount)
                )
                retainedByteCount += appendedCount
                retainedChunk =
                    retainedChunk.dropFirst(appendedCount)
                guard !retainedChunk.isEmpty else {
                    return
                }
            }

            let overflow = max(
                0,
                retainedByteCount + retainedChunk.count - limit
            )
            if overflow > 0 {
                startIndex = (startIndex + overflow) % limit
                retainedByteCount -= overflow
            }

            let writeIndex =
                (startIndex + retainedByteCount) % limit
            let firstCount = min(
                retainedChunk.count,
                limit - writeIndex
            )
            storage.replaceSubrange(
                writeIndex..<(writeIndex + firstCount),
                with: retainedChunk.prefix(firstCount)
            )
            let remainingCount =
                retainedChunk.count - firstCount
            if remainingCount > 0 {
                storage.replaceSubrange(
                    0..<remainingCount,
                    with: retainedChunk.dropFirst(firstCount)
                )
            }
            retainedByteCount += retainedChunk.count
        }

        func rendered() -> (text: String, truncated: Bool) {
            let truncated = totalBytes > limit
            let firstCount = min(
                retainedByteCount,
                limit - startIndex
            )
            var bytes = Data()
            bytes.reserveCapacity(retainedByteCount)
            bytes.append(
                contentsOf:
                    storage[startIndex..<(startIndex + firstCount)]
            )
            if retainedByteCount > firstCount {
                bytes.append(
                    contentsOf:
                        storage[0..<(retainedByteCount - firstCount)]
                )
            }
            var text = String(decoding: bytes, as: UTF8.self)
            if truncated {
                text = "[\(totalBytes - limit) earlier bytes omitted]\n\(text)"
            }
            return (text, truncated)
        }
    }

    public let maximumOutputBytesPerStream: Int
    public let descendantPipeGracePeriod: TimeInterval
    public let environmentOverrides: [String: String]
    public let executionTimeout: TimeInterval
    public let terminationGracePeriod: TimeInterval
    public let processGroupMode: ProcessGroupMode

    public init(
        maximumOutputBytesPerStream: Int = 64 * 1024,
        descendantPipeGracePeriod: TimeInterval = 0.5,
        environmentOverrides: [String: String] = [:],
        executionTimeout: TimeInterval = 30 * 60,
        terminationGracePeriod: TimeInterval = 2,
        processGroupMode: ProcessGroupMode = .isolated
    ) {
        self.maximumOutputBytesPerStream = max(
            1,
            maximumOutputBytesPerStream
        )
        self.descendantPipeGracePeriod = min(
            60,
            max(0, descendantPipeGracePeriod)
        )
        self.environmentOverrides = environmentOverrides
        self.executionTimeout = min(24 * 60 * 60, max(0, executionTimeout))
        self.terminationGracePeriod = min(60, max(0, terminationGracePeriod))
        self.processGroupMode = processGroupMode
    }

    public func run(
        _ command: RenewalCommand,
        onOutput: ProcessOutputHandler? = nil
    ) throws -> ProcessResult {
        let process = try spawn(command)
        var openDescriptors: [Int32: ProcessOutputStream] = [
            process.standardOutputDescriptor: .standardOutput,
            process.standardErrorDescriptor: .standardError,
        ]
        var processWasReaped = false
        defer {
            for descriptor in openDescriptors.keys {
                Darwin.close(descriptor)
            }
            if !processWasReaped {
                _ = terminateAndReap(process.processID)
            }
            if processGroupMode == .isolated {
                terminateRemainingProcessGroup(process.processID)
            }
        }

        try setNonBlocking(process.standardOutputDescriptor)
        try setNonBlocking(process.standardErrorDescriptor)

        var output = TailBuffer(limit: maximumOutputBytesPerStream)
        var error = TailBuffer(limit: maximumOutputBytesPerStream)
        var standardOutputDecoder = ProcessOutputUTF8Decoder()
        var standardErrorDecoder = ProcessOutputUTF8Decoder()
        let startedAt = DispatchTime.now().uptimeNanoseconds
        let executionDeadline = startedAt + nanoseconds(executionTimeout)
        var processExitObservedAt: UInt64?
        var exitCode: Int32?
        var timedOut = false

        while exitCode == nil || !openDescriptors.isEmpty {
            let now = DispatchTime.now().uptimeNanoseconds
            if exitCode == nil {
                var waitStatus: Int32 = 0
                let waitResult = Darwin.waitpid(
                    process.processID,
                    &waitStatus,
                    WNOHANG
                )
                if waitResult == process.processID {
                    processWasReaped = true
                    exitCode = decodeExitCode(from: waitStatus)
                    processExitObservedAt = now
                } else if waitResult < 0, errno != EINTR {
                    throw POSIXError(
                        POSIXErrorCode(rawValue: errno) ?? .ECHILD
                    )
                } else if waitResult == 0, now >= executionDeadline {
                    timedOut = true
                    _ = terminateAndReap(process.processID)
                    processWasReaped = true
                    exitCode = 124
                    processExitObservedAt = now
                }
            }

            if let processExitObservedAt,
               now - processExitObservedAt
                   >= nanoseconds(descendantPipeGracePeriod)
            {
                break
            }

            var descriptors = openDescriptors.keys.map {
                pollfd(
                    fd: $0,
                    events: Int16(POLLIN | POLLHUP | POLLERR),
                    revents: 0
                )
            }
            let pollResult = descriptors.withUnsafeMutableBufferPointer {
                Darwin.poll($0.baseAddress, nfds_t($0.count), 100)
            }
            if pollResult < 0 {
                if errno == EINTR {
                    continue
                }
                throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
            }

            for descriptor in descriptors where descriptor.revents != 0 {
                let readResult = try readAvailable(descriptor.fd)
                switch readResult {
                case .data(let chunk):
                    let stream = openDescriptors[descriptor.fd]
                    switch stream {
                    case .standardOutput:
                        output.append(chunk)
                    case .standardError:
                        error.append(chunk)
                    case nil:
                        break
                    }
                    if let stream {
                        let decodedText: String
                        switch stream {
                        case .standardOutput:
                            decodedText =
                                standardOutputDecoder.append(chunk)
                        case .standardError:
                            decodedText =
                                standardErrorDecoder.append(chunk)
                        }
                        if !decodedText.isEmpty {
                            onOutput?(
                                ProcessOutputChunk(
                                    stream: stream,
                                    text: decodedText
                                )
                            )
                        }
                    }
                case .endOfFile:
                    let stream = openDescriptors.removeValue(
                        forKey: descriptor.fd
                    )
                    Darwin.close(descriptor.fd)
                    if let stream {
                        let finalText: String
                        switch stream {
                        case .standardOutput:
                            finalText = standardOutputDecoder.finish()
                        case .standardError:
                            finalText = standardErrorDecoder.finish()
                        }
                        if !finalText.isEmpty {
                            onOutput?(
                                ProcessOutputChunk(
                                    stream: stream,
                                    text: finalText
                                )
                            )
                        }
                    }
                case .nothingAvailable:
                    break
                }
            }
        }

        let remainingOutput = standardOutputDecoder.finish()
        if !remainingOutput.isEmpty {
            onOutput?(
                ProcessOutputChunk(
                    stream: .standardOutput,
                    text: remainingOutput
                )
            )
        }
        let remainingError = standardErrorDecoder.finish()
        if !remainingError.isEmpty {
            onOutput?(
                ProcessOutputChunk(
                    stream: .standardError,
                    text: remainingError
                )
            )
        }

        let renderedOutput = output.rendered()
        let renderedError = error.rendered()
        return ProcessResult(
            exitCode: exitCode ?? 1,
            standardOutput: renderedOutput.text,
            standardError: renderedError.text,
            standardOutputWasTruncated: renderedOutput.truncated,
            standardErrorWasTruncated: renderedError.truncated,
            timedOut: timedOut
        )
    }

    private enum ReadResult {
        case data(Data)
        case endOfFile
        case nothingAvailable
    }

    private func spawn(_ command: RenewalCommand) throws -> SpawnedProcess {
        var outputPipe = try makePipe()
        var errorPipe: FilePipe
        do {
            errorPipe = try makePipe()
        } catch {
            closeIfOpen(&outputPipe.readDescriptor)
            closeIfOpen(&outputPipe.writeDescriptor)
            throw error
        }
        var fileActions: posix_spawn_file_actions_t?
        var attributes: posix_spawnattr_t?
        var fileActionsWereInitialized = false
        var attributesWereInitialized = false
        defer {
            if fileActionsWereInitialized {
                posix_spawn_file_actions_destroy(&fileActions)
            }
            if attributesWereInitialized {
                posix_spawnattr_destroy(&attributes)
            }
            closeIfOpen(&outputPipe.readDescriptor)
            closeIfOpen(&outputPipe.writeDescriptor)
            closeIfOpen(&errorPipe.readDescriptor)
            closeIfOpen(&errorPipe.writeDescriptor)
        }

        try checkSpawnResult(posix_spawn_file_actions_init(&fileActions))
        fileActionsWereInitialized = true
        try checkSpawnResult(posix_spawnattr_init(&attributes))
        attributesWereInitialized = true
        try checkSpawnResult(
            posix_spawn_file_actions_adddup2(
                &fileActions,
                outputPipe.writeDescriptor,
                STDOUT_FILENO
            )
        )
        try checkSpawnResult(
            posix_spawn_file_actions_adddup2(
                &fileActions,
                errorPipe.writeDescriptor,
                STDERR_FILENO
            )
        )
        for descriptor in [
            outputPipe.readDescriptor,
            outputPipe.writeDescriptor,
            errorPipe.readDescriptor,
            errorPipe.writeDescriptor,
        ] {
            try checkSpawnResult(
                posix_spawn_file_actions_addclose(&fileActions, descriptor)
            )
        }
        var spawnFlags = Int16(POSIX_SPAWN_CLOEXEC_DEFAULT)
        if processGroupMode == .isolated {
            spawnFlags |= Int16(POSIX_SPAWN_SETPGROUP)
        }
        try checkSpawnResult(
            posix_spawnattr_setflags(&attributes, spawnFlags)
        )
        if processGroupMode == .isolated {
            try checkSpawnResult(posix_spawnattr_setpgroup(&attributes, 0))
        }

        let argumentStrings = [command.executable] + command.arguments
        let allocatedArguments = argumentStrings.map { strdup($0) }
        var environment = ProcessInfo.processInfo.environment
        environment.merge(environmentOverrides) { _, override in override }
        if processGroupMode == .isolated {
            environment[Self.containmentEnvironmentKey] =
                Self.containmentEnvironmentValue
        }
        let environmentStrings = environment.map {
            "\($0.key)=\($0.value)"
        }
        let allocatedEnvironment = environmentStrings.map { strdup($0) }
        guard allocatedArguments.allSatisfy({ $0 != nil }),
              allocatedEnvironment.allSatisfy({ $0 != nil })
        else {
            allocatedArguments.forEach { free($0) }
            allocatedEnvironment.forEach { free($0) }
            throw POSIXError(.ENOMEM)
        }
        defer {
            allocatedArguments.forEach { free($0) }
            allocatedEnvironment.forEach { free($0) }
        }
        var argumentVector = allocatedArguments
        argumentVector.append(nil)
        var environmentVector = allocatedEnvironment
        environmentVector.append(nil)
        var processID: pid_t = 0
        let result = command.executable.withCString { executable in
            argumentVector.withUnsafeMutableBufferPointer { arguments in
                environmentVector.withUnsafeMutableBufferPointer { environment in
                    posix_spawn(
                        &processID,
                        executable,
                        &fileActions,
                        &attributes,
                        arguments.baseAddress,
                        environment.baseAddress
                    )
                }
            }
        }
        try checkSpawnResult(result)

        closeIfOpen(&outputPipe.writeDescriptor)
        closeIfOpen(&errorPipe.writeDescriptor)
        return SpawnedProcess(
            processID: processID,
            standardOutputDescriptor: takeDescriptor(
                &outputPipe.readDescriptor
            ),
            standardErrorDescriptor: takeDescriptor(
                &errorPipe.readDescriptor
            )
        )
    }

    private func makePipe() throws -> FilePipe {
        var descriptors = [Int32](repeating: -1, count: 2)
        guard Darwin.pipe(&descriptors) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        let readDescriptor: Int32
        do {
            readDescriptor = try normalizePipeDescriptor(&descriptors[0])
        } catch {
            descriptors.filter { $0 >= 0 }.forEach { Darwin.close($0) }
            throw error
        }
        do {
            let writeDescriptor = try normalizePipeDescriptor(&descriptors[1])
            return FilePipe(
                readDescriptor: readDescriptor,
                writeDescriptor: writeDescriptor
            )
        } catch {
            Darwin.close(readDescriptor)
            descriptors.filter { $0 >= 0 }.forEach { Darwin.close($0) }
            throw error
        }
    }

    private func normalizePipeDescriptor(_ descriptor: inout Int32) throws -> Int32 {
        let original = descriptor
        descriptor = -1

        if original > STDERR_FILENO {
            guard fcntl(original, F_SETFD, FD_CLOEXEC) == 0 else {
                let savedError = errno
                Darwin.close(original)
                throw POSIXError(
                    POSIXErrorCode(rawValue: savedError) ?? .EIO
                )
            }
            return original
        }

        let replacement = fcntl(original, F_DUPFD_CLOEXEC, 3)
        let savedError = errno
        Darwin.close(original)
        guard replacement >= 0 else {
            throw POSIXError(
                POSIXErrorCode(rawValue: savedError) ?? .EIO
            )
        }
        return replacement
    }

    private func checkSpawnResult(_ result: Int32) throws {
        guard result == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: result) ?? .EIO)
        }
    }

    private func closeIfOpen(_ descriptor: inout Int32) {
        guard descriptor >= 0 else {
            return
        }
        Darwin.close(descriptor)
        descriptor = -1
    }

    private func takeDescriptor(_ descriptor: inout Int32) -> Int32 {
        let value = descriptor
        descriptor = -1
        return value
    }

    private func setNonBlocking(_ descriptor: Int32) throws {
        let flags = fcntl(descriptor, F_GETFL)
        guard flags >= 0, fcntl(descriptor, F_SETFL, flags | O_NONBLOCK) >= 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
    }

    private func readAvailable(_ descriptor: Int32) throws -> ReadResult {
        var buffer = [UInt8](repeating: 0, count: 8192)
        let count = buffer.withUnsafeMutableBytes {
            Darwin.read(descriptor, $0.baseAddress, $0.count)
        }
        if count > 0 {
            return .data(Data(buffer.prefix(count)))
        }
        if count == 0 {
            return .endOfFile
        }
        if errno == EAGAIN || errno == EWOULDBLOCK {
            return .nothingAvailable
        }
        throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
    }

    private func terminateAndReap(_ processID: pid_t) -> Int32 {
        Darwin.kill(signalTarget(for: processID), SIGTERM)
        let deadline = DispatchTime.now().uptimeNanoseconds
            + nanoseconds(terminationGracePeriod)
        var waitStatus: Int32 = 0

        while DispatchTime.now().uptimeNanoseconds < deadline {
            let waitResult = Darwin.waitpid(processID, &waitStatus, WNOHANG)
            if waitResult == processID {
                return decodeExitCode(from: waitStatus)
            }
            if waitResult < 0, errno == ECHILD {
                return 1
            }
            usleep(20_000)
        }

        Darwin.kill(signalTarget(for: processID), SIGKILL)
        while Darwin.waitpid(processID, &waitStatus, 0) < 0 {
            if errno != EINTR {
                return 1
            }
        }
        return decodeExitCode(from: waitStatus)
    }

    private func terminateRemainingProcessGroup(_ processID: pid_t) {
        guard Darwin.kill(-processID, 0) == 0 else {
            return
        }
        Darwin.kill(-processID, SIGTERM)
        usleep(50_000)
        Darwin.kill(-processID, SIGKILL)
    }

    private func signalTarget(for processID: pid_t) -> pid_t {
        processGroupMode == .isolated ? -processID : processID
    }

    private func nanoseconds(_ interval: TimeInterval) -> UInt64 {
        UInt64(min(interval, TimeInterval(UInt64.max) / 1_000_000_000)
            * 1_000_000_000)
    }

    private func decodeExitCode(from waitStatus: Int32) -> Int32 {
        let exitedNormally = (waitStatus & 0x7F) == 0
        if exitedNormally {
            return (waitStatus >> 8) & 0xFF
        }
        let signal = waitStatus & 0x7F
        if signal != 0x7F {
            return 128 + signal
        }
        return 1
    }
}
