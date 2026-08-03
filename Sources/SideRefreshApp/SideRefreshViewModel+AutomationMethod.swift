import SideRefreshAppPresentation
import SideRefreshCore

extension SideRefreshViewModel {
    var automaticRenewalMethodSummary: RenewalAutomationMethod.Presentation {
        RenewalAutomationMethod.presentation(
            background: backgroundAutomationPresentationState,
            savedConfiguration: savedRenewalMode.map {
                RenewalAutomationMethod.Configuration(
                    execution: executionMethod(for: $0),
                    connection: connectionMethod(
                        for: savedConnectionRoute ?? .automatic
                    )
                )
            },
            draftConfiguration: RenewalAutomationMethod.Configuration(
                execution: executionMethod(for: renewalMode),
                connection: connectionMethod(for: connectionRoute)
            ),
            draftIsDirty: configurationIsDirty
        )
    }

    private func executionMethod(
        for mode: IOSAppRenewalMode
    ) -> RenewalAutomationMethod.Execution {
        mode == .execute ? .buildSignAndInstall : .validationOnly
    }

    private func connectionMethod(
        for route: DeviceConnectionRoute
    ) -> RenewalAutomationMethod.Connection {
        switch route {
        case .automatic:
            return .xcodeAutomatic
        case .tailnet:
            return .tailnet
        case .custom:
            return .directAddress
        }
    }
}
