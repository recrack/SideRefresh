public struct SimpleWorkspaceWindowContentSize:
    Equatable,
    Sendable
{
    public let width: Double
    public let height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

public enum SimpleWorkspaceWindowSizePolicy {
    public static let initialSize = SimpleWorkspaceWindowContentSize(
        width: 1040,
        height: 700
    )
    public static let minimumSize = SimpleWorkspaceWindowContentSize(
        width: 860,
        height: 560
    )

    public static func sizeAfterRestore(
        width: Double,
        height: Double
    ) -> SimpleWorkspaceWindowContentSize {
        SimpleWorkspaceWindowContentSize(
            width: clamped(width, minimum: minimumSize.width),
            height: clamped(height, minimum: minimumSize.height)
        )
    }

    private static func clamped(
        _ value: Double,
        minimum: Double
    ) -> Double {
        value.isFinite ? max(value, minimum) : minimum
    }
}
