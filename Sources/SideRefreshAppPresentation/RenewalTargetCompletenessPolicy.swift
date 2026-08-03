public enum RenewalTargetCompletenessPolicy {
    public static func isComplete(
        configurationIsDirty: Bool,
        draftIsComplete: Bool,
        savedIsComplete: Bool
    ) -> Bool {
        configurationIsDirty
            ? draftIsComplete
            : savedIsComplete
    }
}
