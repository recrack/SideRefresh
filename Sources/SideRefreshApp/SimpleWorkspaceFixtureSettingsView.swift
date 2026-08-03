#if DEBUG
import SideRefreshAppPresentation
import SwiftUI

struct SimpleWorkspaceFixtureSettingsView: View {
    let relationship: RenewalRelationship?

    var body: some View {
        SimpleWorkspacePageShell(page: .settings) {
            SimpleWorkspacePageHeader(
                title: "설정",
                subtitle:
                    "내 앱을 내 iPhone에서 계속 사용할 수 있도록 준비합니다."
            )
        } content: {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    fixtureCard(
                        title: "갱신 대상",
                        systemImage: "app.badge.checkmark"
                    ) {
                        fixtureRow("내 앱", value: appName)
                        Divider()
                        fixtureRow(
                            "앱 식별자",
                            value: bundleIdentifier
                        )
                        Divider()
                        fixtureRow("버전", value: appVersion)
                        Divider()
                        fixtureRow("내 iPhone", value: iPhoneName)
                    }

                    fixtureCard(
                        title: "자동 갱신",
                        systemImage: "arrow.triangle.2.circlepath"
                    ) {
                        fixtureRow(
                            "실행",
                            value: localized("빌드 및 설치")
                        )
                        Divider()
                        fixtureRow(
                            "연결",
                            value: localized(
                                "Xcode/CoreDevice 자동 연결"
                            )
                        )
                        Divider()
                        fixtureRow(
                            "갱신 간격",
                            value: "144 h"
                        )
                    }

                    Label(
                        "샘플 미리보기에서는 설정을 변경하지 않습니다.",
                        systemImage: "info.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(32)
                .frame(maxWidth: 880)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("fixture.settings")
    }
}
#endif
