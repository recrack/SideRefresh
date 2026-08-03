#if DEBUG
import SwiftUI

struct SimpleWorkspaceFixtureDiagnosticsView: View {
    var body: some View {
        SimpleWorkspacePageShell(page: .diagnostics) {
            SimpleWorkspacePageHeader(
                title: "진단 로그",
                subtitle: "최근 갱신이 검증됐습니다"
            ) {
                Label("완료", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SimpleWorkspacePalette.mint)
            }
        } content: {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(spacing: 0) {
                        ForEach(
                            Array(phases.enumerated()),
                            id: \.offset
                        ) { index, phase in
                            diagnosticRow(phase)
                            if index < phases.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .simpleWorkspaceCard()

                    VStack(alignment: .leading, spacing: 10) {
                        Label(
                            "최근 갱신 결과",
                            systemImage: "terminal"
                        )
                        .font(.headline)
                        Text(verbatim: sampleLog)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                    }
                    .simpleWorkspaceCard()

                    Label(
                        "예시 진단 정보입니다. 실제 로그는 Release 앱에서 표시됩니다.",
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
        .accessibilityIdentifier("fixture.diagnostics")
    }
}
#endif
