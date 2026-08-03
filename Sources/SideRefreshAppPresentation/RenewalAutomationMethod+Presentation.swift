extension RenewalAutomationMethod {
    public enum Provenance: Equatable, Sendable {
        case saved
        case savedWithPendingDraft
        case draftOnly
    }

    public struct Presentation: Equatable, Sendable {
        public let background: BackgroundAutomationState
        public let configuration: Configuration
        public let provenance: Provenance

        public init(
            background: BackgroundAutomationState,
            configuration: Configuration,
            provenance: Provenance
        ) {
            self.background = background
            self.configuration = configuration
            self.provenance = provenance
        }
    }

    public static func presentation(
        background: BackgroundAutomationState,
        savedConfiguration: Configuration?,
        draftConfiguration: Configuration,
        draftIsDirty: Bool
    ) -> Presentation {
        guard let savedConfiguration else {
            return Presentation(
                background: background,
                configuration: draftConfiguration,
                provenance: .draftOnly
            )
        }

        return Presentation(
            background: background,
            configuration: savedConfiguration,
            provenance: draftIsDirty ? .savedWithPendingDraft : .saved
        )
    }
}
