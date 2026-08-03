import Foundation

public enum IOSAppRenewalMode: String, Codable, Equatable, Sendable {
    case dryRun = "dry-run"
    case execute

    public var argument: String {
        "--\(rawValue)"
    }
}

public enum IOSAppRenewalProfileError: LocalizedError, Equatable {
    case conflictingModes
    case duplicateOption(String)
    case invalidValue(option: String, value: String)
    case missingRequiredOption(String)
    case missingValue(String)
    case relativePath(String)
    case unknownOption(String)

    public var errorDescription: String? {
        switch self {
        case .conflictingModes:
            return "Specify only one of --dry-run or --execute."
        case let .duplicateOption(option):
            return "\(option) may only be specified once."
        case let .invalidValue(option, value):
            return "Unsupported \(option) value: \(value)."
        case let .missingRequiredOption(option):
            return "Missing required \(option) value."
        case let .missingValue(option):
            return "Missing value for \(option)."
        case let .relativePath(option):
            return "\(option) must be an absolute path."
        case let .unknownOption(option):
            return "Unknown option: \(option)."
        }
    }
}

public struct IOSAppRenewalProfile: Equatable, Sendable {
    public let mode: IOSAppRenewalMode
    public let buildStrategy: IOSAppBuildStrategy
    public let versionPolicy: IOSAppVersionPolicy
    public let sourceAppVersion: IOSAppVersion?
    public let displayName: String?
    public let plan: IOSAppRenewalPlan

    public init(
        mode: IOSAppRenewalMode,
        buildStrategy: IOSAppBuildStrategy = .incremental,
        versionPolicy: IOSAppVersionPolicy = .keep,
        sourceAppVersion: IOSAppVersion? = nil,
        displayName: String? = nil,
        plan: IOSAppRenewalPlan
    ) {
        self.mode = mode
        self.buildStrategy = buildStrategy
        self.versionPolicy = versionPolicy
        self.sourceAppVersion = sourceAppVersion
        self.displayName = displayName
        self.plan = plan
    }

    public init(arguments: [String]) throws {
        let valueOptions = Set([
            "--container",
            "--scheme",
            "--configuration",
            "--team",
            "--bundle-id",
            "--product",
            "--device",
            "--derived-data",
            "--build-strategy",
            "--version-policy",
            "--source-marketing-version",
            "--source-build-version",
            "--app-display-name",
        ])
        var values: [String: String] = [:]
        var parsedMode: IOSAppRenewalMode?
        var index = 0

        while index < arguments.count {
            let option = arguments[index]
            if option == "--dry-run" || option == "--execute" {
                guard parsedMode == nil else {
                    throw IOSAppRenewalProfileError.conflictingModes
                }
                parsedMode = option == "--execute" ? .execute : .dryRun
                index += 1
                continue
            }
            guard valueOptions.contains(option) else {
                throw IOSAppRenewalProfileError.unknownOption(option)
            }
            guard values[option] == nil else {
                throw IOSAppRenewalProfileError.duplicateOption(option)
            }
            guard arguments.indices.contains(index + 1),
                  !arguments[index + 1].hasPrefix("--")
            else {
                throw IOSAppRenewalProfileError.missingValue(option)
            }
            values[option] = arguments[index + 1]
            index += 2
        }

        func required(_ option: String) throws -> String {
            guard let value = values[option], !value.isEmpty else {
                throw IOSAppRenewalProfileError.missingRequiredOption(option)
            }
            return value
        }

        let containerPath = try required("--container")
        let derivedDataPath = try required("--derived-data")
        guard containerPath.hasPrefix("/") else {
            throw IOSAppRenewalProfileError.relativePath("--container")
        }
        guard derivedDataPath.hasPrefix("/") else {
            throw IOSAppRenewalProfileError.relativePath("--derived-data")
        }

        mode = parsedMode ?? .dryRun
        if let rawStrategy = values["--build-strategy"] {
            guard let strategy = IOSAppBuildStrategy(
                rawValue: rawStrategy
            ) else {
                throw IOSAppRenewalProfileError.invalidValue(
                    option: "--build-strategy",
                    value: rawStrategy
                )
            }
            buildStrategy = strategy
        } else {
            buildStrategy = .incremental
        }
        if let rawPolicy = values["--version-policy"] {
            guard let policy = IOSAppVersionPolicy(
                rawValue: rawPolicy
            ) else {
                throw IOSAppRenewalProfileError.invalidValue(
                    option: "--version-policy",
                    value: rawPolicy
                )
            }
            versionPolicy = policy
        } else {
            versionPolicy = .keep
        }
        switch (
            values["--source-marketing-version"],
            values["--source-build-version"]
        ) {
        case (nil, nil):
            sourceAppVersion = nil
        case let (marketingVersion?, buildVersion?):
            guard let version = IOSAppVersion(
                marketingVersion: marketingVersion,
                buildVersion: buildVersion
            ) else {
                throw IOSAppRenewalProfileError.invalidValue(
                    option: "--source-marketing-version",
                    value: marketingVersion
                )
            }
            sourceAppVersion = version
        case (nil, _?):
            throw IOSAppRenewalProfileError.missingRequiredOption(
                "--source-marketing-version"
            )
        case (_?, nil):
            throw IOSAppRenewalProfileError.missingRequiredOption(
                "--source-build-version"
            )
        }
        displayName = values["--app-display-name"]
        plan = try IOSAppRenewalPlan(
            containerURL: URL(fileURLWithPath: containerPath),
            scheme: try required("--scheme"),
            configuration: values["--configuration"] ?? "Release",
            developmentTeam: try required("--team"),
            bundleIdentifier: try required("--bundle-id"),
            productName: try required("--product"),
            deviceIdentifier: try required("--device"),
            derivedDataURL: URL(fileURLWithPath: derivedDataPath)
        )
    }

    public var arguments: [String] {
        var result = [
            mode.argument,
            "--build-strategy",
            buildStrategy.rawValue,
            "--version-policy",
            versionPolicy.rawValue,
        ]
        if let sourceAppVersion {
            result += [
                "--source-marketing-version",
                sourceAppVersion.marketingVersion,
                "--source-build-version",
                sourceAppVersion.buildVersion,
            ]
        }
        if let displayName {
            result += ["--app-display-name", displayName]
        }
        result += [
            "--container",
            plan.containerURL.path,
            "--scheme",
            plan.scheme,
            "--configuration",
            plan.configuration,
            "--team",
            plan.developmentTeam,
            "--bundle-id",
            plan.bundleIdentifier,
            "--product",
            plan.productName,
            "--device",
            plan.deviceIdentifier,
            "--derived-data",
            plan.derivedDataURL.path,
        ]
        return result
    }

    public func command(
        helperExecutableURL: URL
    ) -> RenewalCommand {
        RenewalCommand(
            executableURL: helperExecutableURL,
            arguments: arguments
        )
    }

    public static func recognized(
        in command: RenewalCommand,
        bundledHelperURL: URL
    ) -> IOSAppRenewalProfile? {
        guard usesBundledHelper(
            executableURL: command.executableURL,
            bundledHelperURL: bundledHelperURL
        ) else {
            return nil
        }
        return try? IOSAppRenewalProfile(arguments: command.arguments)
    }

    public static func usesBundledHelper(
        executableURL: URL,
        bundledHelperURL: URL
    ) -> Bool {
        executableURL.standardizedFileURL
            == bundledHelperURL.standardizedFileURL
    }
}
