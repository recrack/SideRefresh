import Foundation

public enum AppIdentifierPresentation {
    public static func appDetail(
        bundleIdentifier: String?,
        appVersion: String?
    ) -> String? {
        let values = [
            normalized(bundleIdentifier),
            normalized(appVersion).map {
                SideRefreshLocalization.format("버전 %@", $0)
            },
        ].compactMap { $0 }
        return values.isEmpty ? nil : values.joined(separator: "\n")
    }

    public static func iPhoneDetail(
        operatingSystemVersion: String?
    ) -> String? {
        normalized(operatingSystemVersion).map { "iOS \($0)" }
    }

    public static func appVersion(
        marketingVersion: String?
    ) -> String? {
        normalized(marketingVersion)
    }

    public static func appVersionDetail(
        marketingVersion: String?,
        buildVersion: String?
    ) -> String? {
        guard let marketingVersion = normalized(marketingVersion) else {
            return nil
        }
        guard let buildVersion = normalized(buildVersion) else {
            return marketingVersion
        }
        return SideRefreshLocalization.format(
            "%@ · 빌드 %@",
            marketingVersion,
            buildVersion
        )
    }

    public static func detail(_ bundleIdentifier: String?) -> String? {
        normalized(bundleIdentifier)
    }

    private static func normalized(_ value: String?) -> String? {
        let value = value?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""
        return value.isEmpty ? nil : value
    }
}
