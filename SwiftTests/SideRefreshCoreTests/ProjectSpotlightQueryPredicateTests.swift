import Foundation
import XCTest
@testable import SideRefreshCore

final class ProjectSpotlightQueryPredicateTests: XCTestCase {
    func testUsesContainerPredicateDirectlyWithoutExcludedFolders() {
        let predicate = ProjectSpotlightQueryPredicate.make(
            excludingDirectoryURLs: []
        )

        let containerPredicate = predicate as? NSCompoundPredicate
        XCTAssertEqual(
            containerPredicate?.compoundPredicateType,
            .or
        )
        XCTAssertEqual(containerPredicate?.subpredicates.count, 2)
        XCTAssertTrue(
            predicate.evaluate(
                with: [
                    NSMetadataItemFSNameKey: "Example.xcodeproj",
                    NSMetadataItemPathKey:
                        "/Users/example/Projects/Example.xcodeproj",
                ]
            )
        )
        XCTAssertFalse(
            predicate.evaluate(
                with: [
                    NSMetadataItemFSNameKey: "Example.txt",
                    NSMetadataItemPathKey:
                        "/Users/example/Projects/Example.txt",
                ]
            )
        )
    }

    func testCombinesContainerAndExcludedFolderPredicates() {
        let predicate = ProjectSpotlightQueryPredicate.make(
            excludingDirectoryURLs: [
                URL(fileURLWithPath: "/Users/example/Documents"),
                URL(fileURLWithPath: "/Users/example/Downloads"),
            ]
        )

        let compoundPredicate = predicate as? NSCompoundPredicate
        XCTAssertEqual(
            compoundPredicate?.compoundPredicateType,
            .and
        )
        XCTAssertEqual(
            compoundPredicate?.subpredicates.count,
            3
        )
        XCTAssertFalse(
            predicate.evaluate(
                with: [
                    NSMetadataItemFSNameKey: "Hidden.xcodeproj",
                    NSMetadataItemPathKey:
                        "/Users/example/Documents/Hidden.xcodeproj",
                ]
            )
        )
        XCTAssertTrue(
            predicate.evaluate(
                with: [
                    NSMetadataItemFSNameKey: "Visible.xcworkspace",
                    NSMetadataItemPathKey:
                        "/Users/example/Projects/Visible.xcworkspace",
                ]
            )
        )
    }
}
