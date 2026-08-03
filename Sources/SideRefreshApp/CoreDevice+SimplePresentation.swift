import SideRefreshAppPresentation
import SideRefreshCore

extension CoreDevice {
    var simpleSettingsPickerLabel: String {
        var details = [
            RenewalIPhoneNamePolicy.resolve(
                discoveredName: name,
                rememberedName: nil,
                deviceIdentifier: udid,
                discoveredModelName: marketingName
            ),
        ]
        if let version = AppIdentifierPresentation.iPhoneDetail(
            operatingSystemVersion: operatingSystemVersion
        ) {
            details.append(version)
        }
        details.append("…\(udid.suffix(4).uppercased())")
        return details.joined(separator: " · ")
    }
}
