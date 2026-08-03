import AppKit
import SideRefreshCore

@MainActor
enum TailscaleMacInstallation {
    static let downloadURL = URL(
        string: "https://tailscale.com/download/mac"
    )!

    private static let bundleIdentifiers = [
        "io.tailscale.ipn.macsys",
        "io.tailscale.ipn.macos",
    ]

    static var applicationURLs: [URL] {
        bundleIdentifiers.flatMap {
            NSWorkspace.shared.urlsForApplications(
                withBundleIdentifier: $0
            )
        }
    }

    static var isApplicationInstalled: Bool {
        !applicationURLs.isEmpty
    }

    static func executableCandidates(
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
        let candidates = [preferred].compactMap { $0 }
            + TailscaleExecutableLocator.standardCandidateURLs
        var seenPaths = Set<String>()
        return candidates.filter {
            seenPaths.insert($0.standardizedFileURL.path).inserted
        }
    }

    static func availableExecutableURLs(
        preferredPath: String?
    ) -> [URL] {
        TailscaleExecutableLocator(
            candidateURLs: executableCandidates(
                preferredPath: preferredPath
            )
        ).availableExecutableURLs()
    }
}
