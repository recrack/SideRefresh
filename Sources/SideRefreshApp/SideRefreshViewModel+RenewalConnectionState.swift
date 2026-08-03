import SideRefreshAppPresentation

extension SideRefreshViewModel {
    var renewalPresentationConnection: RenewalConnectionState {
        let evidence: RenewalConnectionEvidence
        switch connectionRoute {
        case .automatic:
            evidence = .routeAvailable
        case .tailnet:
            switch selectedTailnetDevice?.isOnline {
            case .some(true):
                evidence = .routeAvailable
            case .some(false):
                evidence = .verifiedUnreachable
            case .none:
                evidence = .absent
            }
        case .custom:
            evidence = currentConnectionAddress == nil
                ? .absent
                : .routeAvailable
        }
        return RenewalConnectionResolver.resolve(
            isChecking:
                isDiscoveringCoreDevices || isDiscoveringTailnet,
            evidence: evidence
        )
    }
}
