import Darwin
import Foundation

public enum HeadlessLaunchAgentState: String, Codable, Equatable, Sendable {
    case disabled
    case enabled
    case installedNotLoaded = "installed-not-loaded"
}

public struct HeadlessLaunchAgentStatus:
    Codable,
    Equatable,
    Sendable
{
    public let label: String
    public let state: HeadlessLaunchAgentState
    public let plistPath: String
    public let configurationPath: String?

    public init(
        label: String,
        state: HeadlessLaunchAgentState,
        plistPath: String,
        configurationPath: String? = nil
    ) {
        self.label = label
        self.state = state
        self.plistPath = plistPath
        self.configurationPath = configurationPath
    }
}

public enum HeadlessLaunchAgentError: LocalizedError, Equatable {
    case agentNotExecutable(String)
    case configurationMissing(String)
    case launchctlFailed(action: String, message: String)

    public var errorDescription: String? {
        switch self {
        case .agentNotExecutable(let path):
            return "SideRefresh Agent is not executable at \(path)."
        case .configurationMissing(let path):
            return "No SideRefresh configuration exists at \(path)."
        case let .launchctlFailed(action, message):
            return "launchctl \(action) failed: \(message)"
        }
    }
}

public struct HeadlessLaunchAgentCommandExecutor: Sendable {
    private let execute:
        @Sendable (RenewalCommand) throws -> ProcessResult

    public init(
        execute:
            @escaping @Sendable (RenewalCommand) throws -> ProcessResult
    ) {
        self.execute = execute
    }

    public init() {
        self.init {
            try BoundedProcessRunner(
                executionTimeout: 30,
                processGroupMode: .inherited
            ).run($0)
        }
    }

    public func callAsFunction(
        _ command: RenewalCommand
    ) throws -> ProcessResult {
        try execute(command)
    }
}

public struct HeadlessLaunchAgentController: Sendable {
    public static let label = "io.github.siderefresh.renewal"

    public let agentExecutableURL: URL
    public let configurationFileURL: URL
    public let launchAgentFileURL: URL
    public let userIdentifier: uid_t

    private let commandExecutor: HeadlessLaunchAgentCommandExecutor

    public init(
        agentExecutableURL: URL,
        configurationFileURL: URL =
            SideRefreshPaths.defaultConfigurationFile,
        launchAgentFileURL: URL =
            HeadlessLaunchAgentController.defaultLaunchAgentFileURL,
        userIdentifier: uid_t = getuid(),
        commandExecutor: HeadlessLaunchAgentCommandExecutor = .init()
    ) {
        self.agentExecutableURL =
            agentExecutableURL.standardizedFileURL
        self.configurationFileURL =
            configurationFileURL.standardizedFileURL
        self.launchAgentFileURL =
            launchAgentFileURL.standardizedFileURL
        self.userIdentifier = userIdentifier
        self.commandExecutor = commandExecutor
    }

    public static var defaultLaunchAgentFileURL: URL {
        let library = FileManager.default.urls(
            for: .libraryDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        return library
            .appendingPathComponent("LaunchAgents", isDirectory: true)
            .appendingPathComponent("\(label).plist")
    }

    public func propertyListData() throws -> Data {
        let intervals = [0, 6, 12, 18].map {
            ["Hour": $0, "Minute": 0]
        }
        let propertyList: [String: Any] = [
            "Label": Self.label,
            "ProgramArguments": [
                agentExecutableURL.path,
                "--config",
                configurationFileURL.path,
            ],
            "ProcessType": "Background",
            "RunAtLoad": true,
            "StartCalendarInterval": intervals,
        ]
        return try PropertyListSerialization.data(
            fromPropertyList: propertyList,
            format: .xml,
            options: 0
        )
    }

    public func status() throws -> HeadlessLaunchAgentStatus {
        let result = try commandExecutor(
            launchctlCommand(
                "print",
                serviceTarget
            )
        )
        if result.exitCode == 0 {
            return makeStatus(
                .enabled,
                configurationPath:
                    scheduledConfigurationPath()
            )
        }
        return makeStatus(
            FileManager.default.fileExists(
                atPath: launchAgentFileURL.path
            )
                ? .installedNotLoaded
                : .disabled,
            configurationPath:
                scheduledConfigurationPath()
        )
    }

    @discardableResult
    public func enable() throws -> HeadlessLaunchAgentStatus {
        guard FileManager.default.isExecutableFile(
            atPath: agentExecutableURL.path
        ) else {
            throw HeadlessLaunchAgentError.agentNotExecutable(
                agentExecutableURL.path
            )
        }
        guard FileManager.default.fileExists(
            atPath: configurationFileURL.path
        ) else {
            throw HeadlessLaunchAgentError.configurationMissing(
                configurationFileURL.path
            )
        }
        _ = try AgentConfiguration.load(from: configurationFileURL)

        let currentStatus = try status()
        if currentStatus.state == .enabled {
            let result = try commandExecutor(
                launchctlCommand("bootout", serviceTarget)
            )
            guard result.exitCode == 0 else {
                throw HeadlessLaunchAgentError.launchctlFailed(
                    action: "bootout",
                    message: launchctlMessage(from: result)
                )
            }
        }
        try FileManager.default.createDirectory(
            at: launchAgentFileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try propertyListData().write(
            to: launchAgentFileURL,
            options: .atomic
        )
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: launchAgentFileURL.path
        )

        let result = try commandExecutor(
            launchctlCommand(
                "bootstrap",
                userDomain,
                launchAgentFileURL.path
            )
        )
        guard result.exitCode == 0 else {
            throw HeadlessLaunchAgentError.launchctlFailed(
                action: "bootstrap",
                message: launchctlMessage(from: result)
            )
        }
        return makeStatus(
            .enabled,
            configurationPath: configurationFileURL.path
        )
    }

    @discardableResult
    public func disable() throws -> HeadlessLaunchAgentStatus {
        let currentStatus = try status()
        if currentStatus.state == .enabled {
            let result = try commandExecutor(
                launchctlCommand("bootout", serviceTarget)
            )
            guard result.exitCode == 0 else {
                throw HeadlessLaunchAgentError.launchctlFailed(
                    action: "bootout",
                    message: launchctlMessage(from: result)
                )
            }
        }
        if FileManager.default.fileExists(
            atPath: launchAgentFileURL.path
        ) {
            try FileManager.default.removeItem(
                at: launchAgentFileURL
            )
        }
        return makeStatus(.disabled)
    }

    private var userDomain: String {
        "gui/\(userIdentifier)"
    }

    private var serviceTarget: String {
        "\(userDomain)/\(Self.label)"
    }

    private func launchctlCommand(
        _ arguments: String...
    ) -> RenewalCommand {
        RenewalCommand(
            executableURL: URL(fileURLWithPath: "/bin/launchctl"),
            arguments: arguments
        )
    }

    private func launchctlMessage(from result: ProcessResult) -> String {
        let standardError = result.standardError
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !standardError.isEmpty {
            return standardError
        }
        let standardOutput = result.standardOutput
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !standardOutput.isEmpty {
            return standardOutput
        }
        return "exit code \(result.exitCode)"
    }

    private func makeStatus(
        _ state: HeadlessLaunchAgentState,
        configurationPath: String? = nil
    ) -> HeadlessLaunchAgentStatus {
        HeadlessLaunchAgentStatus(
            label: Self.label,
            state: state,
            plistPath: launchAgentFileURL.path,
            configurationPath: configurationPath
        )
    }

    private func scheduledConfigurationPath() -> String? {
        guard let data = try? Data(contentsOf: launchAgentFileURL),
              let propertyList = try? PropertyListSerialization
                .propertyList(
                    from: data,
                    options: [],
                    format: nil
                ) as? [String: Any],
              let arguments =
                propertyList["ProgramArguments"] as? [String],
              let optionIndex = arguments.firstIndex(of: "--config"),
              arguments.indices.contains(optionIndex + 1)
        else {
            return nil
        }
        return URL(
            fileURLWithPath: arguments[optionIndex + 1]
        ).standardizedFileURL.path
    }
}
