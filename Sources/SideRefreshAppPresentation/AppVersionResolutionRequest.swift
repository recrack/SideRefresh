import Foundation
import SideRefreshCore

public struct AppVersionResolutionRequest: Equatable, Sendable {
    public let query: XcodeBuildSettingsQuery
    public let buildSettingOverrides: [String]

    public init?(
        containerURL: URL,
        scheme: String,
        configuration: String,
        bundleIdentifier: String,
        derivedDataURL: URL,
        developmentTeam: String
    ) {
        let scheme = Self.normalized(scheme)
        let configuration = Self.normalized(configuration)
        let bundleIdentifier = Self.normalized(bundleIdentifier)
        let developmentTeam = Self.normalized(developmentTeam)
        guard let scheme,
              let configuration,
              let bundleIdentifier
        else {
            return nil
        }
        query = XcodeBuildSettingsQuery(
            containerURL: containerURL.standardizedFileURL,
            scheme: scheme,
            configuration: configuration,
            bundleIdentifier: bundleIdentifier,
            derivedDataURL: derivedDataURL.standardizedFileURL
        )
        buildSettingOverrides = developmentTeam.map {
            ["DEVELOPMENT_TEAM=\($0)"]
        } ?? []
    }

    private static func normalized(_ value: String) -> String? {
        let value = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return value.isEmpty ? nil : value
    }
}
