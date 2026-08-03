import SideRefreshAppPresentation
import SwiftUI

struct SimpleWorkspaceConfirmationModifier: ViewModifier {
    @ObservedObject var model: SideRefreshViewModel
    @Binding var confirmsSave: Bool
    @Binding var confirmsAutomaticRenewal: Bool
    @Binding var confirmsInstall: Bool

    func body(content: Content) -> some View {
        content
            .alert(
                "변경사항을 저장할까요?",
                isPresented: $confirmsSave
            ) {
                Button("취소", role: .cancel) {}
                Button("저장") {
                    model.saveConfiguration(
                        allowingActiveAgentExecution: true
                    )
                }
                .accessibilityIdentifier(
                    "simple.confirmation.save"
                )
            } message: {
                Text(verbatim: model.activeConfigurationSaveMessage)
            }
            .alert(
                "자동 갱신을 켤까요?",
                isPresented: $confirmsAutomaticRenewal
            ) {
                Button("취소", role: .cancel) {}
                Button("자동 갱신 켜기") {
                    model.registerAgent()
                }
                .accessibilityIdentifier(
                    "simple.confirmation.automation"
                )
            } message: {
                Text(verbatim: model.registrationConfirmationMessage)
            }
            .alert(
                Text(
                    verbatim: model.immediateRenewalConfirmationTitle
                ),
                isPresented: $confirmsInstall
            ) {
                Button("취소", role: .cancel) {}
                Button("빌드 및 설치") {
                    model.renewImmediately()
                }
                .accessibilityIdentifier(
                    "simple.confirmation.install"
                )
            } message: {
                Text(verbatim: model.immediateRenewalConfirmationMessage)
            }
            .alert(
                SideRefreshLocalization.string(model.errorAlertTitle),
                isPresented: Binding(
                    get: { model.errorMessage != nil },
                    set: { if !$0 { model.dismissError() } }
                )
            ) {
                if model.errorOffersXcodeRecovery {
                    Button("Xcode에서 열기") {
                        model.dismissError()
                        model.openXcode()
                    }
                }
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
