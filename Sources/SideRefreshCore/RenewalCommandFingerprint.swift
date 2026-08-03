import CryptoKit
import Foundation

extension RenewalCommand {
    var fingerprint: String {
        var data = Data()
        append(executable, to: &data)
        for argument in arguments {
            append(argument, to: &data)
        }
        return SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private func append(_ value: String, to data: inout Data) {
        let bytes = Data(value.utf8)
        var length = UInt64(bytes.count).bigEndian
        withUnsafeBytes(of: &length) {
            data.append(contentsOf: $0)
        }
        data.append(bytes)
    }
}
