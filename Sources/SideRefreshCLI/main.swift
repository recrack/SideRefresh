import Darwin
import Foundation
import SideRefreshCore

let commandName = "side-refresh"

enum CLIError: LocalizedError {
    case usage(String)

    var errorDescription: String? {
        switch self {
        case .usage(let message):
            return message
        }
    }
}

struct StatusOutput: Encodable {
    let due: Bool
    let lastSuccessfulRenewal: Date?
    let nextDue: Date?
    let renewEveryHours: Int
    let stateFile: String
    let command: RenewalCommand
    let systemChangesPerformed: Bool
}

struct TailnetDiscoveryOutput: Encodable {
    let devices: [TailnetDevice]
    let allDeviceCount: Int
    let source: String
    let systemChangesPerformed: Bool
}

struct ConfigurationSavedOutput: Encodable {
    let configurationFile: String
    let stateFile: String
    let mode: IOSAppRenewalMode
    let buildStrategy: IOSAppBuildStrategy
    let versionPolicy: IOSAppVersionPolicy
    let renewEveryHours: Int
    let systemChangesPerformed: Bool
}

struct ConfiguredStatusOutput: Encodable {
    let configurationFile: String
    let renewEveryHours: Int
    let status: RenewalStatus
    let systemChangesPerformed: Bool
}

struct ParsedCLIOptions {
    var values: [String: String] = [:]
    var flags: Set<String> = []
}

func commonOptions(_ arguments: [String]) throws -> (URL, RenewalInterval) {
    var stateFile: String?
    var renewalInterval = RenewalInterval.personalTeamDefault
    var sawRenewalInterval = false
    var index = 0

    while index < arguments.count {
        let name = arguments[index]
        guard arguments.indices.contains(index + 1) else {
            throw CLIError.usage("missing value for \(name)")
        }
        let value = arguments[index + 1]
        guard !value.hasPrefix("--") else {
            throw CLIError.usage("missing value for \(name)")
        }

        switch name {
        case "--state-file":
            guard stateFile == nil else {
                throw CLIError.usage("--state-file may only be specified once")
            }
            stateFile = value
        case "--renew-every-hours":
            guard !sawRenewalInterval else {
                throw CLIError.usage(
                    "--renew-every-hours may only be specified once"
                )
            }
            guard let parsed = Int(value) else {
                throw CLIError.usage(
                    "--renew-every-hours must be an integer from 1 through 168"
                )
            }
            do {
                renewalInterval = try RenewalInterval(hours: parsed)
            } catch {
                throw CLIError.usage(
                    "--renew-every-hours must be an integer from 1 through 168"
                )
            }
            sawRenewalInterval = true
        default:
            throw CLIError.usage("unknown option: \(name)")
        }
        index += 2
    }

    guard let stateFile else {
        throw CLIError.usage("missing required --state-file PATH")
    }
    return (URL(fileURLWithPath: stateFile), renewalInterval)
}

func runCLI(_ arguments: [String]) throws -> Int32 {
    if arguments.first == "config" {
        return try runConfigurationCLI(
            Array(arguments.dropFirst())
        )
    }
    if arguments.first == "schedule" {
        return try runScheduleCLI(
            Array(arguments.dropFirst())
        )
    }
    if arguments.first == "tailnet" {
        return try runTailnetCLI(Array(arguments.dropFirst()))
    }
    guard arguments.count >= 2, arguments[0] == "renewal" else {
        throw CLIError.usage(
            "usage: \(commandName) <config|renewal|schedule|tailnet> ..."
        )
    }

    let action = arguments[1]
    let actionArguments = Array(arguments.dropFirst(2))

    switch action {
    case "status-config":
        let configurationURL = try configuredRenewalOptions(
            actionArguments
        ).configurationURL
        let configuration = try AgentConfiguration.load(
            from: configurationURL
        )
        let status = try RenewalEngine(
            stateFileURL: configuration.stateFileURL,
            renewalInterval: configuration.renewalInterval
        ).status(for: configuration.command)
        try SideRefreshJSONOutput.write(
            ConfiguredStatusOutput(
                configurationFile: configurationURL.path,
                renewEveryHours: configuration.renewEveryHours,
                status: status,
                systemChangesPerformed: false
            )
        )
        return 0
    case "run-due-config":
        let configurationURL = try configuredRenewalOptions(
            actionArguments
        ).configurationURL
        let configuration = try AgentConfiguration.load(
            from: configurationURL
        )
        let result = try ConfiguredRenewalRunner().runIfDue(
            configuration
        )
        try SideRefreshJSONOutput.write(result)
        return result.processResult?.exitCode ?? 0
    case "run-now":
        let options = try configuredRenewalOptions(
            actionArguments,
            allowsConfirmation: true
        )
        guard options.confirmed else {
            throw CLIError.usage(
                "run-now requires --confirm"
            )
        }
        let configuration = try AgentConfiguration.load(
            from: options.configurationURL
        )
        let profile = try IOSAppRenewalProfile(
            arguments: configuration.command.arguments
        )
        guard profile.mode == .execute else {
            throw CLIError.usage(
                "run-now requires an execute-mode configuration"
            )
        }
        let result = try ConfiguredRenewalRunner().runImmediately(
            configuration
        )
        try SideRefreshJSONOutput.write(result)
        return result.processResult?.exitCode ?? 0
    case "status":
        let invocation = try renewalInvocation(
            actionArguments,
            action: "status"
        )
        let engine = RenewalEngine(
            stateFileURL: invocation.stateFile,
            renewalInterval: invocation.renewalInterval
        )
        let status = try engine.status(for: invocation.command)
        try SideRefreshJSONOutput.write(
            StatusOutput(
                due: status.isDue,
                lastSuccessfulRenewal: status.lastSuccessfulRenewal,
                nextDue: status.nextDue,
                renewEveryHours: invocation.renewalInterval.hours,
                stateFile: invocation.stateFile.path,
                command: invocation.command,
                systemChangesPerformed: false
            )
        )
        return 0
    case "run-due":
        let invocation = try renewalInvocation(
            actionArguments,
            action: "run-due"
        )
        let engine = RenewalEngine(
            stateFileURL: invocation.stateFile,
            renewalInterval: invocation.renewalInterval
        )
        let result = try engine.runIfDue(invocation.command)
        try SideRefreshJSONOutput.write(result)
        return result.processResult?.exitCode ?? 0
    default:
        throw CLIError.usage("unknown renewal action: \(action)")
    }
}

func runConfigurationCLI(_ arguments: [String]) throws -> Int32 {
    guard let action = arguments.first else {
        throw CLIError.usage(
            "usage: \(commandName) config <save|show> ..."
        )
    }
    let actionArguments = Array(arguments.dropFirst())
    switch action {
    case "show":
        let options = try parseOptions(
            actionArguments,
            valueOptions: ["--config"]
        )
        let configurationURL = try absoluteURL(
            options.values["--config"]
                ?? SideRefreshPaths.defaultConfigurationFile.path,
            option: "--config"
        )
        try SideRefreshJSONOutput.write(
            AgentConfiguration.load(from: configurationURL)
        )
        return 0
    case "save":
        guard let separator = actionArguments.firstIndex(of: "--")
        else {
            throw CLIError.usage(
                "config save requires `-- IOS_RENEWAL_ARGUMENTS...`"
            )
        }
        let options = try parseOptions(
            Array(actionArguments.prefix(upTo: separator)),
            valueOptions: [
                "--config",
                "--state-file",
                "--renew-every-hours",
                "--helper",
            ],
            flagOptions: ["--confirm-execute"]
        )
        let profileArguments = Array(
            actionArguments.dropFirst(separator + 1)
        )
        let profile = try IOSAppRenewalProfile(
            arguments: profileArguments
        )
        if profile.mode == .execute,
           !options.flags.contains("--confirm-execute")
        {
            throw CLIError.usage(
                "saving execute mode requires --confirm-execute"
            )
        }
        let helper = try absoluteURL(
            try requiredOption(options, "--helper"),
            option: "--helper"
        )
        guard FileManager.default.isExecutableFile(
            atPath: helper.path
        ) else {
            throw CLIError.usage(
                "--helper must point to an executable file"
            )
        }
        let configurationURL = try absoluteURL(
            options.values["--config"]
                ?? SideRefreshPaths.defaultConfigurationFile.path,
            option: "--config"
        )
        let stateURL = try absoluteURL(
            options.values["--state-file"]
                ?? defaultStateURL(for: configurationURL).path,
            option: "--state-file"
        )
        let interval = try renewalInterval(
            options.values["--renew-every-hours"]
        )
        let configuration = AgentConfiguration(
            stateFileURL: stateURL,
            renewalInterval: interval,
            command: profile.command(
                helperExecutableURL: helper
            )
        )
        try configuration.write(to: configurationURL)
        try SideRefreshJSONOutput.write(
            ConfigurationSavedOutput(
                configurationFile: configurationURL.path,
                stateFile: stateURL.path,
                mode: profile.mode,
                buildStrategy: profile.buildStrategy,
                versionPolicy: profile.versionPolicy,
                renewEveryHours: interval.hours,
                systemChangesPerformed: true
            )
        )
        return 0
    default:
        throw CLIError.usage(
            "unknown config action: \(action)"
        )
    }
}

func runScheduleCLI(_ arguments: [String]) throws -> Int32 {
    guard let action = arguments.first,
          ["status", "enable", "disable"].contains(action)
    else {
        throw CLIError.usage(
            "usage: \(commandName) schedule <status|enable|disable> ..."
        )
    }
    let options = try parseOptions(
        Array(arguments.dropFirst()),
        valueOptions: ["--config", "--agent", "--plist"],
        flagOptions: ["--confirm"]
    )
    if action != "status",
       !options.flags.contains("--confirm")
    {
        throw CLIError.usage(
            "schedule \(action) requires --confirm"
        )
    }
    let configurationURL = try absoluteURL(
        options.values["--config"]
            ?? SideRefreshPaths.defaultConfigurationFile.path,
        option: "--config"
    )
    let agentURL = try absoluteURL(
        options.values["--agent"]
            ?? siblingExecutableURL("SideRefreshAgent").path,
        option: "--agent"
    )
    let plistURL = try absoluteURL(
        options.values["--plist"]
            ?? HeadlessLaunchAgentController
                .defaultLaunchAgentFileURL.path,
        option: "--plist"
    )
    let controller = HeadlessLaunchAgentController(
        agentExecutableURL: agentURL,
        configurationFileURL: configurationURL,
        launchAgentFileURL: plistURL
    )
    let status: HeadlessLaunchAgentStatus
    switch action {
    case "status":
        status = try controller.status()
    case "enable":
        let configuration = try AgentConfiguration.load(
            from: configurationURL
        )
        let profile = try IOSAppRenewalProfile(
            arguments: configuration.command.arguments
        )
        guard profile.mode == .execute else {
            throw CLIError.usage(
                "schedule enable requires an execute-mode configuration"
            )
        }
        status = try controller.enable()
    case "disable":
        status = try controller.disable()
    default:
        fatalError("validated schedule action")
    }
    try SideRefreshJSONOutput.write(status)
    return 0
}

func configuredRenewalOptions(
    _ arguments: [String],
    allowsConfirmation: Bool = false
) throws -> (configurationURL: URL, confirmed: Bool) {
    let parsed = try parseOptions(
        arguments,
        valueOptions: ["--config"],
        flagOptions: allowsConfirmation ? ["--confirm"] : []
    )
    return (
        try absoluteURL(
            parsed.values["--config"]
                ?? SideRefreshPaths.defaultConfigurationFile.path,
            option: "--config"
        ),
        parsed.flags.contains("--confirm")
    )
}

func parseOptions(
    _ arguments: [String],
    valueOptions: Set<String>,
    flagOptions: Set<String> = []
) throws -> ParsedCLIOptions {
    var parsed = ParsedCLIOptions()
    var index = 0
    while index < arguments.count {
        let option = arguments[index]
        if flagOptions.contains(option) {
            guard parsed.flags.insert(option).inserted else {
                throw CLIError.usage(
                    "\(option) may only be specified once"
                )
            }
            index += 1
            continue
        }
        guard valueOptions.contains(option) else {
            throw CLIError.usage("unknown option: \(option)")
        }
        guard parsed.values[option] == nil else {
            throw CLIError.usage(
                "\(option) may only be specified once"
            )
        }
        guard arguments.indices.contains(index + 1) else {
            throw CLIError.usage("missing value for \(option)")
        }
        let value = arguments[index + 1]
        guard !value.hasPrefix("--") else {
            throw CLIError.usage("missing value for \(option)")
        }
        parsed.values[option] = value
        index += 2
    }
    return parsed
}

func requiredOption(
    _ options: ParsedCLIOptions,
    _ name: String
) throws -> String {
    guard let value = options.values[name], !value.isEmpty else {
        throw CLIError.usage("missing required \(name) PATH")
    }
    return value
}

func renewalInterval(_ rawValue: String?) throws -> RenewalInterval {
    guard let rawValue else {
        return .personalTeamDefault
    }
    guard let hours = Int(rawValue) else {
        throw CLIError.usage(
            "--renew-every-hours must be an integer from 1 through 168"
        )
    }
    do {
        return try RenewalInterval(hours: hours)
    } catch {
        throw CLIError.usage(
            "--renew-every-hours must be an integer from 1 through 168"
        )
    }
}

func absoluteURL(_ path: String, option: String) throws -> URL {
    guard path.hasPrefix("/") else {
        throw CLIError.usage(
            "\(option) must be an absolute path"
        )
    }
    return URL(fileURLWithPath: path).standardizedFileURL
}

func defaultStateURL(for configurationURL: URL) -> URL {
    if configurationURL
        == SideRefreshPaths.defaultConfigurationFile
    {
        return SideRefreshPaths.defaultStateFile
    }
    return configurationURL
        .deletingLastPathComponent()
        .appendingPathComponent("renewal-state.json")
}

func siblingExecutableURL(_ name: String) -> URL {
    URL(fileURLWithPath: CommandLine.arguments[0])
        .standardizedFileURL
        .deletingLastPathComponent()
        .appendingPathComponent(name)
}

func renewalInvocation(
    _ arguments: [String],
    action: String
) throws -> (
    stateFile: URL,
    renewalInterval: RenewalInterval,
    command: RenewalCommand
) {
    guard let separator = arguments.firstIndex(of: "--") else {
        throw CLIError.usage(
            "\(action) requires `-- EXECUTABLE [ARGUMENTS...]`"
        )
    }
    let options = Array(arguments.prefix(upTo: separator))
    let (stateFile, renewalInterval) = try commonOptions(options)
    let commandArguments = Array(arguments.dropFirst(separator + 1))
    guard let executable = commandArguments.first,
          executable.hasPrefix("/")
    else {
        throw CLIError.usage("renewal executable must be an absolute path")
    }
    return (
        stateFile,
        renewalInterval,
        RenewalCommand(
            executableURL: URL(fileURLWithPath: executable),
            arguments: Array(commandArguments.dropFirst())
        )
    )
}

func runTailnetCLI(_ arguments: [String]) throws -> Int32 {
    guard arguments.first == "discover" else {
        throw CLIError.usage(
            "usage: \(commandName) tailnet discover "
                + "(--status-file PATH | --tailscale EXECUTABLE)"
        )
    }
    let options = Array(arguments.dropFirst())
    guard options.count == 2 else {
        throw CLIError.usage(
            "tailnet discover requires exactly one status source"
        )
    }
    let option = options[0]
    let path = options[1]
    guard path.hasPrefix("/") else {
        throw CLIError.usage("\(option) must be an absolute path")
    }

    let snapshot: TailnetSnapshot
    let source: String
    switch option {
    case "--status-file":
        snapshot = try TailscaleStatusParser.parse(
            Data(contentsOf: URL(fileURLWithPath: path))
        )
        source = "status-file"
    case "--tailscale":
        snapshot = try TailscaleStatusReader().read(
            executableURL: URL(fileURLWithPath: path)
        )
        source = "tailscale-status"
    default:
        throw CLIError.usage("unknown tailnet source: \(option)")
    }

    try SideRefreshJSONOutput.write(
        TailnetDiscoveryOutput(
            devices: snapshot.iOSDevices,
            allDeviceCount: snapshot.devices.count,
            source: source,
            systemChangesPerformed: false
        )
    )
    return 0
}

do {
    exit(try runCLI(Array(CommandLine.arguments.dropFirst())))
} catch {
    SideRefreshJSONOutput.writeError(
        "\(commandName): \(error.localizedDescription)\n"
    )
    exit(2)
}
