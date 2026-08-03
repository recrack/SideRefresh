import SwiftUI

extension SimpleSettingsView {
    var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("설정")
                .font(.system(size: 28, weight: .semibold))
            Text("내 앱을 내 iPhone에서 계속 사용할 수 있도록 준비합니다.")
                .foregroundStyle(.secondary)
        }
    }

    var compatibilityNotice: some View {
        Label(
            "기존 고급 명령은 앱을 선택하고 저장하기 전까지 그대로 유지됩니다.",
            systemImage: "info.circle"
        )
        .font(.callout)
        .foregroundStyle(.secondary)
        .simpleWorkspaceCard()
    }
}
