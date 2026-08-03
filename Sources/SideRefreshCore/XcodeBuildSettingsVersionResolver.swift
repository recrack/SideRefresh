import Foundation

public actor XcodeBuildSettingsVersionResolver {
    private let reader: XcodeBuildSettingsReader

    public init(
        reader: XcodeBuildSettingsReader = XcodeBuildSettingsReader()
    ) {
        self.reader = reader
    }

    public func resolve(
        query: XcodeBuildSettingsQuery,
        buildSettingOverrides: [String] = [],
        xcrunURL: URL = URL(fileURLWithPath: "/usr/bin/xcrun")
    ) throws -> IOSAppVersion {
        try Task.checkCancellation()
        return try reader.read(
            query: query,
            buildSettingOverrides: buildSettingOverrides,
            xcrunURL: xcrunURL
        )
    }
}
