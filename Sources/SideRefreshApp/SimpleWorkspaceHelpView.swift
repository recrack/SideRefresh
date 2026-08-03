import SwiftUI

struct SimpleWorkspaceHelpView: View {
    let openSettings: () -> Void
    let openDiagnostics: () -> Void

    var body: some View {
        SimpleWorkspacePageShell(page: .help) {
            SimpleWorkspacePageHeader(
                title: "도움말",
                subtitle:
                    "내 앱을 iPhone에서 계속 사용하기 위한 순서입니다."
            )
        } content: {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    helpStep(
                        number: 1,
                        title: "내 앱 선택",
                        detail:
                            "Xcode 프로젝트 또는 워크스페이스와 앱 구성을 선택합니다.",
                        systemImage: "app.badge"
                    )
                    helpStep(
                        number: 2,
                        title: "iPhone 연결",
                        detail:
                            "USB, 같은 Wi-Fi 또는 Tailscale 주소로 Xcode가 찾을 iPhone을 정합니다.",
                        systemImage: "iphone.gen3"
                    )
                    helpStep(
                        number: 3,
                        title: "자동 갱신 켜기",
                        detail:
                            "설정을 저장하고 백그라운드 실행을 허용하면 만료 전에 다시 빌드·서명·설치합니다.",
                        systemImage: "arrow.triangle.2.circlepath"
                    )

                    HStack(spacing: 10) {
                        Button("설정으로 이동") {
                            openSettings()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("진단 로그 보기") {
                            openDiagnostics()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(32)
                .frame(maxWidth: 880)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .background(SimpleWorkspacePalette.canvas)
        .tint(SimpleWorkspacePalette.blue)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("simple.help")
    }

    private func helpStep(
        number: Int,
        title: LocalizedStringKey,
        detail: LocalizedStringKey,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(SimpleWorkspacePalette.blue)
                .frame(width: 36, height: 36)
                .background(
                    SimpleWorkspacePalette.blue.opacity(0.12),
                    in: RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(verbatim: "\(number).")
                    Text(title)
                }
                .font(.headline)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .simpleWorkspaceCard()
    }
}
