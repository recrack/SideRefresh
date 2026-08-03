#if DEBUG
import SideRefreshAppPresentation
import SwiftUI

struct SimpleWorkspaceFixtureHost: View {
    let fixture: SimpleWorkspaceFixture
    @State private var navigation: SimpleWorkspaceFixtureNavigation
    @State private var lastRoute = "none"

    init(fixture: SimpleWorkspaceFixture) {
        self.fixture = fixture
        _navigation = State(
            initialValue: SimpleWorkspaceFixtureNavigation(
                isInteractive:
                    !SimpleWorkspaceFixtureCapture.capturesOutput
            )
        )
    }

    var body: some View {
        let presentation =
            SimpleWorkspaceFixtureAdapter.presentation(for: fixture)
        let semantics = SimpleWorkspaceSemanticModel(presentation)
        let automation = RenewalAutomationMethod.Configuration(
            execution: .buildSignAndInstall,
            connection: .xcodeAutomatic
        )
        VStack(spacing: 0) {
            if SimpleWorkspaceFixtureCapture.isPreview {
                SimpleWorkspaceFixturePreviewBanner()
            }
            SimpleWorkspaceView(
                presentation: presentation,
                nextActionIsEnabled:
                    semantics.nextActionRoute != nil,
                manualRenewalIsEnabled:
                    semantics.manualRenewalRoute != nil,
                automaticRenewalMethod:
                    RenewalAutomationMethod.presentation(
                        background: .enabled,
                        savedConfiguration: automation,
                        draftConfiguration: automation,
                        draftIsDirty: false
                    ),
                focusRequest: .initial,
                selectedPage: navigation.selectedPage,
                settingsPage: AnyView(
                    SimpleWorkspaceFixtureSettingsView(
                        relationship: presentation.relationship
                    )
                ),
                helpPage: AnyView(
                    SimpleWorkspaceHelpView(
                        openSettings: { select(.settings) },
                        openDiagnostics: { select(.diagnostics) }
                    )
                ),
                diagnosticsPage: AnyView(
                    SimpleWorkspaceFixtureDiagnosticsView()
                ),
                onSelectPage: select,
                onRoute: { route, _ in
                    lastRoute = route.fixtureDescription
                }
            )
        }
        .overlay(alignment: .bottomTrailing) {
            if !SimpleWorkspaceFixtureCapture.isRequested {
                Text("Fixture route: \(lastRoute)")
                    .font(.caption2.monospaced())
                    .padding(6)
                    .background(.regularMaterial, in: Capsule())
                    .padding(8)
                    .accessibilityLabel("마지막 semantic route")
                    .accessibilityValue(lastRoute)
                    .accessibilityIdentifier(
                        SimpleWorkspaceAccessibility.fixtureRoute
                    )
            }
        }
    }

    private func select(_ page: SimpleWorkspacePage) {
        navigation.select(page)
        lastRoute = "page.\(page.rawValue)"
    }
}
#endif
