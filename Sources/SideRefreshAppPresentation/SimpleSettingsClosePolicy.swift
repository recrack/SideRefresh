public enum SimpleSettingsCloseAction: Equatable, Sendable {
    case keepDraft
    case restoreSavedConfiguration
}

public enum SimpleSettingsClosePolicy {
    public static func action(
        beganCompatibilityMigration: Bool,
        configurationIsDirty: Bool
    ) -> SimpleSettingsCloseAction {
        beganCompatibilityMigration && configurationIsDirty
            ? .restoreSavedConfiguration
            : .keepDraft
    }
}

public struct SimpleSettingsMigrationLifecycle: Equatable, Sendable {
    public private(set) var beganCompatibilityMigration = false

    public init() {}

    public mutating func begin() {
        beganCompatibilityMigration = true
    }

    public mutating func completeIfSaved(
        hasGuidedTarget: Bool,
        configurationIsDirty: Bool
    ) {
        if hasGuidedTarget && !configurationIsDirty {
            beganCompatibilityMigration = false
        }
    }

    public func closeAction(
        configurationIsDirty: Bool
    ) -> SimpleSettingsCloseAction {
        SimpleSettingsClosePolicy.action(
            beganCompatibilityMigration:
                beganCompatibilityMigration,
            configurationIsDirty: configurationIsDirty
        )
    }

    public mutating func takeCloseAction(
        configurationIsDirty: Bool
    ) -> SimpleSettingsCloseAction {
        let action = closeAction(
            configurationIsDirty: configurationIsDirty
        )
        if action == .restoreSavedConfiguration {
            reset()
        }
        return action
    }

    public mutating func reset() {
        beganCompatibilityMigration = false
    }
}
