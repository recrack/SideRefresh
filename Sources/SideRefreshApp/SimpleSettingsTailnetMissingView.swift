import SideRefreshAppPresentation
import SwiftUI

struct SimpleSettingsTailnetMissingView: View {
    let applicationIsInstalled: Bool
    let openTailscale: () -> Void
    let recheck: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(
                    SideRefreshLocalization.string(
                        applicationIsInstalled
                            ? "Tailscale 앱 확인됨 · 상태 확인 필요"
                            : "Tailscale 설치 필요"
                    )
                )
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
            }
            .foregroundStyle(SimpleWorkspacePalette.amber)
            Text(SideRefreshLocalization.string(detail))
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Button(action: openTailscale) {
                    Text(
                        SideRefreshLocalization.string(
                            applicationIsInstalled
                                ? "Tailscale 열기"
                                : "Tailscale 설치…"
                        )
                    )
                }
                Button("설치 후 다시 확인", action: recheck)
            }
        }
    }

    private var detail: String {
        applicationIsInstalled
            ? "앱은 발견했지만 상태 명령을 실행할 수 없습니다."
                + " Tailscale을 열어 연결 상태를 확인하세요."
            : "이 선택은 보이지만 저장과 갱신은 차단됩니다."
                + " Mac과 iPhone에 Tailscale을 설치하고"
                + " 같은 Tailnet에 로그인하세요."
    }
}
