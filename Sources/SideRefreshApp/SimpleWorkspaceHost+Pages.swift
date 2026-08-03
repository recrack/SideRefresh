import SwiftUI

extension SideRefreshSimpleWorkspaceHost {
    var settingsPage: some View {
        SimpleSettingsHost(
            model: model,
            launchRequest: settingsLaunchRequest,
            session: projectSelectionSession,
            onSuccessfulSave: completeSettingsSave,
            onSelectionCancelled: cancelWorkspaceAppSelection,
            onOpenDestination: openEmbeddedDestination,
            isEmbedded: true
        )
    }

    var helpPage: some View {
        SimpleWorkspaceHelpView(
            openSettings: { selectPage(.settings) },
            openDiagnostics: { selectPage(.diagnostics) }
        )
    }

    var diagnosticsPage: some View {
        RenewalLogView(model: model, isEmbedded: true)
    }

    func completeSettingsSave() {
        model.announceSettingsSaved()
        finishWorkspaceSelection()
    }

    func cancelWorkspaceAppSelection() {
        finishWorkspaceSelection()
    }

    private func finishWorkspaceSelection() {
        settingsLaunchRequest = SimpleSettingsLaunchRequest(
            action: .none,
            generation: settingsLaunchRequest.generation + 1
        )
        selectPage(.home)
    }
}
