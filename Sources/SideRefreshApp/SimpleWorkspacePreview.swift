#if DEBUG
import SideRefreshAppPresentation
import SwiftUI

#Preview("Simple workspace · Healthy") {
    let automation = RenewalAutomationMethod.Configuration(
        execution: .buildSignAndInstall,
        connection: .xcodeAutomatic
    )
    SimpleWorkspaceView(
        presentation:
            SimpleWorkspaceFixtureAdapter.presentation(for: .healthy),
        nextActionIsEnabled: true,
        manualRenewalIsEnabled: true,
        automaticRenewalMethod: RenewalAutomationMethod.presentation(
            background: .enabled,
            savedConfiguration: automation,
            draftConfiguration: automation,
            draftIsDirty: false
        ),
        focusRequest: .initial,
        selectedPage: .home,
        settingsPage: AnyView(EmptyView()),
        helpPage: AnyView(EmptyView()),
        diagnosticsPage: AnyView(EmptyView()),
        onSelectPage: { _ in },
        onRoute: { _, _ in }
    )
}
#endif
