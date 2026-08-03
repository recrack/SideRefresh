import SideRefreshAppPresentation
import SwiftUI

struct SimpleSettingsIPhoneView: View {
    @ObservedObject var model: SideRefreshViewModel
    let findIPhone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("내 iPhone")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(verbatim: iPhoneName)
                        .font(.headline)
                    if let iPhoneVersionDetail {
                        Text(verbatim: iPhoneVersionDetail)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button(action: findIPhone) {
                    Text(SideRefreshLocalization.string(actionTitle))
                }
                .disabled(model.isDiscoveringCoreDevices)
                .accessibilityIdentifier(
                    "simple.settings.select-iphone"
                )
            }
            Text(verbatim: model.coreDeviceDisplaySummary)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var actionTitle: String {
        if model.isDiscoveringCoreDevices {
            return "찾는 중…"
        }
        return iPhoneIsSelected ? "변경…" : "iPhone 선택"
    }

    private var iPhoneIsSelected: Bool {
        let identifier = model.target.deviceIdentifier
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return !identifier.isEmpty
            && !identifier.hasPrefix("REPLACE_")
    }

    private var iPhoneName: String {
        let identifier = model.target.deviceIdentifier
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !identifier.isEmpty else {
            return SideRefreshLocalization.string("iPhone 미선택")
        }
        return RenewalIPhoneNamePolicy.resolve(
            discoveredName: model.selectedCoreDeviceDisplayName,
            rememberedName: nil,
            deviceIdentifier: identifier,
            discoveredModelName:
                model.selectedCoreDeviceMarketingName
        )
    }

    private var iPhoneVersionDetail: String? {
        AppIdentifierPresentation.iPhoneDetail(
            operatingSystemVersion:
                model.selectedCoreDeviceOperatingSystemVersion
        )
    }
}
