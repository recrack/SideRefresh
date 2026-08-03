import SideRefreshCore

public enum ProjectSearchAccessSummaryState:
    Equatable,
    Sendable
{
    case ready
    case checking
    case actionRequired
    case blocked
    case unavailable
}

public struct ProjectSearchAccessSummary:
    Equatable,
    Sendable
{
    public let state: ProjectSearchAccessSummaryState
    public let totalCount: Int
    public let searchableCount: Int
    public let checkingCount: Int
    public let actionRequiredCount: Int
    public let optionalLocationCount: Int
    public let blockedCount: Int

    public init(locations: [ProjectSearchLocationAccess]) {
        totalCount = locations.count
        searchableCount = locations.count {
            $0.status == .allowed
                || $0.status == .partiallyBlocked
        }
        checkingCount = locations.count { $0.status == .checking }
        actionRequiredCount = locations.count {
            $0.status == .verificationRequired
                || $0.status == .partiallyBlocked
        }
        optionalLocationCount = locations.count {
            $0.status == .selectionRequired
        }
        blockedCount = locations.count { $0.status == .blocked }

        if blockedCount > 0 {
            state = .blocked
        } else if actionRequiredCount > 0 {
            state = .actionRequired
        } else if checkingCount > 0 {
            state = .checking
        } else if searchableCount == 0 {
            state = .unavailable
        } else {
            state = .ready
        }
    }
}
