extension RenewalPresentationResolver {
    static func condition(
        for failure: RenewalPresentationFailure
    ) -> RenewalCondition {
        switch failure {
        case .connection:
            return .connectionFailure
        case .buildOrSigning:
            return .buildOrSigningFailure
        case .installation:
            return .installationFailure
        case .unverifiedInstallation:
            return .installationEvidenceMissing
        case .permission:
            return .permissionRequired
        case .unknown:
            return .checkFailed
        }
    }
}
