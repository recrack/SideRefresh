import SideRefreshCore

public enum AppVersionResolutionPolicy {
    public static func resolve(
        xcode: IOSAppVersion?,
        projectMetadata: IOSAppVersion?
    ) -> IOSAppVersion? {
        xcode ?? projectMetadata
    }
}
