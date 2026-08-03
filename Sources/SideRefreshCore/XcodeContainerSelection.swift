import Foundation

public struct XcodeContainerSelection: Equatable, Sendable {
    public let containerPath: String
    public let scheme: String
    public let displayName: String
    public let productName: String
    public let bundleIdentifier: String
    public let developmentTeam: String
    public let marketingVersion: String
    public let buildVersion: String

    public init(candidate: XcodeContainerCandidate) {
        let application = candidate.unambiguousApplication
        containerPath = candidate.id
        scheme = application?.unambiguousSchemeName ?? ""
        displayName = application?.displayName ?? ""
        productName = application?.productName ?? ""
        bundleIdentifier = application?.bundleIdentifier ?? ""
        developmentTeam = application?.developmentTeam ?? ""
        marketingVersion = application?.marketingVersion ?? ""
        buildVersion = application?.buildVersion ?? ""
    }
}
