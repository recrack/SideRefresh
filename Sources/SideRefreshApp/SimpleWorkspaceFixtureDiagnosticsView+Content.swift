#if DEBUG
import SwiftUI

extension SimpleWorkspaceFixtureDiagnosticsView {
    var phases: [(title: LocalizedStringKey, icon: String)] {
        [
            ("프로젝트 확인", "folder.badge.checkmark"),
            ("빌드 및 설치", "hammer.fill"),
            ("현재 서명 만료", "checkmark.seal.fill"),
        ]
    }

    func diagnosticRow(
        _ phase: (title: LocalizedStringKey, icon: String)
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: phase.icon)
                .foregroundStyle(SimpleWorkspacePalette.blue)
                .frame(width: 24)
            Text(phase.title)
                .font(.callout)
            Spacer()
            Label("완료", systemImage: "checkmark")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SimpleWorkspacePalette.mint)
        }
        .padding(.vertical, 4)
    }

    var sampleLog: String {
        """
        [09:00:00] SideRefresh Sample configuration loaded
        [09:00:01] Xcode/CoreDevice connection verified
        [09:00:04] Build, sign, and install completed
        [09:00:05] Personal Team expiration recorded
        """
    }
}
#endif
