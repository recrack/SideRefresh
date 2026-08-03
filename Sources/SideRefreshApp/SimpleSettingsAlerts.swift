import SideRefreshAppPresentation
import SwiftUI

struct SimpleSettingsAlerts: ViewModifier {
    @ObservedObject var model: SideRefreshViewModel
    @Binding var confirmsSave: Bool
    @Binding var confirmsEnable: Bool
    @Binding var confirmsDisable: Bool
    let didSave: () -> Void
    let didCancelSave: () -> Void

    func body(content: Content) -> some View {
        content
            .alert(
                "실행 중인 자동 갱신 설정을 바꿀까요?",
                isPresented: $confirmsSave
            ) {
                Button("취소", role: .cancel) {
                    didCancelSave()
                }
                Button("저장") {
                    let saveSucceeded = model.saveConfiguration(
                        allowingActiveAgentExecution: true
                    )
                    if SimpleSettingsSavePresentationPolicy.action(
                        saveSucceeded: saveSucceeded
                    ) == .closeAndConfirm {
                        didSave()
                    }
                }
            } message: {
                Text(verbatim: model.activeConfigurationSaveMessage)
            }
            .alert("자동 갱신을 켤까요?", isPresented: $confirmsEnable) {
                Button("취소", role: .cancel) {}
                Button("자동 갱신 켜기") {
                    model.registerAgent()
                }
            } message: {
                Text(verbatim: model.registrationConfirmationMessage)
            }
            .alert("자동 갱신을 끌까요?", isPresented: $confirmsDisable) {
                Button("취소", role: .cancel) {}
                Button("자동 갱신 끄기") {
                    model.unregisterAgent()
                }
            } message: {
                Text("저장한 앱 설정과 갱신 기록은 그대로 유지됩니다.")
            }
            .alert(
                "오류",
                isPresented: Binding(
                    get: { model.errorMessage != nil },
                    set: { if !$0 { model.dismissError() } }
                )
            ) {
                Button("확인", role: .cancel) {
                    model.dismissError()
                }
            } message: {
                Text(
                    verbatim: SimpleErrorMessagePresentation.message(
                        model.simpleErrorMessageContent
                            ?? .verbatim("")
                    )
                )
            }
    }
}
