import Foundation
import SideRefreshAppPresentation
import SwiftUI

struct SimpleSettingsView: View {
    @ObservedObject var model: SideRefreshViewModel
    let launchRequest: SimpleSettingsLaunchRequest
    let chooseApp: () -> Void
    let findIPhone: () -> Void
    let requestSave: () -> Void
    let performAutomationAction:
        (SimpleSettingsAutomationAction) -> Void
    let openDestination: (RenewalDestination) -> Void
    let isEmbedded: Bool
    @AccessibilityFocusState private var focusedSection:
        SimpleSettingsSection?

    @ViewBuilder
    var body: some View {
        if isEmbedded {
            SimpleWorkspacePageShell(page: .settings) {
                SimpleWorkspacePageHeader(
                    title: "설정",
                    subtitle:
                        "내 앱을 내 iPhone에서 계속 사용할 수 있도록 준비합니다."
                )
            } content: {
                settingsContent(
                    includesHeader: false,
                    padding: 32,
                    maximumWidth: 880
                )
            }
            .settingsViewStyle()
        } else {
            settingsContent(
                includesHeader: true,
                padding: 28,
                maximumWidth: 760
            )
            .settingsViewStyle()
        }
    }

    private func settingsContent(
        includesHeader: Bool,
        padding: CGFloat,
        maximumWidth: CGFloat
    ) -> some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if includesHeader {
                            header
                        }
                        if !model.hasGuidedTarget {
                            compatibilityNotice
                        }
                        SimpleSettingsLanguageView(model: model)
                        SimpleSettingsTargetView(
                            model: model,
                            chooseApp: chooseApp,
                            findIPhone: findIPhone
                        )
                        SimpleSettingsConnectionView(model: model)
                            .id(SimpleSettingsSection.connection)
                            .accessibilityFocused(
                                $focusedSection,
                                equals: .connection
                            )
                        SimpleSettingsSigningView(model: model)
                        SimpleSettingsRenewalView(model: model)
                            .id(SimpleSettingsSection.automation)
                            .accessibilityFocused(
                                $focusedSection,
                                equals: .automation
                            )
                        SimpleSettingsActionView(
                            model: model,
                            performAutomationAction:
                                performAutomationAction,
                            openDestination: openDestination
                        )
                    }
                    .padding(padding)
                    .frame(maxWidth: maximumWidth)
                    .frame(maxWidth: .infinity)
                }
                .onAppear { focusRequestedSection(using: proxy) }
                .onChange(of: launchRequest) { _ in
                    focusRequestedSection(using: proxy)
                }
            }
            Divider()
            SimpleSettingsSaveBar(
                model: model,
                requestSave: requestSave
            )
        }
    }

    private func focusRequestedSection(
        using proxy: ScrollViewProxy
    ) {
        guard let section = launchRequest.action.settingsSection else {
            return
        }
        DispatchQueue.main.async {
            proxy.scrollTo(section, anchor: .top)
            focusedSection = section
        }
    }

}

private extension View {
    func settingsViewStyle() -> some View {
        background(SimpleWorkspacePalette.canvas)
            .tint(SimpleWorkspacePalette.blue)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("simple.settings")
    }
}
