import Foundation
import XCTest
@testable import SideRefreshCore

final class DeviceProvisioningProfileReaderTests: XCTestCase {
    func testReadFallsBackFromUSBToNetworkAndParsesProfiles() throws {
        let directory = try makeTemporaryDirectory()
        let markerURL = directory.appendingPathComponent("calls.txt")
        let ideviceprovisionURL = try makeExecutable(
            named: "ideviceprovision",
            in: directory,
            script: """
            #!/bin/sh
            destination=""
            uses_network=0
            for argument in "$@"; do
                destination="$argument"
                if test "$argument" = "--network"; then
                    uses_network=1
                fi
            done
            if test "$uses_network" = "0"; then
                printf '%s\\n' usb >> '\(markerURL.path)'
                printf '%s' 'USB service unavailable' >&2
                exit 17
            fi
            printf '%s\\n' network >> '\(markerURL.path)'
            : > "$destination/PROFILE-UUID.mobileprovision"
            """
        )
        let securityURL = try makeExecutable(
            named: "security",
            in: directory,
            script: """
            #!/bin/sh
            /usr/bin/printf '%s' '\(Self.profilePayload)'
            """
        )
        let reader = DeviceProvisioningProfileReader(
            profileReader: ProvisioningProfileReader(
                securityExecutableURL: securityURL
            )
        )

        let profiles = try reader.readWithUSBThenNetwork(
            deviceIdentifier: "00008110-TEST",
            ideviceprovisionURL: ideviceprovisionURL
        )

        XCTAssertEqual(
            try String(contentsOf: markerURL, encoding: .utf8),
            "usb\nnetwork\n"
        )
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.identifier, "PROFILE-UUID")
        XCTAssertEqual(
            profiles.first?.applicationIdentifier,
            "TEAM123.com.example.app"
        )
    }

    func testReadRejectsMoreThanTheSafetyLimit() throws {
        let directory = try makeTemporaryDirectory()
        let ideviceprovisionURL = try makeExecutable(
            named: "ideviceprovision",
            in: directory,
            script: """
            #!/bin/sh
            destination=""
            for argument in "$@"; do
                destination="$argument"
            done
            index=0
            while test "$index" -le 200; do
                : > "$destination/$index.mobileprovision"
                index=$((index + 1))
            done
            """
        )

        XCTAssertThrowsError(
            try DeviceProvisioningProfileReader().read(
                deviceIdentifier: "00008110-TEST",
                ideviceprovisionURL: ideviceprovisionURL,
                usesNetwork: false
            )
        ) { error in
            XCTAssertEqual(
                error as? DeviceProvisioningProfileReaderError,
                .tooManyProfiles
            )
        }
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: false
        )
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return directory
    }

    private func makeExecutable(
        named name: String,
        in directory: URL,
        script: String
    ) throws -> URL {
        let executableURL = directory.appendingPathComponent(name)
        try Data(script.utf8).write(to: executableURL)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: executableURL.path
        )
        return executableURL
    }

    private static let profilePayload = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" \
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>UUID</key>
        <string>PROFILE-UUID</string>
        <key>Name</key>
        <string>iOS Team Provisioning Profile</string>
        <key>ExpirationDate</key>
        <date>2026-08-01T00:00:00Z</date>
        <key>Entitlements</key>
        <dict>
            <key>application-identifier</key>
            <string>TEAM123.com.example.app</string>
        </dict>
    </dict>
    </plist>
    """
}
