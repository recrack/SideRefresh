import Foundation

/// Locates a Tailscale command that SideRefresh can execute safely.
public struct TailscaleExecutableLocator: Sendable {
    /// Common executable locations used by the supported macOS variants.
    public static let standardCandidateURLs = [
        "/Applications/Tailscale.localized/Tailscale.app/Contents/MacOS/Tailscale",
        "/Applications/Tailscale.app/Contents/MacOS/Tailscale",
        "/opt/homebrew/bin/tailscale",
        "/usr/local/bin/tailscale",
    ].map { URL(fileURLWithPath: $0) }

    private let candidateURLs: [URL]

    /// Creates a locator with candidates ordered by preference.
    public init(
        candidateURLs: [URL] = Self.standardCandidateURLs
    ) {
        self.candidateURLs = candidateURLs
    }

    /// Returns executable candidates without duplicate standardized paths.
    public func availableExecutableURLs(
        fileManager: FileManager = .default
    ) -> [URL] {
        var seenPaths = Set<String>()
        return candidateURLs.compactMap { candidate in
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
        fileManager: FileManager = .default
    ) -> URL? {
        availableExecutableURLs(fileManager: fileManager).first
    }
}
