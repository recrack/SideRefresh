import Foundation

public enum IOSAppRenewalPlanError: LocalizedError, Equatable {
    case appBundleNotFound(String)
    case emptyValue(String)
    case fileURLRequired(String)
    case invalidAppBundle(String)
    case invalidPathComponent(field: String, value: String)
    case placeholderValue(String)
    case unsupportedContainerExtension(String)
    case unexpectedBundleIdentifier(expected: String, actual: String)
    case unsafeDerivedDataPath(String)

    public var errorDescription: String? {
        switch self {
        case .appBundleNotFound(let path):
            return "The built app bundle was not found at \(path)."
        case .emptyValue(let field):
            return Self.emptyValueDescription(for: field)
        case .fileURLRequired(let field):
            return "\(field) must be an absolute local file URL."
        case .invalidAppBundle(let path):
            return "The app bundle at \(path) has no valid Info.plist."
        case .invalidPathComponent(let field, let value):
            return "\(field) must be one path component, got \(value)."
        case .placeholderValue(let field):
            return "\(field)에 예제 자리표시자가 남아 있습니다. 실제 값을 입력해 주세요."
        case .unsupportedContainerExtension(let pathExtension):
            return "Expected an .xcodeproj or .xcworkspace, got .\(pathExtension)."
        case .unexpectedBundleIdentifier(let expected, let actual):
            return "Expected bundle identifier \(expected), got \(actual)."
        case .unsafeDerivedDataPath(let path):
            return "Refusing unsafe Derived Data path \(path)."
        }
    }

    private static func emptyValueDescription(
        for field: String
    ) -> String {
        switch field {
        case "scheme":
            return "앱 구성(Scheme)이 비어 있습니다."
        case "configuration":
            return "Xcode 빌드 구성이 비어 있습니다."
        case "development team":
            return "Apple 개발 팀 ID가 비어 있습니다."
        case "bundle identifier":
            return "앱 식별자(Bundle ID)가 비어 있습니다."
        case "product name":
            return "빌드 결과 앱 이름이 비어 있습니다."
        case "device identifier":
            return "설치할 iPhone의 기기 식별자(UDID)가 비어 있습니다."
        default:
            return "필수 설정값(\(field))이 비어 있습니다."
        }
    }
}

public enum ExistingAppBundleCleanupResult:
    Equatable,
    Sendable
{
    case absent
    case removed
    case skippedOutsideDerivedData
}

public struct IOSAppRenewalPlan: Equatable, Sendable {
    public let containerURL: URL
    public let scheme: String
    public let configuration: String
    public let developmentTeam: String
    public let bundleIdentifier: String
    public let productName: String
    public let deviceIdentifier: String
    public let derivedDataURL: URL

    public init(
        containerURL: URL,
        scheme: String,
        configuration: String = "Release",
        developmentTeam: String,
        bundleIdentifier: String,
        productName: String,
        deviceIdentifier: String,
        derivedDataURL: URL
    ) throws {
        guard containerURL.isFileURL else {
            throw IOSAppRenewalPlanError.fileURLRequired("container")
        }
        guard derivedDataURL.isFileURL else {
            throw IOSAppRenewalPlanError.fileURLRequired("derived data")
        }
        guard derivedDataURL.standardizedFileURL.path != "/" else {
            throw IOSAppRenewalPlanError.unsafeDerivedDataPath("/")
        }
        let pathExtension = containerURL.pathExtension.lowercased()
        guard pathExtension == "xcodeproj"
                || pathExtension == "xcworkspace"
        else {
            throw IOSAppRenewalPlanError.unsupportedContainerExtension(
                pathExtension
            )
        }
        for (field, value) in [
            ("scheme", scheme),
            ("configuration", configuration),
            ("development team", developmentTeam),
            ("bundle identifier", bundleIdentifier),
            ("product name", productName),
            ("device identifier", deviceIdentifier),
        ] where value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw IOSAppRenewalPlanError.emptyValue(field)
        }
        for (field, value) in [
            ("development team", developmentTeam),
            ("bundle identifier", bundleIdentifier),
            ("device identifier", deviceIdentifier),
        ] where Self.isPlaceholder(value) {
            throw IOSAppRenewalPlanError.placeholderValue(field)
        }
        guard productName != ".",
              productName != "..",
              !productName.contains("/")
        else {
            throw IOSAppRenewalPlanError.invalidPathComponent(
                field: "product name",
                value: productName
            )
        }
        self.containerURL = containerURL.standardizedFileURL
        self.scheme = scheme
        self.configuration = configuration
        self.developmentTeam = developmentTeam
        self.bundleIdentifier = bundleIdentifier
        self.productName = productName
        self.deviceIdentifier = deviceIdentifier
        self.derivedDataURL = derivedDataURL.standardizedFileURL
    }

    private static func isPlaceholder(_ value: String) -> Bool {
        let normalized = value.uppercased()
        return normalized.contains("REPLACE_")
            || normalized.contains("REPLACE-ME")
            || normalized.hasPrefix("YOUR_")
    }

    public var appBundleURL: URL {
        buildProductsURL
            .appendingPathComponent(
                "\(productName).app",
                isDirectory: true
            )
    }

    public var buildProductsURL: URL {
        derivedDataURL
            .appendingPathComponent("Build", isDirectory: true)
            .appendingPathComponent("Products", isDirectory: true)
            .appendingPathComponent(
                "\(configuration)-iphoneos",
                isDirectory: true
            )
    }

    public var buildCommand: RenewalCommand {
        buildCommand(for: .incremental)
    }

    public func buildCommand(
        for strategy: IOSAppBuildStrategy,
        renewalEvidence: IOSAppRenewalEvidence? = nil,
        appVersionOverride: IOSAppVersion? = nil
    ) -> RenewalCommand {
        let containerOption = containerURL.pathExtension.lowercased()
            == "xcodeproj" ? "-project" : "-workspace"
        return RenewalCommand(
            executableURL: URL(fileURLWithPath: "/usr/bin/xcrun"),
            arguments: [
                "xcodebuild",
                containerOption,
                containerURL.path,
                "-scheme",
                scheme,
                "-configuration",
                configuration,
                "-sdk",
                "iphoneos",
                "-destination",
                "platform=iOS,id=\(deviceIdentifier)",
                "-destination-timeout",
                "120",
                "-derivedDataPath",
                derivedDataURL.path,
                "-allowProvisioningUpdates",
                "-allowProvisioningDeviceRegistration",
            ] + buildSettingOverrides(
                renewalEvidence: renewalEvidence,
                appVersionOverride: appVersionOverride
            )
                + strategy.xcodebuildActions
        )
    }

    public func buildSettingOverrides(
        renewalEvidence: IOSAppRenewalEvidence? = nil,
        appVersionOverride: IOSAppVersion? = nil
    ) -> [String] {
        let renewalBuildSettings = renewalEvidence.map {
            [
                "SIDEREFRESH_INSTALL_IDENTIFIER=\($0.identifier)",
                "SIDEREFRESH_RENEWED_AT=\($0.renewedAtBuildSetting)",
            ]
        } ?? []
        let versionBuildSettings = appVersionOverride.map {
            [
                "MARKETING_VERSION=\($0.marketingVersion)",
                "CURRENT_PROJECT_VERSION=\($0.buildVersion)",
            ]
        } ?? []
        return ["DEVELOPMENT_TEAM=\(developmentTeam)"]
            + renewalBuildSettings
            + versionBuildSettings
    }

    public var installCommand: RenewalCommand {
        installCommand(appBundleURL: appBundleURL)
    }

    public func installCommand(
        appBundleURL: URL
    ) -> RenewalCommand {
        RenewalCommand(
            executableURL: URL(fileURLWithPath: "/usr/bin/xcrun"),
            arguments: [
                "devicectl",
                "device",
                "install",
                "app",
                "--device",
                deviceIdentifier,
                appBundleURL.path,
                "--timeout",
                "120",
            ]
        )
    }

    @discardableResult
    public func removeExistingAppBundle()
        throws -> ExistingAppBundleCleanupResult
    {
        try removeExistingAppBundle(at: appBundleURL)
    }

    @discardableResult
    public func removeExistingAppBundle(
        at appBundleURL: URL
    ) throws -> ExistingAppBundleCleanupResult {
        guard FileManager.default.fileExists(
            atPath: appBundleURL.path
        ) else {
            return .absent
        }
        guard isSafeGeneratedAppBundleURL(appBundleURL) else {
            return .skippedOutsideDerivedData
        }
        try FileManager.default.removeItem(at: appBundleURL)
        return .removed
    }

    public func validateBuiltAppBundle() throws {
        try validateBuiltAppBundle(at: appBundleURL)
    }

    public func validateBuiltAppBundle(
        at appBundleURL: URL
    ) throws {
        let infoURL = appBundleURL.appendingPathComponent("Info.plist")
        guard FileManager.default.fileExists(atPath: appBundleURL.path) else {
            throw IOSAppRenewalPlanError.appBundleNotFound(
                appBundleURL.path
            )
        }
        guard let data = try? Data(contentsOf: infoURL),
              let info = try? PropertyListDecoder().decode(
                  AppBundleInfo.self,
                  from: data
              )
        else {
            throw IOSAppRenewalPlanError.invalidAppBundle(appBundleURL.path)
        }
        guard info.bundleIdentifier == bundleIdentifier else {
            throw IOSAppRenewalPlanError.unexpectedBundleIdentifier(
                expected: bundleIdentifier,
                actual: info.bundleIdentifier
            )
        }
    }

    private struct AppBundleInfo: Decodable {
        let bundleIdentifier: String

        enum CodingKeys: String, CodingKey {
            case bundleIdentifier = "CFBundleIdentifier"
        }
    }

    private func isSafeGeneratedAppBundleURL(
        _ appBundleURL: URL
    ) -> Bool {
        let derivedDataPath = derivedDataURL
            .resolvingSymlinksInPath()
            .standardizedFileURL.path
        let appBundlePath = appBundleURL
            .resolvingSymlinksInPath()
            .standardizedFileURL.path
        let derivedDataPrefix = derivedDataPath.hasSuffix("/")
            ? derivedDataPath
            : derivedDataPath + "/"
        return appBundleURL.pathExtension.lowercased() == "app"
            && appBundlePath.hasPrefix(derivedDataPrefix)
    }
}
