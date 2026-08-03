import Foundation

public enum SimpleAppSelectionOrigin: Equatable, Sendable {
    case workspace
    case settings
}

public enum SimpleAppSelectionResult: Equatable, Sendable {
    case confirmed
    case cancelled
}

public enum SimpleAppSelectionCompletionAction:
    Equatable,
    Sendable
{
    case prepareThenSaveAndReturnHome
    case restoreAndReturnHome
    case acceptAndReturnToSettings
    case restoreAndReturnToSettings
}

public enum SimpleAppSelectionCompletionPolicy {
    public static func action(
        origin: SimpleAppSelectionOrigin,
        result: SimpleAppSelectionResult
    ) -> SimpleAppSelectionCompletionAction {
        switch (origin, result) {
        case (.workspace, .confirmed):
            return .prepareThenSaveAndReturnHome
        case (.workspace, .cancelled):
            return .restoreAndReturnHome
        case (.settings, .confirmed):
            return .acceptAndReturnToSettings
        case (.settings, .cancelled):
            return .restoreAndReturnToSettings
        }
    }
}

public enum SimpleAppSelectionTeamPolicy {
    public static func resolve(
        detected: String,
        current: String,
        remembered: String
    ) -> String {
        for value in [detected, current, remembered] {
            let normalized = value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            if isValid(normalized) {
                return normalized
            }
        }
        return ""
    }

    private static func isValid(_ value: String) -> Bool {
        value.count == 10
            && value.rangeOfCharacter(
                from: CharacterSet.alphanumerics.inverted
            ) == nil
    }
}
