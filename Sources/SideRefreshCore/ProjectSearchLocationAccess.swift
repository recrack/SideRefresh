import Foundation

public enum ProjectSearchLocationKind:
    String,
    Equatable,
    Sendable
{
    case home
    case desktop
    case documents
    case downloads
    case custom

    public var requiresExplicitSelection: Bool {
        switch self {
        case .desktop, .documents, .downloads:
            return true
        case .home, .custom:
            return false
        }
    }
}

public enum ProjectSearchAccessStatus:
    String,
    Equatable,
    Sendable
{
    case selectionRequired
    case verificationRequired
    case checking
    case allowed
    case partiallyBlocked
    case blocked
    case missing

    public var restoredAfterCancelledCheck:
        ProjectSearchAccessStatus
    {
        self == .checking ? .verificationRequired : self
    }
}

public enum ProjectSearchAccessProbe:
    Equatable,
    Sendable
{
    case accessible
    case permissionDenied
    case missing
    case failed
}

public struct ProjectSearchLocationAccess:
    Identifiable,
    Equatable,
    Sendable
{
    public let kind: ProjectSearchLocationKind
    public let url: URL
    public var status: ProjectSearchAccessStatus

    public var id: String {
        url.standardizedFileURL.path
    }

    public init(
        kind: ProjectSearchLocationKind,
        url: URL,
        status: ProjectSearchAccessStatus
    ) {
        self.kind = kind
        self.url = url.standardizedFileURL
        self.status = status
    }

    public static func standardLocations(
        homeDirectoryURL: URL,
        selectedLocationURLs: [URL],
        fileExists: (URL) -> Bool
    ) -> [ProjectSearchLocationAccess] {
        let home = homeDirectoryURL.standardizedFileURL
        let standardLocations = builtInLocations(
            homeDirectoryURL: home
        )
        let selectedURLs = selectedLocationURLs.map(
            \.standardizedFileURL
        )
        let selectedPaths = Set(selectedURLs.map(\.path))
        let standardPaths = Set(
            standardLocations.map { $0.1.standardizedFileURL.path }
        )
        var result = standardLocations.map { kind, url in
            let standardizedURL = url.standardizedFileURL
            let status: ProjectSearchAccessStatus
            let wasSelected =
                selectedPaths.contains(standardizedURL.path)
            if kind != .home && !wasSelected {
                status = .selectionRequired
            } else if fileExists(standardizedURL) {
                status = .checking
            } else {
                status = .missing
            }
            return ProjectSearchLocationAccess(
                kind: kind,
                url: standardizedURL,
                status: status
            )
        }
        let customURLs = Dictionary(
            uniqueKeysWithValues: selectedURLs.map {
                ($0.path, $0)
            }
        ).values
            .filter { !standardPaths.contains($0.path) }
            .sorted {
                $0.path.localizedCaseInsensitiveCompare($1.path)
                    == .orderedAscending
            }
        result.append(
            contentsOf: customURLs.map {
                ProjectSearchLocationAccess(
                    kind: .custom,
                    url: $0,
                    status: fileExists($0) ? .checking : .missing
                )
            }
        )
        return result
    }

    public static func protectedLocationURLs(
        homeDirectoryURL: URL
    ) -> [URL] {
        builtInLocations(
            homeDirectoryURL: homeDirectoryURL
        ).compactMap { kind, url in
            kind.requiresExplicitSelection ? url : nil
        }
    }

    public static func resolvedStatus(
        probe: ProjectSearchAccessProbe,
        rootURL: URL,
        unreadableLocationURLs: [URL]
    ) -> ProjectSearchAccessStatus {
        switch probe {
        case .accessible:
            let rootPath = rootURL.standardizedFileURL.path
            let unreadablePaths = unreadableLocationURLs.map {
                $0.standardizedFileURL.path
            }
            if unreadablePaths.contains(rootPath) {
                return .blocked
            }
            let containsUnreadableDescendant =
                unreadablePaths.contains {
                    $0.hasPrefix(rootPath + "/")
                }
            return containsUnreadableDescendant
                ? .partiallyBlocked
                : .allowed
        case .permissionDenied, .failed:
            return .blocked
        case .missing:
            return .missing
        }
    }

    public static func resolvedStatusAfterRootProbe(
        probe: ProjectSearchAccessProbe,
        previousStatus: ProjectSearchAccessStatus
    ) -> ProjectSearchAccessStatus {
        switch probe {
        case .accessible:
            return previousStatus == .partiallyBlocked
                ? .partiallyBlocked
                : .allowed
        case .permissionDenied, .failed:
            return .blocked
        case .missing:
            return .missing
        }
    }

    private static func builtInLocations(
        homeDirectoryURL: URL
    ) -> [(ProjectSearchLocationKind, URL)] {
        let home = homeDirectoryURL.standardizedFileURL
        return [
            (.home, home),
            (
                .desktop,
                home.appendingPathComponent(
                    "Desktop",
                    isDirectory: true
                )
            ),
            (
                .documents,
                home.appendingPathComponent(
                    "Documents",
                    isDirectory: true
                )
            ),
            (
                .downloads,
                home.appendingPathComponent(
                    "Downloads",
                    isDirectory: true
                )
            ),
        ]
    }
}
