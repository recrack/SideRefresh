import SideRefreshAppPresentation
import SideRefreshCore
import SwiftUI

struct SimpleSettingsIPhonePickerPage: View {
    @ObservedObject var model: SideRefreshViewModel
    let onClose: () -> Void
    let isEmbedded: Bool
    @State private var pendingIdentifier: String?

    init(
        model: SideRefreshViewModel,
        onClose: @escaping () -> Void,
        isEmbedded: Bool = false
    ) {
        self.model = model
        self.onClose = onClose
        self.isEmbedded = isEmbedded
        let identifier = model.target.deviceIdentifier.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        _pendingIdentifier = State(
            initialValue: identifier.isEmpty ? nil : identifier
        )
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            deviceList
            Text(verbatim: discoverySummary)
                .font(.caption)
                .foregroundStyle(.secondary)
            SimpleSettingsIPhoneSelectionFooter(
                device: pendingDevice,
                cancel: onClose,
                confirm: usePendingDevice
            )
        }
        .simpleSettingsPageStyle(isEmbedded: isEmbedded)
        .task { model.discoverCoreDevices() }
        .accessibilityIdentifier("simple.iphone-picker")
    }
    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text("설치할 iPhone 선택")
                    .font(.title2.weight(.semibold))
                Text("Xcode에 페어링된 iPhone 중 앱을 설치할 기기를 선택하세요.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                model.discoverCoreDevices()
            } label: {
                Label("다시 찾기", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .disabled(model.isDiscoveringCoreDevices)
        }
        .layoutPriority(10)
        .accessibilityIdentifier("simple.iphone-picker.header")
    }
    @ViewBuilder
    private var deviceList: some View {
        if model.pairedCoreDevices.isEmpty {
            SimpleSettingsIPhoneEmptyState(
                isSearching: model.isDiscoveringCoreDevices
            )
        } else {
            List(
                model.pairedCoreDevices,
                selection: $pendingIdentifier
            ) { device in
                SimpleSettingsIPhoneCandidateRow(
                    device: device,
                    isSelected: pendingIdentifier == device.udid
                )
                .tag(device.udid)
            }
            .listStyle(.inset)
        }
    }
    private var pendingDevice: CoreDevice? {
        model.pairedCoreDevices.first {
            $0.udid == pendingIdentifier
        }
    }
    private var discoverySummary: String {
        if model.isDiscoveringCoreDevices {
            return SideRefreshLocalization.string(
                "Xcode에서 페어링된 iPhone을 찾는 중…"
            )
        }
        let count = model.pairedCoreDevices.count
        return count == 0
            ? model.coreDeviceDisplaySummary
            : SideRefreshLocalization.format(
                "Xcode에서 페어링된 iPhone %ld대를 찾았습니다.",
                count
            )
    }
    private func usePendingDevice() {
        guard let pendingIdentifier else { return }
        model.selectCoreDevice(udid: pendingIdentifier)
        onClose()
    }
}
