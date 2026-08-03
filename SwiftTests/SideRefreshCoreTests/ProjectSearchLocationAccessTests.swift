import Foundation
import XCTest
@testable import SideRefreshCore

final class ProjectSearchLocationAccessTests: XCTestCase {
    func testStandardLocationsSeparateGeneralAndProtectedFolders() {
        let home = URL(fileURLWithPath: "/Users/example")
        let documents = home.appendingPathComponent(
            "Documents",
            isDirectory: true
        )
        let external = URL(
            fileURLWithPath: "/Volumes/Work/iOS Apps",
            isDirectory: true
        )
        let existingPaths: Set<String> = [
            home.path,
            home.appendingPathComponent("Desktop").path,
            documents.path,
            external.path,
        ]

        let locations = ProjectSearchLocationAccess
            .standardLocations(
                homeDirectoryURL: home,
                selectedLocationURLs: [documents, external],
                fileExists: {
                    existingPaths.contains($0.standardizedFileURL.path)
                }
            )

        XCTAssertEqual(
            locations.map(\.kind),
            [.home, .desktop, .documents, .downloads, .custom]
        )
        XCTAssertEqual(
            locations.map(\.status),
            [
                .checking,
                .selectionRequired,
                .checking,
                .selectionRequired,
                .checking,
            ]
        )
        XCTAssertEqual(locations.last?.url, external)
        XCTAssertEqual(
            ProjectSearchLocationAccess.protectedLocationURLs(
                homeDirectoryURL: home
            ),
            [
                home.appendingPathComponent(
                    "Desktop",
                    isDirectory: true
                ),
                home.appendingPathComponent(
                    "Documents",
                    isDirectory: true
                ),
                home.appendingPathComponent(
                    "Downloads",
                    isDirectory: true
                ),
            ]
        )
    }

    func testResolvedStatusRequiresARealSuccessfulProbe() {
        let root = URL(
            fileURLWithPath: "/Users/example/Documents",
            isDirectory: true
        )
        let descendant = root.appendingPathComponent(
            "Private",
            isDirectory: true
        )
        let unrelated = URL(
            fileURLWithPath: "/Users/example/Desktop",
            isDirectory: true
        )

        XCTAssertEqual(
            ProjectSearchLocationAccess.resolvedStatus(
                probe: .accessible,
                rootURL: root,
                unreadableLocationURLs: []
            ),
            .allowed
        )
        XCTAssertEqual(
            ProjectSearchLocationAccess.resolvedStatus(
                probe: .accessible,
                rootURL: root,
                unreadableLocationURLs: [root]
            ),
            .blocked
        )
        XCTAssertEqual(
            ProjectSearchLocationAccess.resolvedStatus(
                probe: .accessible,
                rootURL: root,
                unreadableLocationURLs: [descendant]
            ),
            .partiallyBlocked
        )
        XCTAssertEqual(
            ProjectSearchLocationAccess.resolvedStatus(
                probe: .accessible,
                rootURL: root,
                unreadableLocationURLs: [unrelated]
            ),
            .allowed
        )
        XCTAssertEqual(
            ProjectSearchLocationAccess.resolvedStatus(
                probe: .permissionDenied,
                rootURL: root,
                unreadableLocationURLs: []
            ),
            .blocked
        )
        XCTAssertEqual(
            ProjectSearchLocationAccess.resolvedStatus(
                probe: .missing,
                rootURL: root,
                unreadableLocationURLs: []
            ),
            .missing
        )
    }

    func testCancelledCheckRequiresVerificationInsteadOfClaimingAccess() {
        XCTAssertEqual(
            ProjectSearchAccessStatus.checking
                .restoredAfterCancelledCheck,
            .verificationRequired
        )
        XCTAssertEqual(
            ProjectSearchAccessStatus.allowed
                .restoredAfterCancelledCheck,
            .allowed
        )
    }

    func testRootProbeDoesNotEraseKnownPartialRestrictions() {
        XCTAssertEqual(
            ProjectSearchLocationAccess.resolvedStatusAfterRootProbe(
                probe: .accessible,
                previousStatus: .partiallyBlocked
            ),
            .partiallyBlocked
        )
        XCTAssertEqual(
            ProjectSearchLocationAccess.resolvedStatusAfterRootProbe(
                probe: .permissionDenied,
                previousStatus: .allowed
            ),
            .blocked
        )
    }
}
