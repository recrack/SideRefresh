import SideRefreshAppPresentation
import SwiftUI

struct SimpleWorkspaceConditionView: View {
    let presentation: RenewalPresentation
    let semantics: SimpleWorkspaceSemanticModel
    let actionIsEnabled: Bool
    let focus: FocusState<SimpleWorkspaceControl?>.Binding
    let accessibilityFocus:
        AccessibilityFocusState<
            SimpleWorkspaceAccessibilityFocus?
        >.Binding
    let onRoute: (AppPresentationRoute, SimpleWorkspaceControl) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 7) {
                Text("갱신 상태")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SimpleWorkspacePalette.blue)
                Text(
                    SideRefreshLocalization.string(
                        presentation.condition.sideRefreshTitle
                    )
                )
                    .font(.system(size: 30, weight: .semibold))
                Text(
                    SideRefreshLocalization.string(
                        presentation.condition.sideRefreshDetail
                    )
                )
                    .font(.body)
                    .foregroundStyle(.secondary)
                if presentation.condition == .healthy {
                    Text("지금은 할 일이 없습니다.")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(SimpleWorkspacePalette.mint)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(
                SimpleWorkspaceRegion.condition.rawValue
            )
            .accessibilityFocused(
                accessibilityFocus,
                equals: .condition
            )

            if let action = presentation.nextAction {
                HStack {
                    Button {
                        guard let route = semantics.nextActionRoute else {
                            return
                        }
                        onRoute(route, .nextAction)
                    } label: {
                        Text(
                            SideRefreshLocalization.string(
                                action.sideRefreshTitle
                            )
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .focused(focus, equals: .nextAction)
                    .accessibilityFocused(
                        accessibilityFocus,
                        equals: .control(.nextAction)
                    )
                    .disabled(!actionIsEnabled)
                    .accessibilityIdentifier(
                        SimpleWorkspaceControl.nextAction.rawValue
                    )
                    Spacer()
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(
                    SimpleWorkspaceRegion.nextAction.rawValue
                )
            }
        }
    }
}
