import SideRefreshAppPresentation

extension SimpleSettingsHost {
    func requestSave() {
        if model.saveRequiresActiveAgentConfirmation {
            confirmsSave = true
        } else {
            let saveSucceeded = model.saveConfiguration()
            if SimpleSettingsSavePresentationPolicy.action(
                saveSucceeded: saveSucceeded
            ) == .closeAndConfirm {
                completeSuccessfulSave()
            }
        }
    }

    func completeSuccessfulSave() {
        acceptAppSelectionCheckpoint()
        session.completeMigrationIfSaved(model: model)
        onSuccessfulSave()
    }

    func cancelPendingAppSelectionSave() {
        guard appSelectionOrigin == .workspace,
            appSelectionPreviousTarget != nil
        else {
            return
        }
        restoreAppSelectionCheckpoint()
        session.restoreCancelledMigrationIfNeeded(model: model)
        onSelectionCancelled()
    }

    func performAutomationAction(
        _ action: SimpleSettingsAutomationAction
    ) {
        switch action {
        case .disable:
            confirmsDisable = true
        case .openApproval:
            model.openLoginItemSettings()
        case .enable:
            confirmsEnable = true
        case .saveFirst:
            requestSave()
        case .viewDiagnostics:
            openDestination(.diagnostics)
        }
    }

    func openDestination(_ destination: RenewalDestination) {
        if let onOpenDestination {
            onOpenDestination(destination)
            return
        }
        switch destination {
        case .diagnostics:
            RenewalLogWindowPresenter.shared.show(model: model)
        case .advancedSettings:
            SettingsWindowPresenter.shared.show(
                model: model,
                destination: .advancedSettings
            )
        case .settings, .setup, .help:
            break
        }
    }
}
