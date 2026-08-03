import Foundation

public enum SideRefreshPaths {
    public static let applicationSupportFolderName = "SideRefresh"

    public static var applicationSupportDirectory: URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent(
            applicationSupportFolderName,
            isDirectory: true
        )
    }

    public static var defaultConfigurationFile: URL {
        applicationSupportDirectory.appendingPathComponent("agent-config.json")
    }

    public static var defaultStateFile: URL {
        applicationSupportDirectory.appendingPathComponent("renewal-state.json")
    }
}
