import SideRefreshAppPresentation
import SwiftUI

struct SimpleSettingsXcodeConnectionView: View {
    @ObservedObject var model: SideRefreshViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label(
                    "Xcode/CoreDevice 연결",
                    systemImage: "iphone.gen3"
                )
                .foregroundStyle(SimpleWorkspacePalette.blue)
                Spacer()
                Button {
                    model.discoverCoreDevices()
                } label: {
                    Text(
                        SideRefreshLocalization.string(
                            model.isDiscoveringCoreDevices
                                ? "확인 중…"
                                : "Xcode에서 iPhone 확인"
                        )
                    )
                }
                .disabled(model.isDiscoveringCoreDevices)
            }
            Text(verbatim: model.coreDeviceDisplaySummary)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(
                SideRefreshLocalization.string(
                    "실제 갱신은 USB 또는 Xcode가 사용할 수 있는 네트워크 경로를"
                        + " 자동으로 사용합니다."
                        + " 현재 전송 경로는 구분하지 않습니다."
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            Color.primary.opacity(0.035),
            in: RoundedRectangle(cornerRadius: 10)
        )
    }
}
