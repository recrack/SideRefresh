import SideRefreshAppPresentation
import SwiftUI

struct SimpleWorkspaceAutomationMethodView: View {
    let presentation: RenewalAutomationMethod.Presentation
    let settingsAreAvailable: Bool
    let focus: FocusState<SimpleWorkspaceControl?>.Binding
    let accessibilityFocus:
        AccessibilityFocusState<
            SimpleWorkspaceAccessibilityFocus?
        >.Binding
    let onRoute: (AppPresentationRoute, SimpleWorkspaceControl) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            backgroundRow
            Divider()
            methodRow(
                "실행",
                identifier: "simple.automation.execution",
                value: presentation.executionTitle,
                detail: presentation.executionDetail,
                systemImage: "hammer.fill",
                tint: SimpleWorkspacePalette.blue
            )
            Divider()
            connectionRow
            if let notice = presentation.provenanceNotice {
                Label(
                    SideRefreshLocalization.string(notice),
                    systemImage: "info.circle"
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .accessibilityElement(children: .contain)
    }

}
