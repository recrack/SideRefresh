import Foundation

public enum PersonalTeamCandidateSource: Equatable, Sendable {
    case xcodeProject
    case activeLocalProvision
    case expiredLocalProvision
    case appleDevelopmentIdentity
}

public struct PersonalTeamCandidate:
    Equatable,
    Identifiable,
    Sendable
{
    public let identifier: String
    public let source: PersonalTeamCandidateSource

    public init(
        identifier: String,
        source: PersonalTeamCandidateSource
    ) {
        self.identifier = identifier
        self.source = source
    }

    public var id: String {
        identifier
    }
}

public enum PersonalTeamSelection: Equatable, Sendable {
    case selected(PersonalTeamCandidate)
    case confirmationRequired(PersonalTeamCandidate)
    case notFound
    case ambiguous([PersonalTeamCandidate])
}

public enum PersonalTeamSelector {
    public static func select(
        from profiles: [ProvisioningProfileMetadata],
        projectTeamIdentifiers: [String] = [],
        signingIdentityTeamIdentifiers: [String] = [],
        preferredTeamIdentifiers: [String],
        now: Date = Date()
    ) -> PersonalTeamSelection {
        let localProfiles = profiles.filter {
            $0.isLocalProvision == true
        }
        let projectCandidates = projectTeamIdentifiers
            .filter(isValidTeamIdentifier)
            .map {
                PersonalTeamCandidate(
                    identifier: $0,
                    source: .xcodeProject
                )
            }
        let activeCandidates = candidates(
            from: localProfiles.filter {
                $0.expirationDate > now
            },
            source: .activeLocalProvision
        )
        let expiredCandidates = candidates(
            from: localProfiles.filter {
                $0.expirationDate <= now
            },
            source: .expiredLocalProvision
        )
        let identityCandidates = signingIdentityTeamIdentifiers
            .filter(isValidTeamIdentifier)
            .map {
                PersonalTeamCandidate(
                    identifier: $0,
                    source: .appleDevelopmentIdentity
                )
            }
        return select(
            from:
                projectCandidates
                + activeCandidates
                + expiredCandidates
                + identityCandidates,
            preferredTeamIdentifiers: preferredTeamIdentifiers
        )
    }

    private static func select(
        from candidates: [PersonalTeamCandidate],
        preferredTeamIdentifiers: [String]
    ) -> PersonalTeamSelection {
        let candidatesByIdentifier = Dictionary(
            candidates.map { ($0.identifier, $0) },
            uniquingKeysWith: { first, second in
                sourcePriority(first.source)
                    >= sourcePriority(second.source)
                    ? first
                    : second
            }
        )
        let preferredOrder = preferredTeamIdentifiers
            .enumerated()
            .reduce(into: [String: Int]()) { result, item in
                guard isValidTeamIdentifier(item.element),
                      result[item.element] == nil
                else {
                    return
                }
                result[item.element] = item.offset
            }
        let sortedCandidates = candidatesByIdentifier.values.sorted {
            let lhsPreference =
                preferredOrder[$0.identifier] ?? Int.max
            let rhsPreference =
                preferredOrder[$1.identifier] ?? Int.max
            if lhsPreference != rhsPreference {
                return lhsPreference < rhsPreference
            }
            return $0.identifier < $1.identifier
        }
        switch sortedCandidates.count {
        case 0:
            return .notFound
        case 1:
            let candidate = sortedCandidates[0]
            if candidate.source == .appleDevelopmentIdentity {
                return .confirmationRequired(candidate)
            }
            return .selected(candidate)
        default:
            return .ambiguous(sortedCandidates)
        }
    }

    private static func sourcePriority(
        _ source: PersonalTeamCandidateSource
    ) -> Int {
        switch source {
        case .xcodeProject:
            return 4
        case .activeLocalProvision:
            return 3
        case .expiredLocalProvision:
            return 2
        case .appleDevelopmentIdentity:
            return 1
        }
    }

    private static func candidates(
        from profiles: [ProvisioningProfileMetadata],
        source: PersonalTeamCandidateSource
    ) -> [PersonalTeamCandidate] {
        profiles
            .flatMap(\.teamIdentifiers)
            .filter(isValidTeamIdentifier)
            .map {
                PersonalTeamCandidate(
                    identifier: $0,
                    source: source
                )
            }
    }

    private static func isValidTeamIdentifier(_ value: String) -> Bool {
        value.count == 10
            && value.rangeOfCharacter(
                from: CharacterSet.alphanumerics.inverted
            ) == nil
    }
}
