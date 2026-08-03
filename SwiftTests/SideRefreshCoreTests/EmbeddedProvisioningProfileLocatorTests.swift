import Foundation
import XCTest
@testable import SideRefreshCore

final class EmbeddedProvisioningProfileLocatorTests: XCTestCase {
    func testFindsProfileInXcodesDefaultProductLayout() throws {
        let derivedDataURL = try makeDerivedDataDirectory()
        let profileURL = derivedDataURL.appendingPathComponent(
            "Build/Products/Release-iphoneos/App.app/embedded.mobileprovision"
        )
        try writeProfile(at: profileURL)

        XCTAssertEqual(
            EmbeddedProvisioningProfileLocator.profiles(
                inDerivedDataURL: derivedDataURL
            ).map {
                $0.resolvingSymlinksInPath().path
            },
            [profileURL.resolvingSymlinksInPath().path]
        )
    }

    func testFindsProfileInLegacySideRefreshProductLayout() throws {
        let derivedDataURL = try makeDerivedDataDirectory()
        let profileURL = derivedDataURL.appendingPathComponent(
            "Build/SideRefreshProducts/App.app/embedded.mobileprovision"
        )
        try writeProfile(at: profileURL)

        XCTAssertEqual(
            EmbeddedProvisioningProfileLocator.profiles(
                inDerivedDataURL: derivedDataURL
            ).map {
                $0.resolvingSymlinksInPath().path
            },
            [profileURL.resolvingSymlinksInPath().path]
        )
    }

    private func makeDerivedDataDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return directory
    }

    private func writeProfile(at profileURL: URL) throws {
        try FileManager.default.createDirectory(
            at: profileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("profile".utf8).write(to: profileURL)
    }
}
