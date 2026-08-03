import Foundation

public enum SimpleErrorMessageContent: Equatable, Sendable {
    case productKey(String)
    case verbatim(String)
}

public enum SimpleErrorMessagePresentation {
    public static func message(
        _ content: SimpleErrorMessageContent,
        bundle: Bundle = .main
    ) -> String {
        switch content {
        case let .productKey(key):
            return SideRefreshLocalization.string(
                key,
                bundle: bundle
            )
        case let .verbatim(message):
            return message
        }
    }
}
