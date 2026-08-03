import SideRefreshAppPresentation
import SideRefreshCore
import SwiftUI

struct SimpleSettingsIPhoneCandidateRow: View {
    let device: CoreDevice
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "iphone.gen3")
                .font(.title2)
                .foregroundStyle(SimpleWorkspacePalette.blue)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(displayName)
                    .font(.callout.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(SimpleWorkspacePalette.mint)
                    .accessibilityLabel("선택됨")
            }
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityValue(
            SideRefreshLocalization.string(
                isSelected ? "선택됨" : "선택 안 됨"
            )
        )
    }

    private var displayName: String {
        RenewalIPhoneNamePolicy.resolve(
            discoveredName: device.name,
            rememberedName: nil,
            deviceIdentifier: device.udid,
            discoveredModelName: device.marketingName
        )
    }

    private var detail: String {
        var values = [device.marketingName]
            .compactMap { value in
                let value = value?.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                return value?.isEmpty == false ? value : nil
            }
        if let version = AppIdentifierPresentation.iPhoneDetail(
            operatingSystemVersion: device.operatingSystemVersion
        ) {
            values.append(version)
        }
        values.append(
            SideRefreshLocalization.format(
                "식별자 …%@",
                String(device.udid.suffix(4)).uppercased()
            )
        )
        return values.joined(separator: " · ")
    }
}
