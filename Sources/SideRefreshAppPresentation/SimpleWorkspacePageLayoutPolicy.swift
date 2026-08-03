public struct SimpleWorkspacePageLayoutMetrics:
    Equatable,
    Hashable,
    Sendable
{
    public let horizontalPadding: Double
    public let verticalPadding: Double
    public let minimumContentHeight: Double
    public let maximumContentWidth: Double

    public init(
        horizontalPadding: Double,
        verticalPadding: Double,
        minimumContentHeight: Double,
        maximumContentWidth: Double
    ) {
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.minimumContentHeight = minimumContentHeight
        self.maximumContentWidth = maximumContentWidth
    }
}

public enum SimpleWorkspacePageLayoutPolicy {
    public static let sharedMetrics = SimpleWorkspacePageLayoutMetrics(
        horizontalPadding: 32,
        verticalPadding: 18,
        minimumContentHeight: 50,
        maximumContentWidth: 880
    )

    public static func metrics(
        for page: SimpleWorkspacePage
    ) -> SimpleWorkspacePageLayoutMetrics {
        sharedMetrics
    }

    public static func headerIdentifier(
        for page: SimpleWorkspacePage
    ) -> String {
        "simple.page-header.\(page.rawValue)"
    }
}
