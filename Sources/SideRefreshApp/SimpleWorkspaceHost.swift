import SideRefreshAppPresentation
import SwiftUI

struct SideRefreshSimpleWorkspaceHost: View {
    @ObservedObject var model: SideRefreshViewModel
    @State var confirmsSave = false
    @State var confirmsAutomaticRenewal = false
    @State var confirmsInstall = false
    @State var focusRequest = SimpleWorkspaceFocusRequest.initial
    @State var projectSelectionSession = SimpleSettingsSession()
    @State var confirmsSettingsSaved = false
    @State var handledSettingsSaveGeneration: Int
    @State var selectedPage = SimpleWorkspacePage.home
    @State var settingsLaunchRequest = SimpleSettingsLaunchRequest(
        action: .none,
        generation: 0
    )

    init(model: SideRefreshViewModel) {
        self.model = model
        _handledSettingsSaveGeneration = State(
            initialValue: model.settingsSaveConfirmationGeneration
        )
    }

    var body: some View {
        let presentation = model.renewalPresentation
        SimpleWorkspaceView(
            presentation: presentation,
            nextActionIsEnabled: nextActionIsEnabled(presentation),
            manualRenewalIsEnabled:
                !model.isWorking && model.canRenewImmediately,
            automaticRenewalMethod:
                model.automaticRenewalMethodSummary,
            focusRequest: focusRequest,
            selectedPage: selectedPage,
            settingsPage: AnyView(settingsPage),
            helpPage: AnyView(helpPage),
            diagnosticsPage: AnyView(diagnosticsPage),
            onSelectPage: selectPage,
            onRoute: perform
        )
        .modifier(
            SimpleWorkspaceConfirmationModifier(
                model: model,
                confirmsSave: $confirmsSave,
                confirmsAutomaticRenewal:
                    $confirmsAutomaticRenewal,
                confirmsInstall: $confirmsInstall
            )
        )
        .alert(
            "설정을 저장했습니다",
            isPresented: $confirmsSettingsSaved
        ) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("변경한 설정을 저장하고 내 앱 화면에 반영했습니다.")
        }
        .onAppear {
            presentSettingsSaveConfirmationIfNeeded()
            refreshSelectedIPhoneIdentityIfNeeded()
        }
        .onChange(of: model.settingsSaveConfirmationGeneration) { _ in
            presentSettingsSaveConfirmationIfNeeded()
        }
        .onDisappear {
            if selectedPage == .settings {
                projectSelectionSession
                    .restoreOnSettingsCloseIfNeeded(model: model)
            } else {
                projectSelectionSession.restoreOnHomeCloseIfNeeded(
                    model: model
                )
            }
        }
    }

}
