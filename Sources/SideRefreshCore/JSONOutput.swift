import Darwin
import Foundation

public enum SideRefreshJSONOutput {
    public static func write<T: Encodable>(
        _ value: T,
        to descriptor: Int32 = STDOUT_FILENO
    ) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        var data = try encoder.encode(value)
        data.append(0x0A)
        try write(data, to: descriptor)
    }

    public static func writeError(
        _ message: String,
        to descriptor: Int32 = STDERR_FILENO
    ) {
        try? write(Data(message.utf8), to: descriptor)
    }

    private static func write(_ data: Data, to descriptor: Int32) throws {
        guard fcntl(descriptor, F_SETNOSIGPIPE, 1) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        try data.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else {
                return
            }
            var offset = 0
            while offset < bytes.count {
                let count = Darwin.write(
                    descriptor,
                    baseAddress.advanced(by: offset),
                    bytes.count - offset
                )
                if count < 0, errno == EINTR {
                    continue
                }
                guard count > 0 else {
                    throw POSIXError(
                        POSIXErrorCode(rawValue: errno) ?? .EIO
                    )
                }
                offset += count
            }
        }
    }
}
