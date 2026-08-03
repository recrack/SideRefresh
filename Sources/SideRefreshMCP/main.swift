import Darwin
import Foundation
import SideRefreshCore
import SideRefreshMCPServer

let commandName = "siderefresh-mcp"

func defaultConfigurationURL(
    from arguments: [String]
) throws -> URL {
    guard !arguments.isEmpty else {
        return SideRefreshPaths.defaultConfigurationFile
    }
    guard arguments.count == 2,
          arguments[0] == "--config",
          arguments[1].hasPrefix("/")
    else {
        throw MCPMainError.usage
    }
    return URL(fileURLWithPath: arguments[1]).standardizedFileURL
}

enum MCPMainError: LocalizedError {
    case usage

    var errorDescription: String? {
        "usage: \(commandName) [--config /absolute/path/agent-config.json]"
    }
}

do {
    let executableURL = URL(
        fileURLWithPath: CommandLine.arguments[0]
    ).standardizedFileURL
    let binaryDirectory = executableURL.deletingLastPathComponent()
    let handler = SideRefreshMCPToolHandler(
        defaultConfigurationFileURL: try defaultConfigurationURL(
            from: Array(CommandLine.arguments.dropFirst())
        ),
        helperExecutableURL: binaryDirectory.appendingPathComponent(
            "SideRefreshIOSRenewal"
        ),
        agentExecutableURL: binaryDirectory.appendingPathComponent(
            "SideRefreshAgent"
        )
    )
    try SideRefreshMCPStdioServer(
        router: SideRefreshMCPProtocolRouter(toolHandler: handler)
    ).run()
} catch {
    FileHandle.standardError.write(
        Data(
            "\(commandName): \(error.localizedDescription)\n".utf8
        )
    )
    exit(2)
}
