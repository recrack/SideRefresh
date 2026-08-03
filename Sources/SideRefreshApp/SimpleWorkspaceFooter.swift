import SideRefreshAppPresentation
import SwiftUI

struct SimpleWorkspaceFooter: View {
    let semantics: SimpleWorkspaceSemanticModel
    let manualRenewalIsEnabled: Bool
    let focus: FocusState<SimpleWorkspaceControl?>.Binding
    let accessibilityFocus:
        AccessibilityFocusState<
            SimpleWorkspaceAccessibilityFocus?
        >.Binding
    let onRoute: (AppPresentationRoute, SimpleWorkspaceControl) -> Void

    @ViewBuilder
    var body: some View {
        if let route = semantics.manualRenewalRoute {
            HStack(spacing: 9) {
                Button {
                    onRoute(route, .manualRenewal)
                } label: {
                    Label(
                        "지금 갱신",
                        systemImage: "arrow.triangle.2.circlepath"
                    )
                }
                .buttonStyle(.bordered)
                .focused(focus, equals: .manualRenewal)
                .accessibilityFocused(
                    accessibilityFocus,
                    equals: .control(.manualRenewal)
                )
                .disabled(!manualRenewalIsEnabled)
                .accessibilityIdentifier(
                    SimpleWorkspaceControl.manualRenewal.rawValue
                )
                Spacer()
            }
            .focusSection()
        }
    }
}
