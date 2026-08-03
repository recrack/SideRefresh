import Foundation
import XCTest
@testable import SideRefreshCore

final class XcodeBuildSettingsReaderTests: XCTestCase {
    func testReaderUsesANonDeviceDestinationForDryRunResolution()
        throws
    {
        let executable = try makeExecutable(
            """
            #!/bin/sh
            destination=""
            while test "$#" -gt 0; do
                if test "$1" = "-destination"; then
                    shift
                    destination="$1"
                    break
                fi
                shift
            done
            test "$destination" = "generic/platform=iOS" || exit 41
            printf '%s' '[{"buildSettings":{"CURRENT_PROJECT_VERSION":"73","MARKETING_VERSION":"5.0","PRODUCT_BUNDLE_IDENTIFIER":"com.example.app"}}]'
            """
        )

        let version = try XcodeBuildSettingsReader().read(
            plan: makePlan(),
            destination: .genericIOS,
            xcrunURL: executable
        )

        XCTAssertEqual(
            version,
            IOSAppVersion(
                marketingVersion: "5.0",
                buildVersion: "73"
            )
        )
    }

    func testVersionQueryDoesNotRequireATeamOrSelectedDevice() throws {
        let executable = try makeExecutable(
            """
            #!/bin/sh
            arguments="$*"
            case "$arguments" in
              *"-destination generic/platform=iOS"*) ;;
              *) exit 44 ;;
            esac
            case "$arguments" in
              *"DEVELOPMENT_TEAM="*) exit 45 ;;
            esac
            printf '%s' '[{"buildSettings":{"CURRENT_PROJECT_VERSION":"1","MARKETING_VERSION":"1.0.0","PRODUCT_BUNDLE_IDENTIFIER":"com.example.app"}}]'
            """
        )
        let query = XcodeBuildSettingsQuery(
            containerURL: URL(
                fileURLWithPath: "/Projects/App.xcodeproj"
            ),
            scheme: "App",
            configuration: "Release",
            bundleIdentifier: "com.example.app",
            derivedDataURL: URL(
                fileURLWithPath: "/tmp/app-derived-data"
            )
        )

        XCTAssertEqual(
            try XcodeBuildSettingsReader().read(
                query: query,
                xcrunURL: executable
            ),
            IOSAppVersion(
                marketingVersion: "1.0.0",
                buildVersion: "1"
            )
        )
    }

    func testReaderReportsAnXcodeProcessFailure() throws {
        let executable = try makeExecutable(
            """
            #!/bin/sh
            printf '%s' 'settings unavailable' >&2
            exit 17
            """
        )

        XCTAssertThrowsError(
            try XcodeBuildSettingsReader().read(
                plan: makePlan(),
                xcrunURL: executable
            )
        ) { error in
            XCTAssertEqual(
                error as? XcodeBuildSettingsReaderError,
                .commandFailed(17, "settings unavailable")
            )
        }
    }

    func testParsesTheSelectedAppsResolvedVersion() throws {
        let data = Data(
            """
            [
              {
                "action": "build",
                "buildSettings": {
                  "CURRENT_PROJECT_VERSION": "8",
                  "MARKETING_VERSION": "2.4.1",
                  "PRODUCT_BUNDLE_IDENTIFIER": "com.example.widget"
                },
                "target": "Widget"
              },
              {
                "action": "build",
                "buildSettings": {
                  "CURRENT_PROJECT_VERSION": "73",
                  "MARKETING_VERSION": "5.0",
                  "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app"
                },
                "target": "App"
              }
            ]
            """.utf8
        )

        XCTAssertEqual(
            try XcodeBuildSettingsReader.parse(
                data,
                bundleIdentifier: "com.example.app"
            ),
            IOSAppVersion(
                marketingVersion: "5.0",
                buildVersion: "73"
            )
        )
    }

    func testResolvesTheSelectedAppsActualBuildProductPath() throws {
        let data = Data(
            """
            [
              {
                "buildSettings": {
                  "FULL_PRODUCT_NAME": "Custom Runner.app",
                  "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app",
                  "TARGET_BUILD_DIR": "/tmp/custom-products/iphoneos"
                },
                "target": "App"
              }
            ]
            """.utf8
        )

        XCTAssertEqual(
            try XcodeBuildSettingsReader.parseAppBundleURL(
                data,
                bundleIdentifier: "com.example.app"
            ).path,
            "/tmp/custom-products/iphoneos/Custom Runner.app"
        )
    }

    func testProductReaderUsesSideRefreshDerivedDataAndTeam() throws {
        let executable = try makeExecutable(
            """
            #!/bin/sh
            arguments="$*"
            case "$arguments" in
              *"-derivedDataPath /tmp/app-derived-data"*) ;;
              *) exit 42 ;;
            esac
            case "$arguments" in
              *"DEVELOPMENT_TEAM=ABCDE12345"*) ;;
              *) exit 43 ;;
            esac
            case "$arguments" in
              *"SIDEREFRESH_INSTALL_IDENTIFIER=SR-1234567890AB"*) ;;
              *) exit 45 ;;
            esac
            case "$arguments" in
              *"MARKETING_VERSION=5.1"*) ;;
              *) exit 46 ;;
            esac
            printf '%s' '[{"buildSettings":{"FULL_PRODUCT_NAME":"Resolved.app","PRODUCT_BUNDLE_IDENTIFIER":"com.example.app","TARGET_BUILD_DIR":"/tmp/resolved-products"}}]'
            """
        )
        let plan = try makePlan()
        let evidence = IOSAppRenewalEvidence(
            renewedAt: Date(timeIntervalSince1970: 0),
            uuid: UUID(
                uuidString: "12345678-90AB-CDEF-1234-567890ABCDEF"
            )!
        )
        let version = try XCTUnwrap(
            IOSAppVersion(
                marketingVersion: "5.1",
                buildVersion: "74"
            )
        )

        let appBundleURL = try XcodeBuildSettingsReader()
            .readAppBundleURL(
                plan: plan,
                buildSettingOverrides: plan.buildSettingOverrides(
                    renewalEvidence: evidence,
                    appVersionOverride: version
                ),
                xcrunURL: executable
            )

        XCTAssertEqual(
            appBundleURL.path,
            "/tmp/resolved-products/Resolved.app"
        )
    }

    func testProductReaderCanResolveWithoutASelectedDevice() throws {
        let executable = try makeExecutable(
            """
            #!/bin/sh
            arguments="$*"
            case "$arguments" in
              *"-destination generic/platform=iOS"*) ;;
              *) exit 44 ;;
            esac
            printf '%s' '[{"buildSettings":{"FULL_PRODUCT_NAME":"Resolved.app","PRODUCT_BUNDLE_IDENTIFIER":"com.example.app","TARGET_BUILD_DIR":"/tmp/resolved-products"}}]'
            """
        )

        let appBundleURL = try XcodeBuildSettingsReader()
            .readAppBundleURL(
                plan: makePlan(),
                destination: .genericIOS,
                xcrunURL: executable
            )

        XCTAssertEqual(
            appBundleURL.path,
            "/tmp/resolved-products/Resolved.app"
        )
    }

    func testRejectsAnUnresolvedBuildProductPath() {
        let data = Data(
            """
            [{"buildSettings":{
              "FULL_PRODUCT_NAME":"$(PRODUCT_NAME).app",
              "PRODUCT_BUNDLE_IDENTIFIER":"com.example.app",
              "TARGET_BUILD_DIR":"$(BUILD_DIR)/Products"
            }}]
            """.utf8
        )

        XCTAssertThrowsError(
            try XcodeBuildSettingsReader.parseAppBundleURL(
                data,
                bundleIdentifier: "com.example.app"
            )
        ) { error in
            XCTAssertEqual(
                error as? XcodeBuildSettingsReaderError,
                .invalidAppBundlePath(
                    targetBuildDirectory: "$(BUILD_DIR)/Products",
                    fullProductName: "$(PRODUCT_NAME).app"
                )
            )
        }
    }

    func testRejectsAnUnresolvedOrMissingAppVersion() {
        let data = Data(
            """
            [
              {
                "buildSettings": {
                  "CURRENT_PROJECT_VERSION": "$(BUILD_NUMBER)",
                  "MARKETING_VERSION": "1.0",
                  "PRODUCT_BUNDLE_IDENTIFIER": "com.example.app"
                },
                "target": "App"
              }
            ]
            """.utf8
        )

        XCTAssertThrowsError(
            try XcodeBuildSettingsReader.parse(
                data,
                bundleIdentifier: "com.example.app"
            )
        ) { error in
            XCTAssertEqual(
                error as? XcodeBuildSettingsReaderError,
                .invalidVersion(
                    marketingVersion: "1.0",
                    buildVersion: "$(BUILD_NUMBER)"
                )
            )
        }
    }

    private func makePlan() throws -> IOSAppRenewalPlan {
        try IOSAppRenewalPlan(
            containerURL: URL(
                fileURLWithPath: "/Projects/App.xcodeproj"
            ),
            scheme: "App",
            configuration: "Release",
            developmentTeam: "ABCDE12345",
            bundleIdentifier: "com.example.app",
            productName: "App",
            deviceIdentifier: "00008110-001234567890001E",
            derivedDataURL: URL(
                fileURLWithPath: "/tmp/app-derived-data"
            )
        )
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
