import SideRefreshAppPresentation
import SwiftUI

struct SimpleWorkspaceContent: View {
    let presentation: RenewalPresentation
    let semantics: SimpleWorkspaceSemanticModel
    let nextActionIsEnabled: Bool
    let manualRenewalIsEnabled: Bool
    let automaticRenewalMethod: RenewalAutomationMethod.Presentation
    let focus: FocusState<SimpleWorkspaceControl?>.Binding
    let accessibilityFocus:
        AccessibilityFocusState<
            SimpleWorkspaceAccessibilityFocus?
        >.Binding
    let onRoute: (AppPresentationRoute, SimpleWorkspaceControl) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SimpleWorkspaceConditionView(
                presentation: presentation,
                semantics: semantics,
                actionIsEnabled: nextActionIsEnabled,
                focus: focus,
                accessibilityFocus: accessibilityFocus,
                onRoute: onRoute
            )
            SimpleWorkspaceRelationshipView(
                relationship: presentation.relationship,
                focus: focus,
                accessibilityFocus: accessibilityFocus,
                onRoute: onRoute
            )
            SimpleWorkspaceTimingView(
                presentation: presentation,
                automaticRenewalMethod: automaticRenewalMethod,
                settingsAreAvailable:
                    semantics.focusOrder.contains(.settings),
                focus: focus,
                accessibilityFocus: accessibilityFocus,
                onRoute: onRoute
            )
            SimpleWorkspaceActivityView(
                presentation: presentation
            )
            SimpleWorkspaceFooter(
                semantics: semantics,
                manualRenewalIsEnabled: manualRenewalIsEnabled,
                focus: focus,
                accessibilityFocus: accessibilityFocus,
                onRoute: onRoute
            )
        }
    }
}
