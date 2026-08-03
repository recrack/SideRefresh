import Foundation

public enum DeviceProvisioningProfileReaderError:
    LocalizedError,
    Equatable
{
    case toolUnavailable(String)
    case commandFailed(Int32, String)
    case tooManyProfiles

    public var errorDescription: String? {
        switch self {
        case .toolUnavailable(let path):
            return "실제 iPhone 프로파일 조회 도구를 찾을 수 없습니다: \(path)"
        case .commandFailed(let exitCode, let message):
            let detail = message.isEmpty
                ? "종료 코드 \(exitCode)"
                : message
            return "iPhone의 개발자 프로파일을 읽지 못했습니다: \(detail)"
        case .tooManyProfiles:
            return "iPhone의 개발자 프로파일 수가 안전 한도를 넘었습니다."
        }
    }
}

public struct DeviceProvisioningProfileReader: Sendable {
    public static let maximumProfileCount = 200

    private let runner: BoundedProcessRunner
    private let profileReader: ProvisioningProfileReader

    public init(
        runner: BoundedProcessRunner = BoundedProcessRunner(
            maximumOutputBytesPerStream: 256 * 1024,
            executionTimeout: 45
        ),
        profileReader: ProvisioningProfileReader =
            ProvisioningProfileReader()
    ) {
        self.runner = runner
        self.profileReader = profileReader
    }

    public func read(
        deviceIdentifier: String,
        ideviceprovisionURL: URL,
        usesNetwork: Bool
    ) throws -> [ProvisioningProfileMetadata] {
        guard FileManager.default.isExecutableFile(
            atPath: ideviceprovisionURL.path
        ) else {
            throw DeviceProvisioningProfileReaderError.toolUnavailable(
                ideviceprovisionURL.path
            )
        }
        let outputDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "SideRefresh-DeviceProfiles-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700]
        )
        defer {
            try? FileManager.default.removeItem(at: outputDirectory)
        }
        var arguments = [
            "--udid",
            deviceIdentifier,
        ]
        if usesNetwork {
            arguments.append("--network")
        }
        arguments.append(contentsOf: [
            "copy",
            outputDirectory.path,
        ])
        let result = try runner.run(
            RenewalCommand(
                executableURL: ideviceprovisionURL,
                arguments: arguments
            )
        )
        guard result.exitCode == 0 else {
            throw DeviceProvisioningProfileReaderError.commandFailed(
                result.exitCode,
                result.standardError.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            )
        }
        let profileURLs = try FileManager.default.contentsOfDirectory(
            at: outputDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ).filter {
            $0.pathExtension == "mobileprovision"
        }
        guard profileURLs.count <= Self.maximumProfileCount else {
            throw DeviceProvisioningProfileReaderError.tooManyProfiles
        }
        return profileURLs.compactMap {
            try? profileReader.read(profileURL: $0)
        }
    }

    public func readWithUSBThenNetwork(
        deviceIdentifier: String,
        ideviceprovisionURL: URL
    ) throws -> [ProvisioningProfileMetadata] {
        do {
            return try read(
                deviceIdentifier: deviceIdentifier,
                ideviceprovisionURL: ideviceprovisionURL,
                usesNetwork: false
            )
        } catch let error as DeviceProvisioningProfileReaderError {
            guard case .commandFailed = error else {
                throw error
            }
            return try read(
                deviceIdentifier: deviceIdentifier,
                ideviceprovisionURL: ideviceprovisionURL,
                usesNetwork: true
            )
        }
    }

    public static func profiles(
        matching bundleIdentifier: String,
        in profiles: [ProvisioningProfileMetadata]
    ) -> [ProvisioningProfileMetadata] {
        profiles.filter { profile in
            guard let identifier = profile.applicationIdentifier else {
                return false
            }
            return identifier == bundleIdentifier
                || identifier.hasSuffix(".\(bundleIdentifier)")
        }
    }
}
