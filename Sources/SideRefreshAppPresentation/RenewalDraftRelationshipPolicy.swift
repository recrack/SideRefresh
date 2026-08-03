import Foundation

public enum RenewalDraftRelationshipPolicy {
    public static func relationship(
        hasGuidedTarget: Bool,
        containerPath: String,
        appName: String,
        bundleIdentifier: String,
        appVersion: String? = nil,
        appIconURL: URL? = nil,
        iPhoneName: String?,
        iPhoneOperatingSystemVersion: String? = nil
    ) -> RenewalRelationship? {
        guard hasGuidedTarget,
              !containerPath.trimmingCharacters(
                  in: .whitespacesAndNewlines
              ).isEmpty
        else {
            return nil
        }
        return RenewalRelationship(
            appName: appName,
            bundleIdentifier: normalized(bundleIdentifier),
            appVersion: normalized(appVersion),
            appIconURL: appIconURL,
            iPhoneName: iPhoneName ?? "iPhone 미선택",
            iPhoneOperatingSystemVersion: normalized(
                iPhoneOperatingSystemVersion
            ),
            iPhoneIsSelected: iPhoneName != nil
        )
    }

    private static func normalized(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}
