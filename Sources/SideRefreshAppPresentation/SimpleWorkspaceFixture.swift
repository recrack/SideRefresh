#if DEBUG
import Foundation

public enum SimpleWorkspaceFixture:
    String,
    CaseIterable,
    Hashable,
    Sendable
{
    case healthy
    case initialSetup = "initial-setup"
    case dirtyTarget = "dirty-target"
    case due
    case running
    case failureWithEvidence = "failure-with-evidence"
}

public enum SimpleWorkspaceFixtureAdapter {
    static let now = Date(timeIntervalSince1970: 1_785_672_000)

    public static func presentation(
        for fixture: SimpleWorkspaceFixture
    ) -> RenewalPresentation {
        RenewalPresentationResolver.resolve(input(for: fixture))
    }
}
#endif
