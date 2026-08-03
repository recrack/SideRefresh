import SideRefreshAppPresentation

@MainActor
final class SimpleSettingsSession {
    private var lifecycle = SimpleSettingsMigrationLifecycle()
    private var settingsIsPresented = false

    func beginCompatibilityMigration() {
        lifecycle.begin()
    }

    func completeMigrationIfSaved(model: SideRefreshViewModel) {
        lifecycle.completeIfSaved(
            hasGuidedTarget: model.hasGuidedTarget,
            configurationIsDirty: model.configurationIsDirty
        )
    }

    func restoreCancelledMigrationIfNeeded(
        model: SideRefreshViewModel
    ) {
        guard lifecycle.beganCompatibilityMigration,
              model.target.containerPath.isEmpty
        else {
            return
        }
        model.cancelGuidedTargetMigration()
        lifecycle.reset()
    }

    func settingsDidOpen() {
        settingsIsPresented = true
    }

    func restoreOnSettingsCloseIfNeeded(model: SideRefreshViewModel) {
        settingsIsPresented = false
        restoreOnCloseIfNeeded(model: model)
    }

    func restoreOnHomeCloseIfNeeded(model: SideRefreshViewModel) {
        guard !settingsIsPresented else {
            return
        }
        restoreOnCloseIfNeeded(model: model)
    }

    private func restoreOnCloseIfNeeded(model: SideRefreshViewModel) {
        let action = lifecycle.takeCloseAction(
            configurationIsDirty: model.configurationIsDirty
        )
        if action == .restoreSavedConfiguration {
            model.cancelGuidedTargetMigration()
        }
    }
}
