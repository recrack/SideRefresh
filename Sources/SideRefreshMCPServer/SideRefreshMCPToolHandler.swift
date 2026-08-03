import Darwin
import Foundation
import SideRefreshCore

public struct SideRefreshMCPToolResult: Equatable, Sendable {
    public let content: String
    public let structuredContent: MCPJSONValue
    public let isError: Bool

    public init(
        content: String,
        structuredContent: MCPJSONValue,
        isError: Bool = false
    ) {
        self.content = content
        self.structuredContent = structuredContent
        self.isError = isError
    }
}

public struct SideRefreshMCPDependencies: Sendable {
    public let runCommand:
        @Sendable (RenewalCommand) throws -> ProcessResult
    public let runImmediately:
        @Sendable (AgentConfiguration) throws -> RenewalRunResult
    public let launchctlExecutor: HeadlessLaunchAgentCommandExecutor

    public init(
        runCommand:
            @escaping @Sendable (RenewalCommand) throws -> ProcessResult,
        runImmediately:
            @escaping @Sendable (
                AgentConfiguration
            ) throws -> RenewalRunResult,
        launchctlExecutor: HeadlessLaunchAgentCommandExecutor
    ) {
        self.runCommand = runCommand
        self.runImmediately = runImmediately
        self.launchctlExecutor = launchctlExecutor
    }

    public init() {
        runCommand = {
            try BoundedProcessRunner().run($0)
        }
        runImmediately = {
            try ConfiguredRenewalRunner().runImmediately($0)
        }
        launchctlExecutor = .init()
    }
}

public struct SideRefreshMCPToolHandler: Sendable {
    public let defaultConfigurationFileURL: URL
    public let helperExecutableURL: URL
    public let agentExecutableURL: URL
    public let launchAgentFileURL: URL
    public let userIdentifier: uid_t

    private let dependencies: SideRefreshMCPDependencies

    public init(
        defaultConfigurationFileURL: URL =
            SideRefreshPaths.defaultConfigurationFile,
        helperExecutableURL: URL,
        agentExecutableURL: URL,
        launchAgentFileURL: URL =
            HeadlessLaunchAgentController.defaultLaunchAgentFileURL,
        userIdentifier: uid_t = getuid(),
        dependencies: SideRefreshMCPDependencies = .init()
    ) {
        self.defaultConfigurationFileURL =
            defaultConfigurationFileURL.standardizedFileURL
        self.helperExecutableURL =
            helperExecutableURL.standardizedFileURL
        self.agentExecutableURL =
            agentExecutableURL.standardizedFileURL
        self.launchAgentFileURL =
            launchAgentFileURL.standardizedFileURL
        self.userIdentifier = userIdentifier
        self.dependencies = dependencies
    }

    public static var toolDefinitions: [MCPJSONValue] {
        [
            tool(
                name: "get_status",
                description:
                    "Read the saved SideRefresh target, refresh due state, and background schedule state without changing anything.",
                properties: [
                    "config_path": stringProperty(
                        "Absolute configuration path. Uses SideRefresh's default when omitted."
                    ),
                ],
                annotations: readOnlyAnnotations
            ),
            tool(
                name: "configure_target",
                description:
                    "Save one iOS app renewal target for the headless Agent. Execute mode requires confirm_execute=true.",
                properties: configurationProperties,
                required: [
                    "confirm",
                    "container",
                    "scheme",
                    "team",
                    "bundle_id",
                    "product",
                    "device",
                    "derived_data",
                ],
                annotations: mutationAnnotations(
                    destructive: false,
                    idempotent: true,
                    openWorld: false
                )
            ),
            tool(
                name: "dry_run",
                description:
                    "Resolve and print the configured Xcode build/install plan without building, signing, installing, or updating renewal state.",
                properties: [
                    "config_path": stringProperty(
                        "Absolute configuration path. Uses SideRefresh's default when omitted."
                    ),
                ],
                annotations: readOnlyAnnotations
            ),
            tool(
                name: "renew_now",
                description:
                    "Immediately build, sign, and install the configured iOS app. Requires an execute-mode target and confirm=true.",
                properties: confirmationProperties,
                required: ["confirm"],
                annotations: mutationAnnotations(
                    destructive: true,
                    idempotent: false,
                    openWorld: true
                )
            ),
            tool(
                name: "enable_schedule",
                description:
                    "Install and bootstrap the user LaunchAgent for unattended renewal checks. Requires confirm=true and an execute-mode target.",
                properties: confirmationProperties,
                required: ["confirm"],
                annotations: mutationAnnotations(
                    destructive: false,
                    idempotent: true,
                    openWorld: false
                )
            ),
            tool(
                name: "disable_schedule",
                description:
                    "Boot out SideRefresh's user LaunchAgent and remove only its plist. Keeps binaries, target configuration, and refresh state. Requires confirm=true.",
                properties: confirmationProperties,
                required: ["confirm"],
                annotations: mutationAnnotations(
                    destructive: true,
                    idempotent: true,
                    openWorld: false
                )
            ),
        ]
    }

    public func call(
        name: String,
        arguments: [String: MCPJSONValue] = [:]
    ) -> SideRefreshMCPToolResult {
        do {
            switch name {
            case "get_status":
                return try status(arguments)
            case "configure_target":
                return try configure(arguments)
            case "dry_run":
                return try dryRun(arguments)
            case "renew_now":
                return try renewNow(arguments)
            case "enable_schedule":
                return try enableSchedule(arguments)
            case "disable_schedule":
                return try disableSchedule(arguments)
            default:
                throw SideRefreshMCPToolError.unknownTool(name)
            }
        } catch {
            return .init(
                content: error.localizedDescription,
                structuredContent: .object([
                    "error": .string(error.localizedDescription),
                ]),
                isError: true
            )
        }
    }

    private func status(
        _ arguments: [String: MCPJSONValue]
    ) throws -> SideRefreshMCPToolResult {
        try requireOnly(
            arguments,
            keys: ["config_path"]
        )
        let configurationURL = try configurationURL(arguments)
        let schedule = try launchAgentController(
            configurationFileURL: configurationURL
        ).status()
        guard FileManager.default.fileExists(
            atPath: configurationURL.path
        ) else {
            let output = StatusOutput(
                configured: false,
                configurationPath: configurationURL.path,
                due: nil,
                lastSuccessfulRenewal: nil,
                nextDue: nil,
                provisioningExpirationDate: nil,
                renewEveryHours: nil,
                mode: nil,
                buildStrategy: nil,
                versionPolicy: nil,
                containerPath: nil,
                scheme: nil,
                developmentTeam: nil,
                bundleIdentifier: nil,
                productName: nil,
                coreDeviceIdentifier: nil,
                tailnetNodeIdentifier: nil,
                tailnetDNSName: nil,
                helperExecutable: nil,
                schedule: schedule,
                scheduleMatchesConfiguration:
                    schedule.configurationPath.map {
                        $0 == configurationURL.path
                    }
            )
            return try result(
                "SideRefresh target is not configured.",
                output
            )
        }

        let configuration = try AgentConfiguration.load(
            from: configurationURL
        )
        let renewalStatus = try RenewalEngine(
            stateFileURL: configuration.stateFileURL,
            renewalInterval: configuration.renewalInterval
        ).status(for: configuration.command)
        let profile = try? IOSAppRenewalProfile(
            arguments: configuration.command.arguments
        )
        let output = StatusOutput(
            configured: true,
            configurationPath: configurationURL.path,
            due: renewalStatus.isDue,
            lastSuccessfulRenewal:
                renewalStatus.lastSuccessfulRenewal,
            nextDue: renewalStatus.nextDue,
            provisioningExpirationDate:
                renewalStatus.provisioningExpirationDate,
            renewEveryHours: configuration.renewEveryHours,
            mode: profile?.mode.rawValue,
            buildStrategy: profile?.buildStrategy.rawValue,
            versionPolicy: profile?.versionPolicy.rawValue,
            containerPath: profile?.plan.containerURL.path,
            scheme: profile?.plan.scheme,
            developmentTeam: profile?.plan.developmentTeam,
            bundleIdentifier: profile?.plan.bundleIdentifier,
            productName: profile?.plan.productName,
            coreDeviceIdentifier:
                profile?.plan.deviceIdentifier,
            tailnetNodeIdentifier:
                configuration.tailnetTarget?.nodeID,
            tailnetDNSName:
                configuration.tailnetTarget?.dnsName,
            helperExecutable:
                configuration.command.executable,
            schedule: schedule,
            scheduleMatchesConfiguration:
                schedule.configurationPath.map {
                    $0 == configurationURL.path
                }
        )
        return try result(
            renewalStatus.isDue
                ? "The configured target is due for renewal."
                : "The configured target is not due yet.",
            output
        )
    }

    private func configure(
        _ arguments: [String: MCPJSONValue]
    ) throws -> SideRefreshMCPToolResult {
        try requireOnly(
            arguments,
            keys: Set(Self.configurationProperties.keys)
        )
        try requireConfirmation(arguments, key: "confirm")
        guard FileManager.default.isExecutableFile(
            atPath: helperExecutableURL.path
        ) else {
            throw SideRefreshMCPToolError.helperNotExecutable(
                helperExecutableURL.path
            )
        }

        let mode = try enumValue(
            arguments,
            key: "mode",
            defaultValue: IOSAppRenewalMode.dryRun
        )
        if mode == .execute {
            try requireConfirmation(
                arguments,
                key: "confirm_execute"
            )
        }
        let strategy = try enumValue(
            arguments,
            key: "build_strategy",
            defaultValue: IOSAppBuildStrategy.incremental
        )
        let versionPolicy = try enumValue(
            arguments,
            key: "version_policy",
            defaultValue: IOSAppVersionPolicy.keep
        )
        var profileArguments = [
            mode.argument,
            "--build-strategy",
            strategy.rawValue,
            "--version-policy",
            versionPolicy.rawValue,
            "--container",
            try requiredString(arguments, "container"),
            "--scheme",
            try requiredString(arguments, "scheme"),
            "--configuration",
            try optionalString(arguments, "configuration") ?? "Release",
            "--team",
            try requiredString(arguments, "team"),
            "--bundle-id",
            try requiredString(arguments, "bundle_id"),
            "--product",
            try requiredString(arguments, "product"),
            "--device",
            try requiredString(arguments, "device"),
            "--derived-data",
            try requiredString(arguments, "derived_data"),
        ]
        let sourceMarketing = try optionalString(
            arguments,
            "source_marketing_version"
        )
        let sourceBuild = try optionalString(
            arguments,
            "source_build_version"
        )
        switch (sourceMarketing, sourceBuild) {
        case let (marketing?, build?):
            profileArguments += [
                "--source-marketing-version",
                marketing,
                "--source-build-version",
                build,
            ]
        case (nil, nil):
            break
        default:
            throw SideRefreshMCPToolError.invalidArguments(
                "source_marketing_version and source_build_version must be supplied together."
            )
        }

        let profile = try IOSAppRenewalProfile(
            arguments: profileArguments
        )
        let configurationURL = try configurationURL(arguments)
        let stateFileURL: URL
        if let path = try optionalString(arguments, "state_path") {
            stateFileURL = try absoluteURL(path, key: "state_path")
        } else if configurationURL
            == defaultConfigurationFileURL
        {
            stateFileURL = SideRefreshPaths.defaultStateFile
        } else {
            stateFileURL = configurationURL
                .deletingLastPathComponent()
                .appendingPathComponent("renewal-state.json")
        }
        let interval = try RenewalInterval(
            hours: try optionalInt(
                arguments,
                "renew_every_hours"
            ) ?? RenewalInterval.personalTeamDefault.hours
        )
        let tailnetTarget = try makeTailnetTarget(arguments)
        let configuration = AgentConfiguration(
            stateFileURL: stateFileURL,
            renewalInterval: interval,
            tailnetTarget: tailnetTarget,
            command: profile.command(
                helperExecutableURL: helperExecutableURL
            )
        )
        try configuration.write(to: configurationURL)
        let output = ConfigurationOutput(
            configurationPath: configurationURL.path,
            statePath: stateFileURL.path,
            mode: profile.mode.rawValue,
            buildStrategy: profile.buildStrategy.rawValue,
            versionPolicy: profile.versionPolicy.rawValue,
            renewEveryHours: interval.hours,
            bundleIdentifier: profile.plan.bundleIdentifier,
            scheme: profile.plan.scheme,
            deviceIdentifier: profile.plan.deviceIdentifier
        )
        return try result(
            profile.mode == .execute
                ? "Execute-mode renewal target saved."
                : "Dry-run renewal target saved.",
            output
        )
    }

    private func dryRun(
        _ arguments: [String: MCPJSONValue]
    ) throws -> SideRefreshMCPToolResult {
        try requireOnly(arguments, keys: ["config_path"])
        let configuration = try loadConfiguration(arguments)
        let savedProfile = try IOSAppRenewalProfile(
            arguments: configuration.command.arguments
        )
        let dryRunProfile = IOSAppRenewalProfile(
            mode: .dryRun,
            buildStrategy: savedProfile.buildStrategy,
            versionPolicy: savedProfile.versionPolicy,
            sourceAppVersion: savedProfile.sourceAppVersion,
            plan: savedProfile.plan
        )
        let processResult = try dependencies.runCommand(
            dryRunProfile.command(
                helperExecutableURL:
                    configuration.command.executableURL
            )
        )
        guard processResult.exitCode == 0 else {
            throw SideRefreshMCPToolError.commandFailed(
                processResult.exitCode,
                processResult.standardError
            )
        }
        let plan = try JSONDecoder().decode(
            MCPJSONValue.self,
            from: Data(processResult.standardOutput.utf8)
        )
        return SideRefreshMCPToolResult(
            content:
                "Dry run completed without building, signing, installing, or updating renewal state.",
            structuredContent: plan
        )
    }

    private func renewNow(
        _ arguments: [String: MCPJSONValue]
    ) throws -> SideRefreshMCPToolResult {
        try requireOnly(
            arguments,
            keys: ["config_path", "confirm"]
        )
        try requireConfirmation(arguments, key: "confirm")
        let configuration = try loadConfiguration(arguments)
        let profile = try IOSAppRenewalProfile(
            arguments: configuration.command.arguments
        )
        guard profile.mode == .execute else {
            throw SideRefreshMCPToolError.executeModeRequired
        }
        let output = try dependencies.runImmediately(configuration)
        return try result(
            output.succeeded
                ? "Immediate renewal succeeded."
                : "Immediate renewal did not succeed.",
            output,
            isError: !output.succeeded
        )
    }

    private func enableSchedule(
        _ arguments: [String: MCPJSONValue]
    ) throws -> SideRefreshMCPToolResult {
        try requireOnly(
            arguments,
            keys: ["config_path", "confirm"]
        )
        try requireConfirmation(arguments, key: "confirm")
        let configurationURL = try configurationURL(arguments)
        let configuration = try AgentConfiguration.load(
            from: configurationURL
        )
        let profile = try IOSAppRenewalProfile(
            arguments: configuration.command.arguments
        )
        guard profile.mode == .execute else {
            throw SideRefreshMCPToolError.executeModeRequired
        }
        let output = try launchAgentController(
            configurationFileURL: configurationURL
        ).enable()
        return try result(
            "Background renewal schedule enabled.",
            output
        )
    }

    private func disableSchedule(
        _ arguments: [String: MCPJSONValue]
    ) throws -> SideRefreshMCPToolResult {
        try requireOnly(
            arguments,
            keys: ["config_path", "confirm"]
        )
        try requireConfirmation(arguments, key: "confirm")
        let output = try launchAgentController(
            configurationFileURL: try configurationURL(arguments)
        ).disable()
        return try result(
            "Background renewal schedule disabled. Configuration and state were kept.",
            output
        )
    }

    private func loadConfiguration(
        _ arguments: [String: MCPJSONValue]
    ) throws -> AgentConfiguration {
        try AgentConfiguration.load(
            from: configurationURL(arguments)
        )
    }

    private func configurationURL(
        _ arguments: [String: MCPJSONValue]
    ) throws -> URL {
        guard let path = try optionalString(
            arguments,
            "config_path"
        ) else {
            return defaultConfigurationFileURL
        }
        return try absoluteURL(path, key: "config_path")
    }

    private func makeTailnetTarget(
        _ arguments: [String: MCPJSONValue]
    ) throws -> TailnetTarget? {
        let executable = try optionalString(
            arguments,
            "tailscale_executable"
        )
        let nodeID = try optionalString(
            arguments,
            "tailnet_node_id"
        )
        let dnsName = try optionalString(
            arguments,
            "tailnet_dns_name"
        )
        switch (executable, nodeID, dnsName) {
        case (nil, nil, nil):
            return nil
        case let (executable?, nodeID?, dnsName?):
            return TailnetTarget(
                tailscaleExecutable: executable,
                nodeID: nodeID,
                dnsName: dnsName
            )
        default:
            throw SideRefreshMCPToolError.invalidArguments(
                "tailscale_executable, tailnet_node_id, and tailnet_dns_name must be supplied together."
            )
        }
    }

    private func launchAgentController(
        configurationFileURL: URL
    ) -> HeadlessLaunchAgentController {
        HeadlessLaunchAgentController(
            agentExecutableURL: agentExecutableURL,
            configurationFileURL: configurationFileURL,
            launchAgentFileURL: launchAgentFileURL,
            userIdentifier: userIdentifier,
            commandExecutor: dependencies.launchctlExecutor
        )
    }

    private func result<T: Encodable>(
        _ content: String,
        _ structuredContent: T,
        isError: Bool = false
    ) throws -> SideRefreshMCPToolResult {
        SideRefreshMCPToolResult(
            content: content,
            structuredContent: try MCPJSONValue(
                encoding: structuredContent
            ),
            isError: isError
        )
    }

    private func requireOnly(
        _ arguments: [String: MCPJSONValue],
        keys: Set<String>
    ) throws {
        let unknown = Set(arguments.keys).subtracting(keys)
        guard unknown.isEmpty else {
            throw SideRefreshMCPToolError.invalidArguments(
                "Unknown argument(s): \(unknown.sorted().joined(separator: ", "))."
            )
        }
    }

    private func requiredString(
        _ arguments: [String: MCPJSONValue],
        _ key: String
    ) throws -> String {
        guard let value = try optionalString(arguments, key),
              !value.isEmpty
        else {
            throw SideRefreshMCPToolError.invalidArguments(
                "\(key) is required."
            )
        }
        return value
    }

    private func optionalString(
        _ arguments: [String: MCPJSONValue],
        _ key: String
    ) throws -> String? {
        guard let raw = arguments[key] else {
            return nil
        }
        guard let value = raw.stringValue else {
            throw SideRefreshMCPToolError.invalidArguments(
                "\(key) must be a string."
            )
        }
        return value
    }

    private func optionalInt(
        _ arguments: [String: MCPJSONValue],
        _ key: String
    ) throws -> Int? {
        guard let raw = arguments[key] else {
            return nil
        }
        guard let value = raw.intValue else {
            throw SideRefreshMCPToolError.invalidArguments(
                "\(key) must be an integer."
            )
        }
        return value
    }

    private func requireConfirmation(
        _ arguments: [String: MCPJSONValue],
        key: String
    ) throws {
        guard arguments[key]?.boolValue == true else {
            throw SideRefreshMCPToolError.confirmationRequired(key)
        }
    }

    private func enumValue<T>(
        _ arguments: [String: MCPJSONValue],
        key: String,
        defaultValue: T
    ) throws -> T where T: RawRepresentable, T.RawValue == String {
        guard let value = try optionalString(arguments, key) else {
            return defaultValue
        }
        guard let parsed = T(rawValue: value) else {
            throw SideRefreshMCPToolError.invalidArguments(
                "Unsupported \(key) value: \(value)."
            )
        }
        return parsed
    }

    private func absoluteURL(
        _ path: String,
        key: String
    ) throws -> URL {
        guard path.hasPrefix("/") else {
            throw SideRefreshMCPToolError.invalidArguments(
                "\(key) must be an absolute path."
            )
        }
        return URL(fileURLWithPath: path).standardizedFileURL
    }
}

public enum SideRefreshMCPToolError: LocalizedError, Equatable {
    case commandFailed(Int32, String)
    case confirmationRequired(String)
    case executeModeRequired
    case helperNotExecutable(String)
    case invalidArguments(String)
    case unknownTool(String)

    public var errorDescription: String? {
        switch self {
        case let .commandFailed(exitCode, message):
            let detail = message.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            return detail.isEmpty
                ? "SideRefresh command failed with exit code \(exitCode)."
                : "SideRefresh command failed with exit code \(exitCode): \(detail)"
        case .confirmationRequired(let key):
            return "\(key)=true is required for this operation."
        case .executeModeRequired:
            return "An execute-mode renewal target is required."
        case .helperNotExecutable(let path):
            return "SideRefresh iOS refresh helper is not executable at \(path)."
        case .invalidArguments(let message):
            return message
        case .unknownTool(let name):
            return "Unknown SideRefresh tool: \(name)."
        }
    }
}

private struct StatusOutput: Codable {
    let configured: Bool
    let configurationPath: String
    let due: Bool?
    let lastSuccessfulRenewal: Date?
    let nextDue: Date?
    let provisioningExpirationDate: Date?
    let renewEveryHours: Int?
    let mode: String?
    let buildStrategy: String?
    let versionPolicy: String?
    let containerPath: String?
    let scheme: String?
    let developmentTeam: String?
    let bundleIdentifier: String?
    let productName: String?
    let coreDeviceIdentifier: String?
    let tailnetNodeIdentifier: String?
    let tailnetDNSName: String?
    let helperExecutable: String?
    let schedule: HeadlessLaunchAgentStatus
    let scheduleMatchesConfiguration: Bool?

    private enum CodingKeys: String, CodingKey {
        case configured
        case configurationPath = "configuration_path"
        case due
        case lastSuccessfulRenewal = "last_successful_renewal"
        case nextDue = "next_due"
        case provisioningExpirationDate =
            "provisioning_expiration_date"
        case renewEveryHours = "renew_every_hours"
        case mode
        case buildStrategy = "build_strategy"
        case versionPolicy = "version_policy"
        case containerPath = "container_path"
        case scheme
        case developmentTeam = "development_team"
        case bundleIdentifier = "bundle_identifier"
        case productName = "product_name"
        case coreDeviceIdentifier = "core_device_identifier"
        case tailnetNodeIdentifier = "tailnet_node_identifier"
        case tailnetDNSName = "tailnet_dns_name"
        case helperExecutable = "helper_executable"
        case schedule
        case scheduleMatchesConfiguration =
            "schedule_matches_configuration"
    }
}

private struct ConfigurationOutput: Codable {
    let configurationPath: String
    let statePath: String
    let mode: String
    let buildStrategy: String
    let versionPolicy: String
    let renewEveryHours: Int
    let bundleIdentifier: String
    let scheme: String
    let deviceIdentifier: String

    private enum CodingKeys: String, CodingKey {
        case configurationPath = "configuration_path"
        case statePath = "state_path"
        case mode
        case buildStrategy = "build_strategy"
        case versionPolicy = "version_policy"
        case renewEveryHours = "renew_every_hours"
        case bundleIdentifier = "bundle_identifier"
        case scheme
        case deviceIdentifier = "device_identifier"
    }
}

private extension SideRefreshMCPToolHandler {
    static let readOnlyAnnotations: MCPJSONValue = .object([
        "readOnlyHint": .bool(true),
        "destructiveHint": .bool(false),
        "idempotentHint": .bool(true),
        "openWorldHint": .bool(false),
    ])

    static let confirmationProperties: [String: MCPJSONValue] = [
        "config_path": stringProperty(
            "Absolute configuration path. Uses SideRefresh's default when omitted."
        ),
        "confirm": .object([
            "type": .string("boolean"),
            "description": .string(
                "Must be true to confirm this state-changing operation."
            ),
        ]),
    ]

    static let configurationProperties: [String: MCPJSONValue] = [
        "confirm": .object([
            "type": .string("boolean"),
            "description": .string(
                "Must be true to confirm writing or replacing the saved target."
            ),
        ]),
        "config_path": stringProperty(
            "Absolute configuration path. Uses SideRefresh's default when omitted."
        ),
        "state_path": stringProperty(
            "Absolute renewal state path. Defaults beside a custom configuration."
        ),
        "container": stringProperty(
            "Absolute .xcodeproj or .xcworkspace path."
        ),
        "scheme": stringProperty("Xcode scheme."),
        "configuration": stringProperty(
            "Xcode build configuration. Defaults to Release."
        ),
        "team": stringProperty(
            "Apple Personal Team identifier."
        ),
        "bundle_id": stringProperty(
            "Expected iOS application Bundle ID."
        ),
        "product": stringProperty(
            "Built .app product name without the extension."
        ),
        "device": stringProperty("CoreDevice iPhone UDID."),
        "derived_data": stringProperty(
            "Absolute stable Derived Data path."
        ),
        "renew_every_hours": .object([
            "type": .string("integer"),
            "minimum": .int(1),
            "maximum": .int(168),
            "default": .int(144),
        ]),
        "mode": .object([
            "type": .string("string"),
            "enum": .array([
                .string("dry-run"),
                .string("execute"),
            ]),
            "default": .string("dry-run"),
        ]),
        "confirm_execute": .object([
            "type": .string("boolean"),
            "description": .string(
                "Must be true when mode is execute."
            ),
        ]),
        "build_strategy": .object([
            "type": .string("string"),
            "enum": .array([
                .string("incremental"),
                .string("clean-rebuild"),
            ]),
            "default": .string("incremental"),
        ]),
        "version_policy": .object([
            "type": .string("string"),
            "enum": .array([
                .string("keep"),
                .string("automatic"),
            ]),
            "default": .string("keep"),
        ]),
        "source_marketing_version": stringProperty(
            "Optional project marketing version paired with source_build_version."
        ),
        "source_build_version": stringProperty(
            "Optional project build version paired with source_marketing_version."
        ),
        "tailscale_executable": stringProperty(
            "Optional absolute Tailscale CLI path."
        ),
        "tailnet_node_id": stringProperty(
            "Optional stable Tailscale node ID."
        ),
        "tailnet_dns_name": stringProperty(
            "Optional Tailscale DNS name."
        ),
    ]

    static func stringProperty(
        _ description: String
    ) -> MCPJSONValue {
        .object([
            "type": .string("string"),
            "description": .string(description),
        ])
    }

    static func mutationAnnotations(
        destructive: Bool,
        idempotent: Bool,
        openWorld: Bool
    ) -> MCPJSONValue {
        .object([
            "readOnlyHint": .bool(false),
            "destructiveHint": .bool(destructive),
            "idempotentHint": .bool(idempotent),
            "openWorldHint": .bool(openWorld),
        ])
    }

    static func tool(
        name: String,
        description: String,
        properties: [String: MCPJSONValue],
        required: [String] = [],
        annotations: MCPJSONValue
    ) -> MCPJSONValue {
        var schema: [String: MCPJSONValue] = [
            "type": .string("object"),
            "properties": .object(properties),
            "additionalProperties": .bool(false),
        ]
        if !required.isEmpty {
            schema["required"] = .array(
                required.map(MCPJSONValue.string)
            )
        }
        return .object([
            "name": .string(name),
            "description": .string(description),
            "inputSchema": .object(schema),
            "annotations": annotations,
        ])
    }
}
