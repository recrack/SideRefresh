public struct SimpleWorkspaceSemanticModel: Equatable, Sendable {
    public let orderedRegions: [SimpleWorkspaceRegion]
    public let focusOrder: [SimpleWorkspaceControl]
    public let nextActionRoute: AppPresentationRoute?
    public let manualRenewalRoute: AppPresentationRoute?

    public init(_ presentation: RenewalPresentation) {
        var regions: [SimpleWorkspaceRegion] = [.condition]
        if presentation.nextAction != nil {
            regions.append(.nextAction)
        }
        regions.append(contentsOf: [
            .relationship,
            .timing,
            .evidence,
        ])
        if presentation.progress != nil {
            regions.append(.progress)
        } else if presentation.recentResult != nil {
            regions.append(.recentResult)
        }
        orderedRegions = regions

        let route = AppPresentationCoordinator.route(
            for: presentation
        )
        nextActionRoute = route
        manualRenewalRoute = presentation.condition == .healthy
            ? .confirmation(.installNow)
            : nil

        let destinations = presentation.availableDestinations
        var controls: [SimpleWorkspaceControl] = []
        if route != nil {
            controls.append(.nextAction)
        }
        if destinations.contains(.setup) {
            controls.append(contentsOf: [.selectApp, .selectIPhone])
        }
        if destinations.contains(.settings) {
            controls.append(contentsOf: [
                .automationSettings,
                .connectionSettings,
            ])
        }
        if manualRenewalRoute != nil {
            controls.append(.manualRenewal)
        }
        if destinations.contains(.settings) {
            controls.append(.settings)
        }
        if destinations.contains(.help) {
            controls.append(.help)
        }
        if destinations.contains(.diagnostics) {
            controls.append(.diagnostics)
        }
        focusOrder = controls
    }
}
