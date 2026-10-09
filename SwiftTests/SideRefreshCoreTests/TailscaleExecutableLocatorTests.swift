import Foundation
import SideRefreshCore
import XCTest

final class TailscaleExecutableLocatorTests: XCTestCase {
    func testLocatorFindsBundleExecutableInCustomApplicationLocation() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        for identifier in ["io.tailscale.ipn.macsys", "io.tailscale.ipn.macos"] {
            let app = directory.appendingPathComponent("\(identifier)/VPN Client.app")
            let contents = app.appendingPathComponent("Contents")
            let executable = contents.appendingPathComponent("MacOS/TailnetCommand")
            try FileManager.default.createDirectory(
                at: executable.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let info = try PropertyListSerialization.data(
                fromPropertyList: [
                    "CFBundleIdentifier": identifier,
                    "CFBundleExecutable": "TailnetCommand",
                    "CFBundlePackageType": "APPL",
                ], format: .xml, options: 0
            )
            try info.write(to: contents.appendingPathComponent("Info.plist"))
            try Data("#!/bin/sh\n".utf8).write(to: executable)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o700], ofItemAtPath: executable.path
            )

            let locator = TailscaleExecutableLocator(
                candidateURLs: [], applicationURLs: [app]
            )

            XCTAssertEqual(locator.firstAvailableExecutableURL(), executable)
        }
    }

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
            candidateURLs: [unavailable, executable],
            applicationURLs: []
        ).firstAvailableExecutableURL()

        XCTAssertEqual(result, executable)
    }
}
