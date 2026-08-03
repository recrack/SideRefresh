import SideRefreshAppPresentation
import SwiftUI

struct SimpleSettingsActionView: View {
    @ObservedObject var model: SideRefreshViewModel
    let performAutomationAction:
        (SimpleSettingsAutomationAction) -> Void
    let openDestination: (RenewalDestination) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("자동 갱신")
                        .font(.headline)
                    Text(
                        SideRefreshLocalization.string(
                            model.agentSummary
                        )
                    )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ForEach(automationActions, id: \.self) { action in
                    Button {
                        performAutomationAction(action)
                    } label: {
                        Text(
                            SideRefreshLocalization.string(
                                automationActionTitle(action)
                            )
                        )
                    }
                }
            }
            HStack {
                Button("고급 설정…") {
                    openDestination(.advancedSettings)
                }
                Button("진단 로그…") {
                    openDestination(.diagnostics)
                }
            }
        }
        .simpleWorkspaceCard()
    }

    private var automationActions: [SimpleSettingsAutomationAction] {
        SimpleSettingsAutomationPolicy.actions(
            for: model.backgroundAutomationPresentationState,
            canRegister: model.canRegisterAgent
        )
    }

    private func automationActionTitle(
        _ action: SimpleSettingsAutomationAction
    ) -> String {
        switch action {
        case .disable:
            return "자동 갱신 끄기"
        case .openApproval:
            return "macOS에서 허용…"
        case .saveFirst:
            return "설정 저장 후 켜기"
        case .enable:
            return "자동 갱신 켜기"
        case .viewDiagnostics:
            return "진단 로그 보기"
        }
    }
}
