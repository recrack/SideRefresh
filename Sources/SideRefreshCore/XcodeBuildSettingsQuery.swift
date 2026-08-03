import Foundation

public struct XcodeBuildSettingsQuery: Equatable, Sendable {
    public let containerURL: URL
    public let scheme: String
    public let configuration: String
    public let bundleIdentifier: String
    public let derivedDataURL: URL

    public init(
        containerURL: URL,
        scheme: String,
        configuration: String,
        bundleIdentifier: String,
        derivedDataURL: URL
    ) {
        self.containerURL = containerURL
        self.scheme = scheme
        self.configuration = configuration
        self.bundleIdentifier = bundleIdentifier
        self.derivedDataURL = derivedDataURL
    }
}
