import SideRefreshAppPresentation

extension SideRefreshSimpleWorkspaceHost {
    func perform(
        _ route: AppPresentationRoute,
        from control: SimpleWorkspaceControl
    ) {
        SideRefreshAppRouteExecutor.perform(
            route,
            model: model,
            handlers: SideRefreshAppRouteHandlers(
                confirmSave: { confirmsSave = true },
                confirmAutomaticRenewal: {
                    confirmsAutomaticRenewal = true
                },
                confirmInstall: { confirmsInstall = true },
                openDestination: {
                    openDestination($0, returningTo: control)
                }
            )
        )
    }

    private func openDestination(
        _ destination: RenewalDestination,
        returningTo control: SimpleWorkspaceControl
    ) {
        if let page = SimpleWorkspaceNavigationPolicy.page(
            for: destination
        ) {
            if page == .settings {
                requestSettingsPage(
                    launchAction(
                        for: destination,
                        control: control
                    )
                )
            } else {
                selectPage(page)
            }
            return
        }

        let restore = { restoreFocus(to: control) }
        switch SimpleSettingsDestinationPolicy.surface(
            for: destination
        ) {
        case .diagnostics:
            RenewalLogWindowPresenter.shared.show(
                model: model,
                onClose: restore
            )
        case .simpleSettings:
            SimpleSettingsWindowPresenter.shared.show(
                model: model,
                launchAction: launchAction(
                    for: destination,
                    control: control
                ),
                session: projectSelectionSession,
                onSave: {
                    SimpleWorkspaceWindowPresenter.shared.show(
                        model: model
                    )
                    model.announceSettingsSaved()
                },
                onClose: restore
            )
        case .legacySettings:
            SettingsWindowPresenter.shared.show(
                model: model,
                destination: destination,
                onClose: restore
            )
        }
    }

    func selectPage(_ page: SimpleWorkspacePage) {
        if selectedPage == .settings, page != .settings {
            projectSelectionSession.restoreOnSettingsCloseIfNeeded(
                model: model
            )
        }
        if page == .settings, selectedPage != .settings {
            projectSelectionSession.settingsDidOpen()
        }
        selectedPage = page
    }

    func openEmbeddedDestination(
        _ destination: RenewalDestination
    ) {
        if let page = SimpleWorkspaceNavigationPolicy.page(
            for: destination
        ) {
            selectPage(page)
            return
        }
        SettingsWindowPresenter.shared.show(
            model: model,
            destination: destination
        )
    }

    private func requestSettingsPage(
        _ action: SimpleSettingsLaunchAction
    ) {
        settingsLaunchRequest = SimpleSettingsLaunchRequest(
            action: action,
            generation: settingsLaunchRequest.generation + 1
        )
        selectPage(.settings)
    }

    func restoreFocus(
        to control: SimpleWorkspaceControl
    ) {
        focusRequest = SimpleWorkspaceFocusRequest(
            control: control,
            generation: focusRequest.generation + 1
        )
    }
}
