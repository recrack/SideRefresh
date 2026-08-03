#if DEBUG
public enum SimpleWorkspaceFixtureLaunchRequest: Equatable, Sendable {
    case normal
    case fixture(SimpleWorkspaceFixture)
    case invalid(String)

    public static func resolve(
        _ rawValue: String?,
        captureRequested: Bool = false
    ) -> SimpleWorkspaceFixtureLaunchRequest {
        guard let rawValue else {
            return captureRequested ? .invalid("missing") : .normal
        }
        guard let fixture = SimpleWorkspaceFixture(rawValue: rawValue) else {
            return .invalid(rawValue)
        }
        return .fixture(fixture)
    }
}
#endif
