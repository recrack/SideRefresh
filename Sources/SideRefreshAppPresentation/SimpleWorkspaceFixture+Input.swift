#if DEBUG
import Foundation

extension SimpleWorkspaceFixtureAdapter {
    static func input(
        for fixture: SimpleWorkspaceFixture
    ) -> RenewalPresentationInput {
        switch fixture {
        case .healthy:
            return configured(recentOutcome: .verified)
        case .initialSetup:
            return RenewalPresentationInput(
                now: now,
                availableDestinations: destinations
            )
        case .dirtyTarget:
            return configured(draftIsDirty: true)
        case .due:
            return configured(renewalIsDue: true)
        case .running:
            return configured(
                progress: RenewalPresentationProgress(
                    phase: .building,
                    message: "Building SideRefresh Sample."
                ),
                recentOutcome: .verified
            )
        case .failureWithEvidence:
            return configured(
                failure: .buildOrSigning,
                recentOutcome: .failed(.buildOrSigning)
            )
        }
    }

    private static func configured(
        draftIsDirty: Bool = false,
        renewalIsDue: Bool = false,
        progress: RenewalPresentationProgress? = nil,
        failure: RenewalPresentationFailure? = nil,
        recentOutcome: RenewalRecentOutcome? = nil
    ) -> RenewalPresentationInput {
        let relationship = RenewalRelationship(
            appName: "SideRefresh Sample",
            bundleIdentifier: "io.github.siderefresh.sample",
            appVersion: "1.0 (1)",
            appIconURL: sampleAppIconURL,
            iPhoneName: "Demo iPhone",
            iPhoneOperatingSystemVersion: "26.0"
        )
        return RenewalPresentationInput(
            now: now,
            hasSavedConfiguration: true,
            hasCompleteTarget: true,
            executionIsEnabled: true,
            draftIsDirty: draftIsDirty,
            automation: .enabled,
            connection: .reachable,
            renewalIsDue: renewalIsDue,
            nextRenewalDate: now.addingTimeInterval(
                renewalIsDue ? -3_600 : 172_800
            ),
            evidence: LastVerifiedEvidence(
                installedAt: now.addingTimeInterval(-86_400),
                expiresAt: now.addingTimeInterval(518_400)
            ),
            progress: progress,
            failure: failure,
            savedRelationship: relationship,
            draftRelationship: relationship,
            recentResult: recentOutcome.map {
                RenewalRecentResult(
                    outcome: $0,
                    completedAt: now.addingTimeInterval(-7_200),
                    summary: "Latest refresh result"
                )
            },
            availableDestinations: destinations
        )
    }

    private static var destinations: Set<RenewalDestination> {
        Set(RenewalDestination.allCases)
    }

    private static var sampleAppIconURL: URL? {
        guard let path = ProcessInfo.processInfo.environment[
            "SIDEREFRESH_UI_FIXTURE_APP_ICON"
        ], !path.isEmpty else {
            return nil
        }
        return URL(fileURLWithPath: path).standardizedFileURL
    }
}
#endif
