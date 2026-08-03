public struct XcodeContainerRelationshipIndex: Sendable {
    private let relatedContainerIDs: Set<String>
    private let representedProjectIDs: Set<String>
    private let preferredWorkspaceIDsByProjectID:
        [String: Set<String>]
    private let preferredWorkspaceIDByProjectID: [String: String]

    public init(candidates: [XcodeContainerCandidate]) {
        let projectsByID = Dictionary(
            uniqueKeysWithValues: candidates
                .filter { $0.kind == .project }
                .map { ($0.id, $0) }
        )
        var workspaceIDsByProjectID: [String: Set<String>] = [:]
        var projectIDsByWorkspaceID: [String: Set<String>] = [:]
        var relatedIDs = Set<String>()
        let workspaces = candidates
            .filter { $0.kind == .workspace }
            .sorted(by: { $0.id < $1.id })
        for workspace in workspaces {
            for projectID in workspace.referencedProjectPaths {
                guard let project = projectsByID[projectID],
                      Self.representsSameApplications(workspace, project)
                else {
                    continue
                }
                workspaceIDsByProjectID[projectID, default: []]
                    .insert(workspace.id)
                projectIDsByWorkspaceID[workspace.id, default: []]
                    .insert(projectID)
                relatedIDs.insert(projectID)
                relatedIDs.insert(workspace.id)
            }
        }
        var eligibleWorkspaceIDsByProjectID:
            [String: Set<String>] = [:]
        var workspaceByProjectID: [String: String] = [:]
        for (projectID, workspaceIDs) in workspaceIDsByProjectID {
            let eligibleWorkspaceIDs = workspaceIDs.filter {
                projectIDsByWorkspaceID[$0]?.count == 1
            }
            guard !eligibleWorkspaceIDs.isEmpty else {
                continue
            }
            eligibleWorkspaceIDsByProjectID[projectID] =
                eligibleWorkspaceIDs
            if eligibleWorkspaceIDs.count == 1,
               let workspaceID = eligibleWorkspaceIDs.first
            {
                workspaceByProjectID[projectID] = workspaceID
            }
        }
        relatedContainerIDs = relatedIDs
        representedProjectIDs = Set(
            eligibleWorkspaceIDsByProjectID.keys
        )
        preferredWorkspaceIDsByProjectID =
            eligibleWorkspaceIDsByProjectID
        preferredWorkspaceIDByProjectID = workspaceByProjectID
    }

    public func hasRelatedContainer(for candidate: XcodeContainerCandidate) -> Bool {
        relatedContainerIDs.contains(candidate.id)
    }

    public func preferredCandidates(
        from candidates: [XcodeContainerCandidate]
    ) -> [XcodeContainerCandidate] {
        candidates.filter { candidate in
            candidate.kind == .workspace
                || !representedProjectIDs.contains(candidate.id)
        }
    }

    public func preferredCandidateIDs(
        for candidateID: String
    ) -> Set<String> {
        preferredWorkspaceIDsByProjectID[candidateID]
            ?? [candidateID]
    }

    public func preferredCandidateID(for candidateID: String) -> String {
        preferredWorkspaceIDByProjectID[candidateID] ?? candidateID
    }

    public func unambiguousPreferredCandidateID(
        for candidateID: String
    ) -> String? {
        let candidateIDs = preferredCandidateIDs(for: candidateID)
        guard candidateIDs.count == 1 else {
            return nil
        }
        return candidateIDs.first
    }

    public func recommendsWorkspace(for candidate: XcodeContainerCandidate) -> Bool {
        switch candidate.kind {
        case .project:
            return representedProjectIDs.contains(candidate.id)
        case .workspace:
            return preferredWorkspaceIDsByProjectID.values.contains {
                $0.contains(candidate.id)
            }
        }
    }

    private static func representsSameApplications(
        _ workspace: XcodeContainerCandidate,
        _ project: XcodeContainerCandidate
    ) -> Bool {
        let workspaceApplications = Set(
            workspace.applications.map(ApplicationIdentity.init)
        )
        let projectApplications = Set(
            project.applications.map(ApplicationIdentity.init)
        )
        return !projectApplications.isEmpty
            && workspaceApplications == projectApplications
    }

    private struct ApplicationIdentity: Hashable, Sendable {
        let targetName: String
        let productName: String
        let bundleIdentifier: String?

        init(_ application: XcodeApplicationTargetInfo) {
            targetName = application.targetName
            productName = application.productName
            bundleIdentifier = application.bundleIdentifier
        }
    }
}
