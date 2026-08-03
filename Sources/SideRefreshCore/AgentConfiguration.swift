import Foundation

public enum AgentConfigurationError: LocalizedError, Equatable {
    case invalidStateFile
    case invalidExecutable
    case invalidTailnetExecutable

    public var errorDescription: String? {
        switch self {
        case .invalidStateFile:
            return "The renewal state file must be an absolute path."
        case .invalidExecutable:
            return "The renewal executable must be an absolute path."
        case .invalidTailnetExecutable:
            return "The Tailscale executable must be an absolute path."
        }
    }
}

public struct AgentConfiguration: Codable, Equatable, Sendable {
    public let stateFile: String
    public let renewalInterval: RenewalInterval
    public let tailnetTarget: TailnetTarget?
    public let command: RenewalCommand

    private enum CodingKeys: String, CodingKey {
        case stateFile = "state_file"
        case renewalInterval = "renew_every_hours"
        case tailnetTarget = "tailnet_target"
        case command
    }

    public init(
        stateFileURL: URL,
        renewalInterval: RenewalInterval = .personalTeamDefault,
        tailnetTarget: TailnetTarget? = nil,
        command: RenewalCommand
    ) {
        stateFile = stateFileURL.standardizedFileURL.path
        self.renewalInterval = renewalInterval
        self.tailnetTarget = tailnetTarget
        self.command = command
    }

    public var stateFileURL: URL {
        URL(fileURLWithPath: stateFile)
    }

    public var renewEveryHours: Int {
        renewalInterval.hours
    }

    public static func load(from fileURL: URL) throws -> AgentConfiguration {
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        let configuration = try decoder.decode(AgentConfiguration.self, from: data)
        try configuration.validate()
        return configuration
    }

    public func write(to fileURL: URL) throws {
        try validate()
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: fileURL, options: .atomic)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: fileURL.path
        )
    }

    private func validate() throws {
        guard stateFile.hasPrefix("/") else {
            throw AgentConfigurationError.invalidStateFile
        }
        guard command.executable.hasPrefix("/") else {
            throw AgentConfigurationError.invalidExecutable
        }
        if let tailnetTarget,
           !tailnetTarget.tailscaleExecutable.hasPrefix("/")
        {
            throw AgentConfigurationError.invalidTailnetExecutable
        }
    }
}
