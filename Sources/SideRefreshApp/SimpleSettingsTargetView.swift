import SideRefreshAppPresentation
import SwiftUI

struct SimpleSettingsTargetView: View {
    @ObservedObject var model: SideRefreshViewModel
    let chooseApp: () -> Void
    let findIPhone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("갱신 대상", systemImage: "app.connected.to.app.below.fill")
                .font(.headline)
            SimpleSettingsValueRow(
                title: "내 앱",
                value: appName,
                detail: AppIdentifierPresentation.appDetail(
                    bundleIdentifier: model.target.bundleIdentifier,
                    appVersion: AppIdentifierPresentation.appVersionDetail(
                        marketingVersion:
                            model.target.sourceMarketingVersion,
                        buildVersion: model.target.sourceBuildVersion
                    )
                ),
                action: appIsSelected ? "변경…" : "앱 선택",
                identifier: "simple.settings.select-app",
                isDisabled: false,
                perform: chooseApp
            )
            Divider()
            SimpleSettingsIPhoneView(
                model: model,
                findIPhone: findIPhone
            )
            if appIsSelected {
                Label {
                    Text(
                        SideRefreshLocalization.string(
                            appDetailsAreComplete
                                ? "Xcode에서 앱 정보를 자동으로 확인했습니다."
                                : "Xcode 프로젝트의 앱 정보가 하나로 확인되지 않았습니다."
                        )
                    )
                } icon: {
                    Image(
                        systemName: appDetailsAreComplete
                            ? "checkmark.circle.fill"
                            : "exclamationmark.circle"
                    )
                }
                .font(.caption)
                .foregroundStyle(
                    appDetailsAreComplete
                        ? SimpleWorkspacePalette.mint
                        : SimpleWorkspacePalette.amber
                )
                if !appDetailsAreComplete {
                    Button("고급 앱 정보 확인…") {
                        SettingsWindowPresenter.shared.show(
                            model: model,
                            destination: .setup
                        )
                    }
                }
            }
        }
        .simpleWorkspaceCard()
    }

    private var appIsSelected: Bool {
        model.hasGuidedTarget && !model.target.containerPath.isEmpty
    }

    private var appDetailsAreComplete: Bool {
        [
            model.target.scheme,
            model.target.productName,
            model.target.bundleIdentifier,
        ].allSatisfy {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private var appName: String {
        appIsSelected
            ? model.target.displayName
            : SideRefreshLocalization.string("앱 미설정")
    }
}
