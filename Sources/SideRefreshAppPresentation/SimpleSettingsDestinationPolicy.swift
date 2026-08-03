public enum SimpleSettingsDestinationSurface: Equatable, Sendable {
    case simpleSettings
    case legacySettings
    case diagnostics
}

public enum SimpleSettingsDestinationPolicy {
    public static func surface(
        for destination: RenewalDestination
    ) -> SimpleSettingsDestinationSurface {
        switch destination {
        case .settings, .setup:
            return .simpleSettings
        case .advancedSettings, .help:
            return .legacySettings
        case .diagnostics:
            return .diagnostics
        }
    }
}
