import SideRefreshAppPresentation
import SwiftUI

struct SimpleWorkspaceView: View {
    let presentation: RenewalPresentation
    let nextActionIsEnabled: Bool
    let manualRenewalIsEnabled: Bool
    let automaticRenewalMethod: RenewalAutomationMethod.Presentation
    let focusRequest: SimpleWorkspaceFocusRequest
    let selectedPage: SimpleWorkspacePage
    let settingsPage: AnyView
    let helpPage: AnyView
    let diagnosticsPage: AnyView
    let onSelectPage: (SimpleWorkspacePage) -> Void
    let onRoute: (AppPresentationRoute, SimpleWorkspaceControl) -> Void

    @FocusState private var focusedControl: SimpleWorkspaceControl?
    @AccessibilityFocusState private var accessibilityFocus: SimpleWorkspaceAccessibilityFocus?

    private var semantics: SimpleWorkspaceSemanticModel {
        SimpleWorkspaceSemanticModel(presentation)
    }

    var body: some View {
        HStack(spacing: 0) {
            SimpleWorkspaceSidebar(
                selectedPage: selectedPage,
                focus: $focusedControl,
                accessibilityFocus: $accessibilityFocus,
                onSelectPage: onSelectPage
            )
            Divider()
            selectedPageContent
            .frame(minWidth: 670)
        }
        .background(SimpleWorkspacePalette.canvas)
        .tint(SimpleWorkspacePalette.blue)
        .focusSection()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(
            SimpleWorkspaceAccessibility.workspace
        )
        .modifier(
            SimpleWorkspaceProgressAnnouncementModifier(
                progress: presentation.progress
            )
        )
        .frame(
            minWidth: 860,
            idealWidth: 1040,
            minHeight: 560,
            idealHeight: 700
        )
        .onAppear {
            updateFocus(for: selectedPage)
        }
        .onChange(of: focusRequest) { request in
            focusedControl = request.control
            if let control = request.control {
                accessibilityFocus = .control(control)
            }
        }
        .onChange(of: selectedPage) { page in
            updateFocus(for: page)
        }
    }

    @ViewBuilder
    private var selectedPageContent: some View {
        switch selectedPage {
        case .home:
            homePage
        case .settings:
            settingsPage
        case .help:
            helpPage
        case .diagnostics:
            diagnosticsPage
        }
    }

    private var homePage: some View {
        SimpleWorkspacePageShell(page: .home) {
            SimpleWorkspaceHeader(
                relationship: presentation.relationship,
                evidence: presentation.evidence
            )
        } content: {
            ScrollView {
                SimpleWorkspaceContent(
                    presentation: presentation,
                    semantics: semantics,
                    nextActionIsEnabled: nextActionIsEnabled,
                    manualRenewalIsEnabled:
                        manualRenewalIsEnabled,
                    automaticRenewalMethod:
                        automaticRenewalMethod,
                    focus: $focusedControl,
                    accessibilityFocus: $accessibilityFocus,
                    onRoute: onRoute
                )
                .padding(32)
                .frame(maxWidth: 880)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func updateFocus(for page: SimpleWorkspacePage) {
        #if DEBUG
        if SimpleWorkspaceFixtureCapture.capturesOutput {
            focusedControl = nil
            accessibilityFocus = nil
            return
        }
        #endif
        switch page {
        case .home:
            focusedControl = semantics.focusOrder.first
            accessibilityFocus = .condition
        case .settings:
            focusedControl = .settings
            accessibilityFocus = .control(.settings)
        case .help:
            focusedControl = .help
            accessibilityFocus = .control(.help)
        case .diagnostics:
            focusedControl = .diagnostics
            accessibilityFocus = .control(.diagnostics)
        }
    }
}
