#if DEBUG
import SwiftUI

struct SimpleWorkspaceFixturePreviewBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Label("샘플 미리보기", systemImage: "eye.fill")
                .font(.callout.weight(.semibold))
            Text("예시 데이터입니다. 실제 설정은 변경되지 않습니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(SimpleWorkspacePalette.blue.opacity(0.10))
        .overlay(alignment: .bottom) {
            Divider()
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("fixture.preview-banner")
    }
}
#endif
