import Darwin
import Foundation
import SideRefreshCore

func configurationURL(from arguments: [String]) throws -> URL {
    if let optionIndex = arguments.firstIndex(of: "--config") {
        guard arguments.indices.contains(optionIndex + 1) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return URL(fileURLWithPath: arguments[optionIndex + 1])
    }
    return SideRefreshPaths.defaultConfigurationFile
}

do {
    let configuration = try AgentConfiguration.load(
        from: configurationURL(
            from: Array(CommandLine.arguments.dropFirst())
        )
    )
    let result = try ConfiguredRenewalRunner().runIfDue(configuration)
    try? SideRefreshJSONOutput.write(result)
    exit(result.processResult?.exitCode ?? 0)
} catch {
    SideRefreshJSONOutput.writeError(
        "SideRefresh Agent: \(error.localizedDescription)\n"
    )
    exit(2)
}
