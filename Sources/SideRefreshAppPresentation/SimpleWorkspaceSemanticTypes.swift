public enum SimpleWorkspaceRegion:
    String,
    CaseIterable,
    Equatable,
    Hashable,
    Sendable
{
    case brand = "simple.brand"
    case navigation = "simple.navigation"
    case currentApp = "simple.current-app"
    case condition = "simple.condition"
    case nextAction = "simple.next-action"
    case relationship = "simple.relationship"
    case timing = "simple.timing"
    case evidence = "simple.last-verified"
    case progress = "simple.progress"
    case recentResult = "simple.recent-result"
}

public enum SimpleWorkspaceControl:
    String,
    CaseIterable,
    Equatable,
    Hashable,
    Sendable
{
    case nextAction = "simple.control.next-action"
    case selectApp = "simple.relationship.select-app"
    case selectIPhone = "simple.relationship.select-iphone"
    case automationSettings = "simple.automation.background-settings"
    case connectionSettings = "simple.automation.connection-settings"
    case manualRenewal = "simple.secondary.manual-renewal"
    case settings = "simple.destination.settings"
    case help = "simple.destination.help"
    case diagnostics = "simple.destination.diagnostics"
}

public enum SimpleWorkspaceAccessibility {
    public static let workspace = "simple.workspace"
    public static let sidebarHome = "simple.navigation.home"
    public static let fixtureRoute = "simple.fixture.route"
}
