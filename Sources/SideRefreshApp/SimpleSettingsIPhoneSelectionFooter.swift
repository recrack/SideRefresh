import SideRefreshAppPresentation
import SideRefreshCore
import SwiftUI

struct SimpleSettingsIPhoneSelectionFooter: View {
    let device: CoreDevice?
    let cancel: () -> Void
    let confirm: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: device == nil ? "cursorarrow.click" : "iphone.gen3")
                .font(.title3)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(
                    verbatim: device?.name
                        ?? SideRefreshLocalization.string(
                            "사용할 iPhone을 선택하세요"
                        )
                )
                    .font(.callout.weight(.semibold))
                Text(
                    verbatim:
                    device.map {
                        SideRefreshLocalization.format(
                            "iOS %@ · 식별자 …%@",
                            operatingSystemVersion($0),
                            String($0.udid.suffix(4)).uppercased()
                        )
                    } ?? SideRefreshLocalization.string(
                        "선택한 뒤 이곳에서 확정할 수 있습니다."
                    )
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Button("취소", role: .cancel, action: cancel)
                .keyboardShortcut(.cancelAction)
            Button(action: confirm) {
                Label(
                    "선택한 iPhone 사용",
                    systemImage: "checkmark.circle.fill"
                )
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .disabled(device == nil)
        }
        .padding(12)
        .background(
            SimpleWorkspacePalette.blue.opacity(device == nil ? 0.03 : 0.08),
            in: RoundedRectangle(cornerRadius: 11)
        )
    }

    private func operatingSystemVersion(_ device: CoreDevice) -> String {
        let version = device.operatingSystemVersion?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return version.isEmpty
            ? SideRefreshLocalization.string("미확인")
            : version
    }
}
