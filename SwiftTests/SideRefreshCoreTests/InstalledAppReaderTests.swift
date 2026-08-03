import Foundation
import XCTest
@testable import SideRefreshCore

final class InstalledAppReaderTests: XCTestCase {
    func testReaderQueriesOnlyTheSelectedBundleIdentifier() throws {
        let executable = try makeExecutable(
            """
            #!/bin/sh
            bundle_identifier=""
            output=""
            while test "$#" -gt 0; do
                if test "$1" = "--bundle-id"; then
                    shift
                    bundle_identifier="$1"
                elif test "$1" = "--json-output"; then
                    shift
                    output="$1"
                fi
                shift
            done
            test "$bundle_identifier" = "com.example.sample" || exit 41
            test -n "$output" || exit 42
            printf '%s' '{"result":{"apps":[{"name":"Sample","bundleIdentifier":"com.example.sample","version":"1.2.3","bundleVersion":"45","builtByDeveloper":true}]}}' > "$output"
            """
        )

        let app = try InstalledAppReader().read(
            deviceIdentifier: "00008110-001234567890001E",
            bundleIdentifier: "com.example.sample",
            xcrunURL: executable
        )

        XCTAssertEqual(app?.version, "1.2.3")
        XCTAssertEqual(app?.bundleVersion, "45")
    }

    func testParsesInstalledAppFromDeviceControlOutput() throws {
        let data = Data(
            """
            {
              "result": {
                "apps": [
                  {
                    "name": "Sample",
                    "bundleIdentifier": "com.example.sample",
                    "version": "1.2.3",
                    "bundleVersion": "45",
                    "builtByDeveloper": true,
                    "appClip": false,
                    "defaultApp": false,
                    "hidden": false,
                    "internalApp": false,
                    "removable": true,
                    "url": "file:///private/sample.app/"
                  }
                ]
              }
            }
            """.utf8
        )

        XCTAssertEqual(
            try InstalledAppReader.parse(data),
            [
                InstalledDeviceApp(
                    name: "Sample",
                    bundleIdentifier: "com.example.sample",
                    version: "1.2.3",
                    bundleVersion: "45",
                    builtByDeveloper: true,
                    appClip: false,
                    defaultApp: false,
                    hidden: false,
                    internalApp: false,
                    removable: true,
                    url: "file:///private/sample.app/"
                ),
            ]
        )
    }

    func testRejectsUnsupportedOutput() {
        XCTAssertThrowsError(
            try InstalledAppReader.parse(Data("{}".utf8))
        ) { error in
            XCTAssertEqual(
                error as? InstalledAppReaderError,
                .invalidOutput
            )
        }
    }

    private func makeExecutable(_ script: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let executable = directory.appendingPathComponent("xcrun")
        try Data(script.utf8).write(to: executable)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: executable.path
        )
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return executable
    }
}
