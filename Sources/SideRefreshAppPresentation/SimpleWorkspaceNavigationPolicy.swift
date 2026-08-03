public enum SimpleWorkspacePage:
    String,
    CaseIterable,
    Equatable,
    Hashable,
    Sendable
{
    case home
    case settings
    case help
    case diagnostics
}

public enum SimpleWorkspaceNavigationPolicy {
    public static func page(
        for destination: RenewalDestination
    ) -> SimpleWorkspacePage? {
        switch destination {
        case .settings, .setup:
            return .settings
        case .help:
            return .help
        case .diagnostics:
            return .diagnostics
        case .advancedSettings:
            return nil
        }
    }
}

#if DEBUG
/// Resolves presentation differences between interactive preview and capture.
public enum SimpleWorkspaceFixturePresentationPolicy {
    /// Keeps review-only identity out of deterministic output captures.
    public static func showsPreviewIdentity(
        previewRequested: Bool,
        capturesOutput: Bool
    ) -> Bool {
        previewRequested && !capturesOutput
    }
}

/// Transient page selection for a DEBUG workspace fixture.
public struct SimpleWorkspaceFixtureNavigation:
    Equatable,
    Sendable
{
    /// The fixture page currently rendered by the workspace.
    public private(set) var selectedPage: SimpleWorkspacePage
    /// Whether sidebar selections may change the rendered page.
    public let isInteractive: Bool

    /// Creates preview or deterministic-capture navigation state.
    public init(
        isInteractive: Bool,
        selectedPage: SimpleWorkspacePage = .home
    ) {
        self.isInteractive = isInteractive
        self.selectedPage = selectedPage
    }

    /// Applies a sidebar selection when the fixture is interactive.
    public mutating func select(_ page: SimpleWorkspacePage) {
        guard isInteractive else {
            return
        }
        selectedPage = page
    }
}
#endif
