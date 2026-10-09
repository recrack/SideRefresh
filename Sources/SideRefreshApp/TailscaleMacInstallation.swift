import AppKit
import SideRefreshCore

@MainActor
enum TailscaleMacInstallation {
    static let downloadURL = URL(
        string: "https://tailscale.com/download/mac"
    )!

    static var applicationURLs: [URL] {
        TailscaleExecutableLocator.installedApplicationURLs
    }

    static var isApplicationInstalled: Bool {
        !applicationURLs.isEmpty
    }

    static func availableExecutableURLs(
        preferredPath: String?
    ) -> [URL] {
        let preferred = preferredPath.flatMap { path -> URL? in
            let trimmed = path.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            guard trimmed.hasPrefix("/") else {
                return nil
            }
            return URL(fileURLWithPath: trimmed)
        }
        return TailscaleExecutableLocator().availableExecutableURLs(
            preferredExecutableURL: preferred
        )
    }
}
