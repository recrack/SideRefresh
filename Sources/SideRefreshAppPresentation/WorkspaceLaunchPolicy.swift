/// A top-level workspace that SideRefresh can present.
public enum AppWorkspace: Equatable, Sendable {
    /// The primary status and action workspace.
    case simple

    /// The temporary compatibility workspace.
    case legacy
}

/// Defines the workspace selected for a normal application launch.
public enum WorkspaceLaunchPolicy {
    /// The workspace opened after a normal launch.
    public static let normalLaunchWorkspace = AppWorkspace.simple

    /// The workspace opened from the menu-bar primary action.
    public static let menuBarWorkspace = normalLaunchWorkspace
}
