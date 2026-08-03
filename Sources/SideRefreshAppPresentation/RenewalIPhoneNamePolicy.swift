import Foundation

public enum RenewalIPhoneNamePolicy {
    public static func resolve(
        discoveredName: String?,
        rememberedName: String?,
        deviceIdentifier: String,
        discoveredModelName: String? = nil,
        rememberedModelName: String? = nil
    ) -> String {
        let modelName = firstNonempty(
            [discoveredModelName, rememberedModelName]
        )
        let name = firstNonempty([discoveredName, rememberedName])
            ?? fallbackName(deviceIdentifier: deviceIdentifier)
        guard let modelName,
              name.caseInsensitiveCompare(modelName) != .orderedSame
        else {
            return name
        }
        return "\(name) · \(modelName)"
    }

    private static func firstNonempty(
        _ candidates: [String?]
    ) -> String? {
        for candidate in candidates {
            let name = candidate?.trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""
            if !name.isEmpty {
                return name
            }
        }
        return nil
    }

    private static func fallbackName(deviceIdentifier: String) -> String {
        let identifier = deviceIdentifier.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !identifier.isEmpty else {
            return "iPhone"
        }
        return "iPhone · \(identifier.suffix(4).uppercased())"
    }
}
