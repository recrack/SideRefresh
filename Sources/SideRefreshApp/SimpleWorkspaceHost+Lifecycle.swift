import SideRefreshAppPresentation

extension SideRefreshSimpleWorkspaceHost {
    func nextActionIsEnabled(
        _ presentation: RenewalPresentation
    ) -> Bool {
        let route = AppPresentationCoordinator.route(
            for: presentation
        )
        guard !model.isWorking, route != nil else {
            return false
        }
        if route == .confirmation(.installNow) {
            return model.canRenewImmediately
        }
        return true
    }

    func presentSettingsSaveConfirmationIfNeeded() {
        let generation = model.settingsSaveConfirmationGeneration
        guard generation > handledSettingsSaveGeneration else {
            return
        }
        handledSettingsSaveGeneration = generation
        confirmsSettingsSaved = true
    }

    func refreshSelectedIPhoneIdentityIfNeeded() {
        let identifier = model.target.deviceIdentifier
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard model.hasGuidedTarget,
              !identifier.isEmpty,
              !identifier.hasPrefix("REPLACE_"),
              !model.coreDeviceDiscoveryHasCompleted
        else {
            return
        }
        model.discoverCoreDevices()
    }
}
