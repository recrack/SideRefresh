import Foundation

public struct CoreDevice: Equatable, Identifiable, Sendable {
    public let udid: String
    public let name: String
    public let marketingName: String?
    public let operatingSystemVersion: String?
    public let pairingState: String?

    public var id: String {
        udid
    }

    public var isPaired: Bool {
        pairingState?.caseInsensitiveCompare("paired") == .orderedSame
    }

    public init(
        udid: String,
        name: String,
        marketingName: String?,
        operatingSystemVersion: String?,
        pairingState: String?
    ) {
        self.udid = udid
        self.name = name
        self.marketingName = marketingName
        self.operatingSystemVersion = operatingSystemVersion
        self.pairingState = pairingState
    }
}

public struct CoreDeviceSnapshot: Equatable, Sendable {
    public let iPhones: [CoreDevice]

    public var pairedIPhones: [CoreDevice] {
        iPhones.filter(\.isPaired)
    }

    public init(iPhones: [CoreDevice]) {
        self.iPhones = iPhones
    }

    public static func parse(_ data: Data) throws -> CoreDeviceSnapshot {
        let document: DeviceListDocument
        do {
            document = try JSONDecoder().decode(
                DeviceListDocument.self,
                from: data
            )
        } catch {
            throw CoreDeviceReaderError.invalidOutput
        }

        let iPhones = document.result.devices.compactMap {
            device -> CoreDevice? in
            let hardware = device.hardwareProperties
            let reality = hardware.reality?.lowercased()
            guard hardware.platform.caseInsensitiveCompare("iOS")
                    == .orderedSame,
                  hardware.deviceType.caseInsensitiveCompare("iPhone")
                    == .orderedSame,
                  reality == nil || reality == "physical"
            else {
                return nil
            }

            let udid = hardware.udid.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            guard !udid.isEmpty else {
                return nil
            }

            let name = device.deviceProperties.name.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            return CoreDevice(
                udid: udid,
                name: name.isEmpty ? "이름 없는 iPhone" : name,
                marketingName: hardware.marketingName,
                operatingSystemVersion:
                    device.deviceProperties.osVersionNumber,
                pairingState:
                    device.connectionProperties?.pairingState
            )
        }
        .sorted {
            let comparison = $0.name.localizedCaseInsensitiveCompare(
                $1.name
            )
            if comparison == .orderedSame {
                return $0.udid < $1.udid
            }
            return comparison == .orderedAscending
        }

        return CoreDeviceSnapshot(iPhones: iPhones)
    }

    private struct DeviceListDocument: Decodable {
        let result: Result

        struct Result: Decodable {
            let devices: [Device]
        }

        struct Device: Decodable {
            let connectionProperties: ConnectionProperties?
            let deviceProperties: DeviceProperties
            let hardwareProperties: HardwareProperties
        }

        struct ConnectionProperties: Decodable {
            let pairingState: String?
        }

        struct DeviceProperties: Decodable {
            let name: String
            let osVersionNumber: String?
        }

        struct HardwareProperties: Decodable {
            let deviceType: String
            let marketingName: String?
            let platform: String
            let reality: String?
            let udid: String
        }
    }
}

public enum CoreDeviceReaderError: LocalizedError, Equatable {
    case commandFailed(exitCode: Int32, message: String)
    case invalidOutput
    case outputMissing
    case outputTooLarge
    case xcodeToolsUnavailable(String)

    public var errorDescription: String? {
        switch self {
        case let .commandFailed(exitCode, message):
            if message.isEmpty {
                return "Xcode의 iPhone 목록을 읽지 못했습니다(종료 코드 \(exitCode))."
            }
            return "Xcode의 iPhone 목록을 읽지 못했습니다: \(message)"
        case .invalidOutput:
            return "Xcode가 반환한 iPhone 목록 형식을 이해하지 못했습니다."
        case .outputMissing:
            return "Xcode가 iPhone 목록 파일을 만들지 않았습니다."
        case .outputTooLarge:
            return "Xcode의 iPhone 목록이 4 MiB 안전 한도를 넘었습니다."
        case .xcodeToolsUnavailable:
            return "Xcode 명령줄 도구를 찾을 수 없습니다."
        }
    }
}

public struct CoreDeviceReader: Sendable {
    private static let maximumOutputBytes = 4 * 1_024 * 1_024

    private let runner: BoundedProcessRunner

    public init(
        runner: BoundedProcessRunner = BoundedProcessRunner(
            maximumOutputBytesPerStream: 256 * 1_024,
            executionTimeout: 15
        )
    ) {
        self.runner = runner
    }

    public func read(
        xcrunURL: URL = URL(fileURLWithPath: "/usr/bin/xcrun")
    ) throws -> CoreDeviceSnapshot {
        guard xcrunURL.isFileURL,
              xcrunURL.path.hasPrefix("/"),
              FileManager.default.isExecutableFile(atPath: xcrunURL.path)
        else {
            throw CoreDeviceReaderError.xcodeToolsUnavailable(
                xcrunURL.path
            )
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "SideRefresh-CoreDevice-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700]
        )
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let outputURL = directory.appendingPathComponent("devices.json")
        let result = try runner.run(
            RenewalCommand(
                executableURL: xcrunURL,
                arguments: [
                    "devicectl",
                    "list",
                    "devices",
                    "--filter",
                    "hardwareProperties.platform == 'iOS' AND hardwareProperties.deviceType == 'iPhone'",
                    "--timeout",
                    "10",
                    "--json-output",
                    outputURL.path,
                    "--quiet",
                ]
            )
        )
        guard result.exitCode == 0 else {
            throw CoreDeviceReaderError.commandFailed(
                exitCode: result.exitCode,
                message: result.standardError.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            )
        }
        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw CoreDeviceReaderError.outputMissing
        }

        let attributes = try FileManager.default.attributesOfItem(
            atPath: outputURL.path
        )
        if let size = attributes[.size] as? NSNumber,
           size.intValue > Self.maximumOutputBytes
        {
            throw CoreDeviceReaderError.outputTooLarge
        }
        let data = try Data(
            contentsOf: outputURL,
            options: [.mappedIfSafe]
        )
        guard data.count <= Self.maximumOutputBytes else {
            throw CoreDeviceReaderError.outputTooLarge
        }
        return try CoreDeviceSnapshot.parse(data)
    }
}
