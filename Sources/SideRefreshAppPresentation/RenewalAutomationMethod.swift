public enum RenewalAutomationMethod {
    public enum Execution: Equatable, Sendable {
        case buildSignAndInstall
        case validationOnly
    }

    public enum Connection: Equatable, Sendable {
        case xcodeAutomatic
        case tailnet
        case directAddress
    }

    public struct Configuration: Equatable, Sendable {
        public let execution: Execution
        public let connection: Connection

        public init(
            execution: Execution,
            connection: Connection
        ) {
            self.execution = execution
            self.connection = connection
        }
    }

    public static let nextEligibilityTitle = "다음 갱신 가능 시각"
}
