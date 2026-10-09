import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// Locates a Tailscale command that SideRefresh can execute safely.
public struct TailscaleExecutableLocator: Sendable {
    /// Common executable locations used by the supported macOS variants.
    public static let standardCandidateURLs = [
        "/Applications/Tailscale.localized/Tailscale.app/Contents/MacOS/Tailscale",
        "/Applications/Tailscale.app/Contents/MacOS/Tailscale",
        "/opt/homebrew/bin/tailscale",
        "/usr/local/bin/tailscale",
    ].map { URL(fileURLWithPath: $0) }

    private static let bundleIdentifiers = [
        "io.tailscale.ipn.macsys",
        "io.tailscale.ipn.macos",
    ]

    /// Installed Tailscale apps registered with macOS, including custom locations.
    public static var installedApplicationURLs: [URL] {
        #if canImport(AppKit)
        bundleIdentifiers.flatMap {
            NSWorkspace.shared.urlsForApplications(withBundleIdentifier: $0)
        }.filter { FileManager.default.fileExists(atPath: $0.path) }
        #else
        []
        #endif
    }

    private let candidateURLs: [URL]

    /// Searches installed app bundles before common CLI locations.
    public init(
        candidateURLs: [URL] = Self.standardCandidateURLs,
        applicationURLs: [URL] = Self.installedApplicationURLs
    ) {
        let applicationExecutables = applicationURLs.compactMap { url -> URL? in
            guard let bundle = Bundle(url: url),
                  let identifier = bundle.bundleIdentifier,
                  Self.bundleIdentifiers.contains(identifier)
            else {
                return nil
            }
            return bundle.executableURL
        }
        self.candidateURLs = applicationExecutables + candidateURLs
    }

    /// Returns executable candidates without duplicate standardized paths.
    public func availableExecutableURLs(
        preferredExecutableURL: URL? = nil,
        fileManager: FileManager = .default
    ) -> [URL] {
        var seenPaths = Set<String>()
        let candidates = [preferredExecutableURL].compactMap { $0 } + candidateURLs
        return candidates.compactMap { candidate in
            let url = candidate.standardizedFileURL
            guard url.isFileURL,
                  url.path.hasPrefix("/"),
                  seenPaths.insert(url.path).inserted,
                  fileManager.isExecutableFile(atPath: url.path)
            else {
                return nil
            }
            return url
        }
    }

    /// Returns the first executable candidate, or `nil` when none is usable.
    public func firstAvailableExecutableURL(
        preferredExecutableURL: URL? = nil,
        fileManager: FileManager = .default
    ) -> URL? {
        availableExecutableURLs(
            preferredExecutableURL: preferredExecutableURL,
            fileManager: fileManager
        ).first
    }
}
