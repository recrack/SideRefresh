import SideRefreshAppPresentation

extension SimpleSettingsHost {
    func chooseApp() {
        chooseApp(origin: .settings)
    }

    func chooseApp(origin: SimpleAppSelectionOrigin) {
        beginAppSelectionCheckpoint()
        let beginsMigration =
            model.isConfigured && !model.hasGuidedTarget
        guard
            model.hasGuidedTarget
                || model.useGuidedTargetEditor()
        else {
            acceptAppSelectionCheckpoint()
            return
        }
        if beginsMigration {
            session.beginCompatibilityMigration()
        }
        appSelectionOrigin = origin
        page = SimpleSettingsPagePolicy.page(for: .selectApp)
    }

    func findIPhone() {
        findIPhone(origin: .settings)
    }

    func findIPhone(origin: SimpleAppSelectionOrigin) {
        guard model.hasGuidedTarget else {
            chooseApp(origin: origin)
            return
        }
        page = SimpleSettingsPagePolicy.page(for: .selectIPhone)
    }

    func completeAppSelection(
        _ result: SimpleAppSelectionResult
    ) {
        switch SimpleAppSelectionCompletionPolicy.action(
            origin: appSelectionOrigin,
            result: result
        ) {
        case .prepareThenSaveAndReturnHome:
            prepareAndSaveAppSelection()
        case .restoreAndReturnHome:
            restoreAppSelectionCheckpoint()
            session.restoreCancelledMigrationIfNeeded(model: model)
            onSelectionCancelled()
        case .acceptAndReturnToSettings:
            acceptAppSelectionCheckpoint()
            closeSelection()
        case .restoreAndReturnToSettings:
            restoreAppSelectionCheckpoint()
            session.restoreCancelledMigrationIfNeeded(model: model)
            closeSelection()
        }
    }

    func beginAppSelectionCheckpoint() {
        appSelectionPreviousTarget = model.target
        appSelectionConfigurationWasDirty = model.configurationIsDirty
    }

    func acceptAppSelectionCheckpoint() {
        appSelectionPreviousTarget = nil
        appSelectionConfigurationWasDirty = false
    }

    func restoreAppSelectionCheckpoint() {
        appSelectionPreparationTask?.cancel()
        appSelectionPreparationTask = nil
        guard let previousTarget = appSelectionPreviousTarget else {
            return
        }
        model.restoreTargetAfterCancelledAppSelection(
            previousTarget,
            configurationWasDirty: appSelectionConfigurationWasDirty
        )
        acceptAppSelectionCheckpoint()
    }

    private func prepareAndSaveAppSelection() {
        appSelectionPreparationTask?.cancel()
        appSelectionPreparationTask = Task { @MainActor in
            await model.waitForConfiguredXcodeContainerLoad()
            guard !Task.isCancelled else {
                return
            }
            appSelectionPreparationTask = nil
            requestSave()
        }
    }
}
