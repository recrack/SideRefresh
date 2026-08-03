import Foundation
import XCTest
@testable import SideRefreshCore

final class PersonalTeamSelectorTests: XCTestCase {
    func testSelectsTheOnlyValidPersonalTeam() {
        let result = PersonalTeamSelector.select(
            from: [
                profile(
                    team: "ORGTEAM123",
                    isLocalProvision: false
                ),
                profile(
                    team: "PERSONAL01",
                    isLocalProvision: true
                ),
            ],
            preferredTeamIdentifiers: []
        )

        XCTAssertEqual(
            result,
            .selected(
                PersonalTeamCandidate(
                    identifier: "PERSONAL01",
                    source: .activeLocalProvision
                )
            )
        )
    }

    func testRejectsAnAmbiguousSetOfPersonalTeams() {
        let result = PersonalTeamSelector.select(
            from: [
                profile(team: "PERSONAL01", isLocalProvision: true),
                profile(team: "PERSONAL02", isLocalProvision: true),
            ],
            preferredTeamIdentifiers: []
        )

        XCTAssertEqual(
            result,
            .ambiguous([
                PersonalTeamCandidate(
                    identifier: "PERSONAL01",
                    source: .activeLocalProvision
                ),
                PersonalTeamCandidate(
                    identifier: "PERSONAL02",
                    source: .activeLocalProvision
                ),
            ])
        )
    }

    func testPreferredPersonalTeamStillRequiresExplicitChoice() {
        let result = PersonalTeamSelector.select(
            from: [
                profile(team: "PERSONAL01", isLocalProvision: true),
                profile(team: "PERSONAL02", isLocalProvision: true),
            ],
            preferredTeamIdentifiers: ["PERSONAL02"]
        )

        XCTAssertEqual(
            result,
            .ambiguous([
                PersonalTeamCandidate(
                    identifier: "PERSONAL02",
                    source: .activeLocalProvision
                ),
                PersonalTeamCandidate(
                    identifier: "PERSONAL01",
                    source: .activeLocalProvision
                )
            ])
        )
    }

    func testDuplicateAndEmptyPreferredTeamsDoNotCrashDiscovery() {
        let result = PersonalTeamSelector.select(
            from: [
                profile(team: "PERSONAL01", isLocalProvision: true),
                profile(team: "PERSONAL02", isLocalProvision: true),
            ],
            preferredTeamIdentifiers: [
                "",
                "PERSONAL02",
                "PERSONAL02",
                "PERSONAL01",
            ]
        )

        XCTAssertEqual(
            result,
            .ambiguous([
                PersonalTeamCandidate(
                    identifier: "PERSONAL02",
                    source: .activeLocalProvision
                ),
                PersonalTeamCandidate(
                    identifier: "PERSONAL01",
                    source: .activeLocalProvision
                ),
            ])
        )
    }

    func testExpiredPersonalTeamCanStillProvideItsIdentifier() {
        let result = PersonalTeamSelector.select(
            from: [
                profile(
                    team: "PERSONAL01",
                    isLocalProvision: true,
                    expirationDate: .distantPast
                ),
                profile(team: "BAD", isLocalProvision: true),
            ],
            preferredTeamIdentifiers: ["PERSONAL01"]
        )

        XCTAssertEqual(
            result,
            .selected(
                PersonalTeamCandidate(
                    identifier: "PERSONAL01",
                    source: .expiredLocalProvision
                )
            )
        )
    }

    func testSigningIdentityIsAnUnverifiedFallbackCandidate() {
        let result = PersonalTeamSelector.select(
            from: [],
            signingIdentityTeamIdentifiers: ["CERTTEAM01"],
            preferredTeamIdentifiers: []
        )

        XCTAssertEqual(
            result,
            .confirmationRequired(
                PersonalTeamCandidate(
                    identifier: "CERTTEAM01",
                    source: .appleDevelopmentIdentity
                )
            )
        )
    }

    func testActivePersonalTeamProfileWinsOverSigningIdentity() {
        let result = PersonalTeamSelector.select(
            from: [
                profile(
                    team: "PERSONAL01",
                    isLocalProvision: true
                ),
            ],
            signingIdentityTeamIdentifiers: ["PERSONAL01"],
            preferredTeamIdentifiers: []
        )

        XCTAssertEqual(
            result,
            .selected(
                PersonalTeamCandidate(
                    identifier: "PERSONAL01",
                    source: .activeLocalProvision
                )
            )
        )
    }

    func testXcodeProjectTeamWinsOverOtherLocalEvidence() {
        let result = PersonalTeamSelector.select(
            from: [
                profile(
                    team: "PROJECT001",
                    isLocalProvision: true
                ),
            ],
            projectTeamIdentifiers: ["PROJECT001"],
            signingIdentityTeamIdentifiers: ["PROJECT001"],
            preferredTeamIdentifiers: []
        )

        XCTAssertEqual(
            result,
            .selected(
                PersonalTeamCandidate(
                    identifier: "PROJECT001",
                    source: .xcodeProject
                )
            )
        )
    }

    func testDifferentEvidenceSourcesStillRequireChoice() {
        let result = PersonalTeamSelector.select(
            from: [
                profile(
                    team: "PERSONAL01",
                    isLocalProvision: true
                ),
            ],
            signingIdentityTeamIdentifiers: ["CERTTEAM01"],
            preferredTeamIdentifiers: []
        )

        XCTAssertEqual(
            result,
            .ambiguous([
                PersonalTeamCandidate(
                    identifier: "CERTTEAM01",
                    source: .appleDevelopmentIdentity
                ),
                PersonalTeamCandidate(
                    identifier: "PERSONAL01",
                    source: .activeLocalProvision
                ),
            ])
        )
    }

    func testMalformedSigningIdentityTeamIsIgnored() {
        let result = PersonalTeamSelector.select(
            from: [],
            signingIdentityTeamIdentifiers: ["BAD"],
            preferredTeamIdentifiers: []
        )

        XCTAssertEqual(result, .notFound)
    }

    private func profile(
        team: String,
        isLocalProvision: Bool,
        expirationDate: Date = .distantFuture
    ) -> ProvisioningProfileMetadata {
        ProvisioningProfileMetadata(
            identifier: UUID().uuidString,
            name: "Test",
            creationDate: nil,
            expirationDate: expirationDate,
            applicationIdentifier: nil,
            teamIdentifiers: [team],
            isLocalProvision: isLocalProvision
        )
    }
}
