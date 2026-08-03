public struct SimpleSettingsWindowContentSize:
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

public enum SimpleSettingsWindowSizePolicy {
    public static let initialSize = SimpleSettingsWindowContentSize(
        width: 760,
        height: 720
    )
    public static let minimumSize = SimpleSettingsWindowContentSize(
        width: initialSize.width,
        height: initialSize.height
    )

    public static func sizeAfterRestore(
        width: Double,
        height: Double
    ) -> SimpleSettingsWindowContentSize {
        SimpleSettingsWindowContentSize(
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
