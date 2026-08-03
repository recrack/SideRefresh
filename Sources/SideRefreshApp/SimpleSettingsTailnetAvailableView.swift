import SideRefreshCore
import SideRefreshAppPresentation
import SwiftUI

struct SimpleSettingsTailnetAvailableView: View {
    @ObservedObject var model: SideRefreshViewModel

    var body: some View {
        let devices = selectableDevices
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(
                    "Tailscale 명령 확인됨",
                    systemImage: "terminal.fill"
                )
                .foregroundStyle(SimpleWorkspacePalette.blue)
                Spacer()
                Button {
                    model.discoverTailnetDevices()
                } label: {
                    Text(
                        SideRefreshLocalization.string(
                            model.isDiscoveringTailnet
                                ? "찾는 중…"
                                : "iPhone 찾기"
                        )
                    )
                }
                .disabled(model.isDiscoveringTailnet)
            }
            Text(verbatim: model.tailnetSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
            if !devices.isEmpty {
                Picker(
                    "Tailscale의 iPhone",
                    selection: $model.selectedTailnetNodeID
                ) {
                    Text("iPhone을 선택하세요").tag("")
                    ForEach(devices, id: \.id) { device in
                        Text(
                            verbatim: TailnetDevicePresentation.pickerLabel(
                                for: device
                            )
                        )
                        .tag(device.id ?? "")
                    }
                }
            }
            if let device = model.selectedTailnetDevice {
                SimpleSettingsTailnetStatusView(device: device)
            } else if !devices.isEmpty {
                Text("주소를 확인할 iPhone을 목록에서 선택하세요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var selectableDevices: [TailnetDevice] {
        var seenIdentifiers = Set<String>()
        return model.tailnetDevices.filter { device in
            guard let identifier = device.id,
                  !identifier.isEmpty
            else {
                return false
            }
            return seenIdentifiers.insert(identifier).inserted
        }
    }
}
