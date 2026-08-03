import Foundation
import XCTest
@testable import SideRefreshCore

final class CoreDeviceReaderTests: XCTestCase {
    func testParserUsesTheHardwareUDIDAndKeepsOnlyPhysicalIPhones() throws {
        // devicectl can omit `reality` for a known physical iPhone.
        let snapshot = try CoreDeviceSnapshot.parse(
            Data(Self.deviceListJSON.utf8)
        )

        XCTAssertEqual(
            snapshot.iPhones,
            [
                CoreDevice(
                    udid: "00008110-001234567890001E",
                    name: "Personal iPhone",
                    marketingName: "iPhone 16 Pro",
                    operatingSystemVersion: "26.5",
                    pairingState: "paired"
                ),
            ]
        )
        XCTAssertEqual(
            snapshot.iPhones.first?.udid,
            "00008110-001234567890001E"
        )
        XCTAssertNotEqual(
            snapshot.iPhones.first?.udid,
            "12345678-1234-1234-1234-1234567890AB"
        )
    }

    func testParserRejectsMalformedJSON() {
        XCTAssertThrowsError(
            try CoreDeviceSnapshot.parse(Data("not-json".utf8))
        ) { error in
            XCTAssertEqual(
                error as? CoreDeviceReaderError,
                .invalidOutput
            )
        }
    }

    func testReaderWritesJSONToATemporaryFileForDevicectl() throws {
        let executable = try makeExecutable(
            """
            #!/bin/sh
            test "$1" = "devicectl" || exit 41
            test "$2" = "list" || exit 42
            test "$3" = "devices" || exit 43
            test "$4" = "--filter" || exit 44
            test "$5" = "hardwareProperties.platform == 'iOS' AND hardwareProperties.deviceType == 'iPhone'" || exit 45
            output=""
            while test "$#" -gt 0; do
                if test "$1" = "--json-output"; then
                    shift
                    output="$1"
                    break
                fi
                shift
            done
            test -n "$output" || exit 46
            printf '%s' '\(Self.deviceListJSON)' > "$output"
            """
        )

        let snapshot = try CoreDeviceReader().read(
            xcrunURL: executable
        )

        XCTAssertEqual(snapshot.pairedIPhones.count, 1)
        XCTAssertEqual(
            snapshot.pairedIPhones.first?.name,
            "Personal iPhone"
        )
    }

    func testReaderReportsADevicectlFailure() throws {
        let executable = try makeExecutable(
            """
            #!/bin/sh
            printf '%s' 'CoreDevice unavailable' >&2
            exit 17
            """
        )

        XCTAssertThrowsError(
            try CoreDeviceReader().read(xcrunURL: executable)
        ) { error in
            guard case let .commandFailed(exitCode, message) =
                    error as? CoreDeviceReaderError
            else {
                return XCTFail("Expected commandFailed, got \(error)")
            }
            XCTAssertEqual(exitCode, 17)
            XCTAssertEqual(message, "CoreDevice unavailable")
        }
    }

    func testReaderRejectsMissingXcodeTools() {
        XCTAssertThrowsError(
            try CoreDeviceReader().read(
                xcrunURL: URL(
                    fileURLWithPath: "/definitely/missing/xcrun"
                )
            )
        ) { error in
            guard case .xcodeToolsUnavailable =
                    error as? CoreDeviceReaderError
            else {
                return XCTFail(
                    "Expected xcodeToolsUnavailable, got \(error)"
                )
            }
        }
    }

    func testReaderRejectsMissingJSONOutput() throws {
        let executable = try makeExecutable(
            """
            #!/bin/sh
            exit 0
            """
        )

        XCTAssertThrowsError(
            try CoreDeviceReader().read(xcrunURL: executable)
        ) { error in
            XCTAssertEqual(
                error as? CoreDeviceReaderError,
                .outputMissing
            )
        }
    }

    func testReaderRejectsOversizedJSONOutput() throws {
        let executable = try makeExecutable(
            """
            #!/bin/sh
            output=""
            while test "$#" -gt 0; do
                if test "$1" = "--json-output"; then
                    shift
                    output="$1"
                    break
                fi
                shift
            done
            test -n "$output" || exit 46
            /bin/dd if=/dev/zero of="$output" bs=1048576 count=5 2>/dev/null
            """
        )

        XCTAssertThrowsError(
            try CoreDeviceReader().read(xcrunURL: executable)
        ) { error in
            XCTAssertEqual(
                error as? CoreDeviceReaderError,
                .outputTooLarge
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

    private static let deviceListJSON = """
    {
      "info": {
        "outcome": "success"
      },
      "result": {
        "devices": [
          {
            "identifier": "12345678-1234-1234-1234-1234567890AB",
            "connectionProperties": {
              "pairingState": "paired",
              "transportType": "localNetwork"
            },
            "deviceProperties": {
              "name": "Personal iPhone",
              "osVersionNumber": "26.5"
            },
            "hardwareProperties": {
              "deviceType": "iPhone",
              "marketingName": "iPhone 16 Pro",
              "platform": "iOS",
              "udid": "00008110-001234567890001E"
            }
          },
          {
            "identifier": "87654321-4321-4321-4321-BA0987654321",
            "connectionProperties": {
              "pairingState": "paired"
            },
            "deviceProperties": {
              "name": "Personal iPad",
              "osVersionNumber": "26.5"
            },
            "hardwareProperties": {
              "deviceType": "iPad",
              "marketingName": "iPad Pro",
              "platform": "iOS",
              "reality": "physical",
              "udid": "00008120-001234567890001E"
            }
          },
          {
            "identifier": "SIMULATOR",
            "connectionProperties": {
              "pairingState": "paired"
            },
            "deviceProperties": {
              "name": "iPhone Simulator",
              "osVersionNumber": "26.5"
            },
            "hardwareProperties": {
              "deviceType": "iPhone",
              "marketingName": "iPhone 16 Pro",
              "platform": "iOS",
              "reality": "simulator",
              "udid": "SIMULATOR-UDID"
            }
          }
        ]
      }
    }
    """
}
