import Foundation
import SideRefreshCore
import XCTest

final class TailscaleExecutableLocatorTests: XCTestCase {
    func testLocatorUsesTheFirstExecutableCandidate() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        let unavailable = directory.appendingPathComponent("unavailable")
        let executable = directory.appendingPathComponent("tailscale")
        try Data().write(to: unavailable)
        try Data("#!/bin/sh\n".utf8).write(to: executable)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: executable.path
        )

        let result = TailscaleExecutableLocator(
            candidateURLs: [unavailable, executable]
        ).firstAvailableExecutableURL()

        XCTAssertEqual(result, executable)
    }
}
