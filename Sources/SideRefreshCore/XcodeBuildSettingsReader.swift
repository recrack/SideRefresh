import Foundation

public enum XcodeBuildSettingsDestination: Sendable {
    case genericIOS
    case selectedDevice
}

public enum XcodeBuildSettingsReaderError:
    LocalizedError,
    Equatable
{
    case commandFailed(Int32, String)
    case invalidAppBundlePath(
        targetBuildDirectory: String,
        fullProductName: String
    )
    case invalidOutput
    case targetNotFound(String)
    case invalidVersion(
        marketingVersion: String,
        buildVersion: String
    )

    public var errorDescription: String? {
        switch self {
        case let .commandFailed(exitCode, message):
            let detail = message.isEmpty
                ? "종료 코드 \(exitCode)"
                : message
            return "Xcode 빌드 설정을 확인하지 못했습니다: \(detail)"
        case let .invalidAppBundlePath(
            targetBuildDirectory,
            fullProductName
        ):
            return "Xcode 빌드 결과 앱 경로를 확인하지 못했습니다: \(targetBuildDirectory)/\(fullProductName)"
        case .invalidOutput:
            return "Xcode 앱 버전 정보를 해석하지 못했습니다."
        case let .targetNotFound(bundleIdentifier):
            return "Xcode 설정에서 \(bundleIdentifier) 앱을 찾지 못했습니다."
        case let .invalidVersion(marketingVersion, buildVersion):
            return "Xcode 앱 버전 \(marketingVersion) (\(buildVersion))을 안전하게 올릴 수 없습니다."
        }
    }
}

public struct XcodeBuildSettingsReader: Sendable {
    private struct Entry: Decodable {
        let buildSettings: [String: String]
    }

    private let runner: BoundedProcessRunner

    public init(
        runner: BoundedProcessRunner = BoundedProcessRunner(
            maximumOutputBytesPerStream: 4 * 1024 * 1024,
            executionTimeout: 120
        )
    ) {
        self.runner = runner
    }

    public func read(
        plan: IOSAppRenewalPlan,
        destination: XcodeBuildSettingsDestination = .selectedDevice,
        xcrunURL: URL = URL(fileURLWithPath: "/usr/bin/xcrun")
    ) throws -> IOSAppVersion {
        let data = try readData(
            plan: plan,
            destination: destination,
            xcrunURL: xcrunURL
        )
        return try Self.parse(
            data,
            bundleIdentifier: plan.bundleIdentifier
        )
    }

    public func read(
        query: XcodeBuildSettingsQuery,
        buildSettingOverrides: [String] = [],
        xcrunURL: URL = URL(fileURLWithPath: "/usr/bin/xcrun")
    ) throws -> IOSAppVersion {
        let data = try readData(
            query: query,
            destination: .genericIOS,
            selectedDeviceIdentifier: nil,
            buildSettingOverrides: buildSettingOverrides,
            xcrunURL: xcrunURL
        )
        return try Self.parse(
            data,
            bundleIdentifier: query.bundleIdentifier
        )
    }

    public func readAppBundleURL(
        plan: IOSAppRenewalPlan,
        destination: XcodeBuildSettingsDestination = .selectedDevice,
        buildSettingOverrides: [String]? = nil,
        xcrunURL: URL = URL(fileURLWithPath: "/usr/bin/xcrun")
    ) throws -> URL {
        let data = try readData(
            plan: plan,
            destination: destination,
            buildSettingOverrides: buildSettingOverrides,
            xcrunURL: xcrunURL
        )
        return try Self.parseAppBundleURL(
            data,
            bundleIdentifier: plan.bundleIdentifier
        )
    }

    private func readData(
        plan: IOSAppRenewalPlan,
        destination: XcodeBuildSettingsDestination,
        buildSettingOverrides: [String]? = nil,
        xcrunURL: URL
    ) throws -> Data {
        try readData(
            query: XcodeBuildSettingsQuery(
                containerURL: plan.containerURL,
                scheme: plan.scheme,
                configuration: plan.configuration,
                bundleIdentifier: plan.bundleIdentifier,
                derivedDataURL: plan.derivedDataURL
            ),
            destination: destination,
            selectedDeviceIdentifier: plan.deviceIdentifier,
            buildSettingOverrides:
                buildSettingOverrides
                    ?? plan.buildSettingOverrides(),
            xcrunURL: xcrunURL
        )
    }

    private func readData(
        query: XcodeBuildSettingsQuery,
        destination: XcodeBuildSettingsDestination,
        selectedDeviceIdentifier: String?,
        buildSettingOverrides: [String],
        xcrunURL: URL
    ) throws -> Data {
        let containerOption =
            query.containerURL.pathExtension.lowercased() == "xcodeproj"
            ? "-project"
            : "-workspace"
        let destinationValue = switch destination {
        case .genericIOS:
            "generic/platform=iOS"
        case .selectedDevice:
            "platform=iOS,id=\(selectedDeviceIdentifier ?? "")"
        }
        let result = try runner.run(
            RenewalCommand(
                executableURL: xcrunURL,
                arguments: [
                    "xcodebuild",
                    containerOption,
                    query.containerURL.path,
                    "-scheme",
                    query.scheme,
                    "-configuration",
                    query.configuration,
                    "-sdk",
                    "iphoneos",
                    "-destination",
                    destinationValue,
                    "-destination-timeout",
                    "120",
                    "-derivedDataPath",
                    query.derivedDataURL.path,
                ] + buildSettingOverrides + [
                    "-showBuildSettings",
                    "-json",
                ]
            )
        )
        guard result.exitCode == 0 else {
            throw XcodeBuildSettingsReaderError.commandFailed(
                result.exitCode,
                result.standardError.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            )
        }
        guard !result.standardOutputWasTruncated else {
            throw XcodeBuildSettingsReaderError.invalidOutput
        }
        return Data(result.standardOutput.utf8)
    }

    public static func parse(
        _ data: Data,
        bundleIdentifier: String
    ) throws -> IOSAppVersion {
        let settings = try selectedBuildSettings(
            in: data,
            bundleIdentifier: bundleIdentifier
        )
        let marketingVersion = settings["MARKETING_VERSION"] ?? ""
        let buildVersion = settings["CURRENT_PROJECT_VERSION"] ?? ""
        guard let version = IOSAppVersion(
            marketingVersion: marketingVersion,
            buildVersion: buildVersion
        ) else {
            throw XcodeBuildSettingsReaderError.invalidVersion(
                marketingVersion: marketingVersion,
                buildVersion: buildVersion
            )
        }
        return version
    }

    public static func parseAppBundleURL(
        _ data: Data,
        bundleIdentifier: String
    ) throws -> URL {
        let settings = try selectedBuildSettings(
            in: data,
            bundleIdentifier: bundleIdentifier
        )
        let targetBuildDirectory =
            settings["TARGET_BUILD_DIR"] ?? ""
        let fullProductName = settings["FULL_PRODUCT_NAME"] ?? ""
        guard targetBuildDirectory.hasPrefix("/"),
              !targetBuildDirectory.contains("$("),
              (fullProductName as NSString)
                  .pathExtension.lowercased() == "app",
              fullProductName != ".",
              fullProductName != "..",
              !fullProductName.contains("/")
        else {
            throw XcodeBuildSettingsReaderError.invalidAppBundlePath(
                targetBuildDirectory: targetBuildDirectory,
                fullProductName: fullProductName
            )
        }
        return URL(
            fileURLWithPath: targetBuildDirectory,
            isDirectory: true
        ).appendingPathComponent(
            fullProductName,
            isDirectory: true
        )
    }

    private static func selectedBuildSettings(
        in data: Data,
        bundleIdentifier: String
    ) throws -> [String: String] {
        let entries: [Entry]
        do {
            entries = try JSONDecoder().decode([Entry].self, from: data)
        } catch {
            throw XcodeBuildSettingsReaderError.invalidOutput
        }
        guard let settings = entries.lazy.map(\.buildSettings).first(
            where: {
                $0["PRODUCT_BUNDLE_IDENTIFIER"] == bundleIdentifier
            }
        ) else {
            throw XcodeBuildSettingsReaderError.targetNotFound(
                bundleIdentifier
            )
        }
        return settings
    }
}
