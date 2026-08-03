import SideRefreshAppPresentation
import SwiftUI

struct SimpleSettingsHost: View {
    @ObservedObject var model: SideRefreshViewModel
    let launchRequest: SimpleSettingsLaunchRequest
    let session: SimpleSettingsSession
    let onSuccessfulSave: () -> Void
    let onSelectionCancelled: () -> Void
    let onOpenDestination: ((RenewalDestination) -> Void)?
    let isEmbedded: Bool

    init(
        model: SideRefreshViewModel,
        launchRequest: SimpleSettingsLaunchRequest,
        session: SimpleSettingsSession,
        onSuccessfulSave: @escaping () -> Void,
        onSelectionCancelled: @escaping () -> Void = {},
        onOpenDestination:
            ((RenewalDestination) -> Void)? = nil,
        isEmbedded: Bool = false
    ) {
        self.model = model
        self.launchRequest = launchRequest
        self.session = session
        self.onSuccessfulSave = onSuccessfulSave
        self.onSelectionCancelled = onSelectionCancelled
        self.onOpenDestination = onOpenDestination
        self.isEmbedded = isEmbedded
    }

    @State var page = SimpleSettingsPage.overview
    @State var confirmsSave = false
    @State var confirmsEnable = false
    @State var confirmsDisable = false
    @State var appSelectionOrigin = SimpleAppSelectionOrigin.settings
    @State var appSelectionPreparationTask: Task<Void, Never>?
    @State var appSelectionPreviousTarget: RenewalTargetDraft?
    @State var appSelectionConfigurationWasDirty = false
    @State private var handledLaunchGeneration = -1

    var body: some View {
        settingsPage
            .modifier(
                SimpleSettingsAlerts(
                    model: model,
                    confirmsSave: $confirmsSave,
                    confirmsEnable: $confirmsEnable,
                    confirmsDisable: $confirmsDisable,
                    didSave: {
                        completeSuccessfulSave()
                    },
                    didCancelSave: cancelPendingAppSelectionSave
                )
            )
            .onAppear(perform: handleLaunchRequest)
            .onChange(of: launchRequest) { _ in
                handleLaunchRequest()
            }
            .onDisappear {
                appSelectionPreparationTask?.cancel()
                appSelectionPreparationTask = nil
                restoreAppSelectionCheckpoint()
            }
    }

    private func handleLaunchRequest() {
        guard handledLaunchGeneration != launchRequest.generation else {
            return
        }
        handledLaunchGeneration = launchRequest.generation
        switch launchRequest.action {
        case .none:
            break
        case .chooseApp:
            chooseApp(
                origin: isEmbedded ? .workspace : .settings
            )
        case .chooseIPhone:
            findIPhone(
                origin: isEmbedded ? .workspace : .settings
            )
        case .editAutomation, .editConnection:
            page = .overview
        }
    }

}
