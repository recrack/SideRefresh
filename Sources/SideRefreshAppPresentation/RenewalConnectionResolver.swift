public enum RenewalConnectionResolver {
    public static func resolve(
        isChecking: Bool,
        knownReachability: Bool?,
        canAttemptWithoutProbe: Bool
    ) -> RenewalConnectionState {
        let evidence = knownReachability.map {
            $0 ? RenewalConnectionEvidence.verifiedReachable
                : .verifiedUnreachable
        } ?? (canAttemptWithoutProbe ? .routeAvailable : .absent)
        return resolve(isChecking: isChecking, evidence: evidence)
    }

    public static func resolve(
        isChecking: Bool,
        evidence: RenewalConnectionEvidence
    ) -> RenewalConnectionState {
        guard !isChecking else {
            return .checking
        }
        switch evidence {
        case .absent:
            return .unknown
        case .verifiedReachable:
            return .reachable
        case .verifiedUnreachable:
            return .unreachable
        case .routeAvailable:
            return .availableForAttempt
        }
    }
}
