import Foundation

public struct InstalledDeviceApp: Codable, Equatable, Sendable {
    public let name: String
    public let bundleIdentifier: String
    public let version: String
    public let bundleVersion: String
    public let builtByDeveloper: Bool
    public let appClip: Bool?
    public let defaultApp: Bool?
    public let hidden: Bool?
    public let internalApp: Bool?
    public let removable: Bool?
    public let url: String?

    public init(
        name: String,
        bundleIdentifier: String,
        version: String,
        bundleVersion: String,
        builtByDeveloper: Bool,
        appClip: Bool? = nil,
        defaultApp: Bool? = nil,
        hidden: Bool? = nil,
        internalApp: Bool? = nil,
        removable: Bool? = nil,
        url: String? = nil
    ) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.bundleVersion = bundleVersion
        self.builtByDeveloper = builtByDeveloper
        self.appClip = appClip
        self.defaultApp = defaultApp
        self.hidden = hidden
        self.internalApp = internalApp
        self.removable = removable
        self.url = url
    }
}

public enum InstalledAppReaderError: LocalizedError, Equatable {
    case xcodeToolsUnavailable(String)
    case commandFailed(Int32, String)
    case outputMissing
    case outputTooLarge
    case invalidOutput

    public var errorDescription: String? {
        switch self {
        case .xcodeToolsUnavailable(let path):
            return "Xcode 기기 도구를 찾을 수 없습니다: \(path)"
        case .commandFailed(let exitCode, let message):
            let detail = message.isEmpty
                ? "종료 코드 \(exitCode)"
                : message
            return "iPhone의 설치 앱을 확인하지 못했습니다: \(detail)"
        case .outputMissing:
            return "Xcode 기기 도구가 설치 앱 정보를 만들지 못했습니다."
        case .outputTooLarge:
            return "Xcode 기기 도구의 설치 앱 정보가 너무 큽니다."
        case .invalidOutput:
            return "Xcode 기기 도구의 설치 앱 정보를 해석하지 못했습니다."
        }
    }
}

public struct InstalledAppReader: Sendable {
    private struct Output: Decodable {
        struct Result: Decodable {
            let apps: [InstalledDeviceApp]
        }

        let result: Result
    }

    public static let maximumOutputBytes = 2 * 1024 * 1024

    private let runner: BoundedProcessRunner

    public init(
        runner: BoundedProcessRunner = BoundedProcessRunner(
            maximumOutputBytesPerStream: 128 * 1024,
            executionTimeout: 45
        )
    ) {
        self.runner = runner
    }

    public func read(
        deviceIdentifier: String,
        bundleIdentifier: String,
        xcrunURL: URL = URL(fileURLWithPath: "/usr/bin/xcrun")
    ) throws -> InstalledDeviceApp? {
        try readApps(
            deviceIdentifier: deviceIdentifier,
            arguments: [
                "--bundle-id",
                bundleIdentifier,
            ],
            xcrunURL: xcrunURL
        ).first
    }

    public func readDeveloperApps(
        deviceIdentifier: String,
        xcrunURL: URL = URL(fileURLWithPath: "/usr/bin/xcrun")
    ) throws -> [InstalledDeviceApp] {
        try readApps(
            deviceIdentifier: deviceIdentifier,
            arguments: [
                "--filter",
                "builtByDeveloper == true",
            ],
            xcrunURL: xcrunURL
        ).sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name)
                == .orderedAscending
        }
    }

    private func readApps(
        deviceIdentifier: String,
        arguments additionalArguments: [String],
        xcrunURL: URL
    ) throws -> [InstalledDeviceApp] {
        guard FileManager.default.isExecutableFile(
            atPath: xcrunURL.path
        ) else {
            throw InstalledAppReaderError.xcodeToolsUnavailable(
                xcrunURL.path
            )
        }
        let outputDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "SideRefresh-InstalledApp-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: false
        )
        defer {
            try? FileManager.default.removeItem(at: outputDirectory)
        }
        let outputURL = outputDirectory.appendingPathComponent("apps.json")
        var arguments = [
            "devicectl",
            "device",
            "info",
            "apps",
            "--device",
            deviceIdentifier,
        ]
        arguments.append(contentsOf: additionalArguments)
        arguments.append(contentsOf: [
            "--timeout",
            "30",
            "--json-output",
            outputURL.path,
            "--quiet",
        ])
        let result = try runner.run(
            RenewalCommand(
                executableURL: xcrunURL,
                arguments: arguments
            )
        )
        guard result.exitCode == 0 else {
            throw InstalledAppReaderError.commandFailed(
                result.exitCode,
                result.standardError.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            )
        }
        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw InstalledAppReaderError.outputMissing
        }
        let attributes = try FileManager.default.attributesOfItem(
            atPath: outputURL.path
        )
        if let size = attributes[.size] as? NSNumber,
           size.intValue > Self.maximumOutputBytes
        {
            throw InstalledAppReaderError.outputTooLarge
        }
        let data = try Data(
            contentsOf: outputURL,
            options: [.mappedIfSafe]
        )
        return try Self.parse(data)
    }

    public static func parse(
        _ data: Data
    ) throws -> [InstalledDeviceApp] {
        do {
            return try JSONDecoder().decode(Output.self, from: data)
                .result.apps
        } catch {
            throw InstalledAppReaderError.invalidOutput
        }
    }
}
