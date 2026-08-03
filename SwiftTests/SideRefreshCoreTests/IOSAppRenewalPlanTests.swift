import Foundation
import XCTest
@testable import SideRefreshCore

final class IOSAppRenewalPlanTests: XCTestCase {
    func testPlanRejectsSamplePlaceholderSigningValues() throws {
        XCTAssertThrowsError(
            try IOSAppRenewalPlan(
                containerURL: URL(
                    fileURLWithPath:
                        "/examples/SideRefreshSample.xcodeproj"
                ),
                scheme: "SideRefreshSample",
                developmentTeam: "REPLACE_WITH_TEAM_ID",
                bundleIdentifier:
                    "io.github.siderefresh.sample.replace-me",
                productName: "SideRefreshSample",
                deviceIdentifier: "00008110-001234567890001E",
                derivedDataURL: URL(
                    fileURLWithPath: "/tmp/side-refresh-sample"
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? IOSAppRenewalPlanError,
                .placeholderValue("development team")
            )
        }
    }

    func testPlanBuildsAndInstallsAKnownXcodeProject() throws {
        let plan = try IOSAppRenewalPlan(
            containerURL: URL(
                fileURLWithPath: "/examples/SideRefreshSample.xcodeproj"
            ),
            scheme: "SideRefreshSample",
            configuration: "Release",
            developmentTeam: "ABCDE12345",
            bundleIdentifier: "io.github.siderefresh.sample",
            productName: "SideRefreshSample",
            deviceIdentifier: "00008110-001234567890001E",
            derivedDataURL: URL(fileURLWithPath: "/tmp/side-refresh-derived-data")
        )

        XCTAssertEqual(
            plan.appBundleURL.path,
            "/tmp/side-refresh-derived-data/Build/Products/Release-iphoneos/SideRefreshSample.app"
        )
        XCTAssertEqual(plan.buildCommand.executable, "/usr/bin/xcrun")
        XCTAssertEqual(
            plan.buildCommand.arguments,
            [
                "xcodebuild",
                "-project",
                "/examples/SideRefreshSample.xcodeproj",
                "-scheme",
                "SideRefreshSample",
                "-configuration",
                "Release",
                "-sdk",
                "iphoneos",
                "-destination",
                "platform=iOS,id=00008110-001234567890001E",
                "-destination-timeout",
                "120",
                "-derivedDataPath",
                "/tmp/side-refresh-derived-data",
                "-allowProvisioningUpdates",
                "-allowProvisioningDeviceRegistration",
                "DEVELOPMENT_TEAM=ABCDE12345",
                "build",
            ]
        )
        XCTAssertFalse(
            plan.buildCommand.arguments.contains {
                $0.hasPrefix("CONFIGURATION_BUILD_DIR=")
            },
            "Xcode의 기본 제품 디렉터리를 강제하면 CocoaPods 리소스 경로가 깨집니다."
        )
        XCTAssertEqual(plan.installCommand.executable, "/usr/bin/xcrun")
        XCTAssertEqual(
            plan.installCommand.arguments,
            [
                "devicectl",
                "device",
                "install",
                "app",
                "--device",
                "00008110-001234567890001E",
                "/tmp/side-refresh-derived-data/Build/Products/Release-iphoneos/SideRefreshSample.app",
                "--timeout",
                "120",
            ]
        )
    }

    func testPlanSupportsAnXcodeWorkspace() throws {
        let plan = try IOSAppRenewalPlan(
            containerURL: URL(fileURLWithPath: "/examples/App.xcworkspace"),
            scheme: "App",
            developmentTeam: "ABCDE12345",
            bundleIdentifier: "io.github.siderefresh.app",
            productName: "App",
            deviceIdentifier: "Personal iPhone",
            derivedDataURL: URL(fileURLWithPath: "/tmp/app-derived-data")
        )

        XCTAssertEqual(
            Array(plan.buildCommand.arguments.prefix(3)),
            ["xcodebuild", "-workspace", "/examples/App.xcworkspace"]
        )
    }

    func testCleanRebuildRunsXcodeCleanBeforeBuild() throws {
        let plan = try IOSAppRenewalPlan(
            containerURL: URL(
                fileURLWithPath: "/examples/App.xcodeproj"
            ),
            scheme: "App",
            developmentTeam: "ABCDE12345",
            bundleIdentifier: "io.github.siderefresh.app",
            productName: "App",
            deviceIdentifier: "Personal iPhone",
            derivedDataURL: URL(
                fileURLWithPath: "/tmp/app-derived-data"
            )
        )

        XCTAssertEqual(
            Array(
                plan.buildCommand(
                    for: .cleanRebuild
                ).arguments.suffix(2)
            ),
            ["clean", "build"]
        )
        XCTAssertEqual(
            plan.buildCommand(for: .incremental).arguments.last,
            "build"
        )
    }

    func testRenewalEvidenceIsInjectedWithoutChangingAppVersion() throws {
        let plan = try IOSAppRenewalPlan(
            containerURL: URL(fileURLWithPath: "/examples/App.xcodeproj"),
            scheme: "App",
            developmentTeam: "ABCDE12345",
            bundleIdentifier: "io.github.siderefresh.app",
            productName: "App",
            deviceIdentifier: "Personal iPhone",
            derivedDataURL: URL(
                fileURLWithPath: "/tmp/app-derived-data"
            )
        )
        let evidence = IOSAppRenewalEvidence(
            renewedAt: Date(timeIntervalSince1970: 0),
            uuid: UUID(
                uuidString: "12345678-90AB-CDEF-1234-567890ABCDEF"
            )!
        )

        let arguments = plan.buildCommand(
            for: .incremental,
            renewalEvidence: evidence
        ).arguments

        XCTAssertEqual(
            Array(arguments.suffix(3)),
            [
                "SIDEREFRESH_INSTALL_IDENTIFIER=SR-1234567890AB",
                "SIDEREFRESH_RENEWED_AT=1970-01-01T00:00:00Z",
                "build",
            ]
        )
        XCTAssertFalse(
            arguments.contains {
                $0.hasPrefix("MARKETING_VERSION=")
                    || $0.hasPrefix("CURRENT_PROJECT_VERSION=")
            }
        )
    }

    func testAutomaticVersionIsInjectedIntoTheXcodeBuild() throws {
        let plan = try IOSAppRenewalPlan(
            containerURL: URL(fileURLWithPath: "/examples/App.xcodeproj"),
            scheme: "App",
            developmentTeam: "ABCDE12345",
            bundleIdentifier: "io.github.siderefresh.app",
            productName: "App",
            deviceIdentifier: "Personal iPhone",
            derivedDataURL: URL(
                fileURLWithPath: "/tmp/app-derived-data"
            )
        )
        let nextVersion = try XCTUnwrap(
            IOSAppVersion(
                marketingVersion: "1.2.10",
                buildVersion: "46"
            )
        )

        let arguments = plan.buildCommand(
            for: .incremental,
            appVersionOverride: nextVersion
        ).arguments

        XCTAssertEqual(
            Array(arguments.suffix(3)),
            [
                "MARKETING_VERSION=1.2.10",
                "CURRENT_PROJECT_VERSION=46",
                "build",
            ]
        )
    }

    func testPlanRejectsUnsupportedContainers() {
        XCTAssertThrowsError(
            try IOSAppRenewalPlan(
                containerURL: URL(fileURLWithPath: "/examples/Package.swift"),
                scheme: "App",
                developmentTeam: "ABCDE12345",
                bundleIdentifier: "io.github.siderefresh.app",
                productName: "App",
                deviceIdentifier: "Personal iPhone",
                derivedDataURL: URL(fileURLWithPath: "/tmp/app-derived-data")
            )
        ) { error in
            XCTAssertEqual(
                error as? IOSAppRenewalPlanError,
                .unsupportedContainerExtension("swift")
            )
        }
    }

    func testPlanRejectsAnEmptyRequiredValue() {
        XCTAssertThrowsError(
            try IOSAppRenewalPlan(
                containerURL: URL(fileURLWithPath: "/examples/App.xcodeproj"),
                scheme: "",
                developmentTeam: "ABCDE12345",
                bundleIdentifier: "io.github.siderefresh.app",
                productName: "App",
                deviceIdentifier: "Personal iPhone",
                derivedDataURL: URL(fileURLWithPath: "/tmp/app-derived-data")
            )
        ) { error in
            XCTAssertEqual(
                error as? IOSAppRenewalPlanError,
                .emptyValue("scheme")
            )
        }
    }

    func testMissingDeviceIdentifierHasAUserFacingMessage() {
        XCTAssertThrowsError(
            try IOSAppRenewalPlan(
                containerURL: URL(
                    fileURLWithPath: "/examples/App.xcodeproj"
                ),
                scheme: "App",
                developmentTeam: "ABCDE12345",
                bundleIdentifier: "io.github.siderefresh.app",
                productName: "App",
                deviceIdentifier: "",
                derivedDataURL: URL(
                    fileURLWithPath: "/tmp/app-derived-data"
                )
            )
        ) { error in
            XCTAssertEqual(
                error.localizedDescription,
                "설치할 iPhone의 기기 식별자(UDID)가 비어 있습니다."
            )
        }
    }

    func testPlanRejectsANonFileContainerURL() {
        XCTAssertThrowsError(
            try IOSAppRenewalPlan(
                containerURL: URL(string: "https://example.com/App.xcodeproj")!,
                scheme: "App",
                developmentTeam: "ABCDE12345",
                bundleIdentifier: "io.github.siderefresh.app",
                productName: "App",
                deviceIdentifier: "Personal iPhone",
                derivedDataURL: URL(fileURLWithPath: "/tmp/app-derived-data")
            )
        ) { error in
            XCTAssertEqual(
                error as? IOSAppRenewalPlanError,
                .fileURLRequired("container")
            )
        }
    }

    func testPlanRejectsAnAppBundleWithTheWrongIdentifier() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let plan = try IOSAppRenewalPlan(
            containerURL: URL(fileURLWithPath: "/examples/App.xcodeproj"),
            scheme: "App",
            developmentTeam: "ABCDE12345",
            bundleIdentifier: "io.github.siderefresh.expected",
            productName: "App",
            deviceIdentifier: "00008110-001234567890001E",
            derivedDataURL: directory
        )
        try FileManager.default.createDirectory(
            at: plan.appBundleURL,
            withIntermediateDirectories: true
        )
        let plist = ["CFBundleIdentifier": "io.github.siderefresh.other"]
        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        try data.write(
            to: plan.appBundleURL.appendingPathComponent("Info.plist")
        )

        XCTAssertThrowsError(try plan.validateBuiltAppBundle()) { error in
            XCTAssertEqual(
                error as? IOSAppRenewalPlanError,
                .unexpectedBundleIdentifier(
                    expected: "io.github.siderefresh.expected",
                    actual: "io.github.siderefresh.other"
                )
            )
        }
    }

    func testPlanRemovesAStaleBundleAndAcceptsTheExpectedBuild() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let plan = try IOSAppRenewalPlan(
            containerURL: URL(fileURLWithPath: "/examples/App.xcodeproj"),
            scheme: "App",
            developmentTeam: "ABCDE12345",
            bundleIdentifier: "io.github.siderefresh.expected",
            productName: "App",
            deviceIdentifier: "00008110-001234567890001E",
            derivedDataURL: directory
        )
        let resolvedAppBundleURL = directory
            .appendingPathComponent("CustomProducts", isDirectory: true)
            .appendingPathComponent("Resolved.app", isDirectory: true)
        try FileManager.default.createDirectory(
            at: resolvedAppBundleURL,
            withIntermediateDirectories: true
        )
        try Data("stale".utf8).write(
            to: resolvedAppBundleURL.appendingPathComponent("marker")
        )

        XCTAssertEqual(
            try plan.removeExistingAppBundle(
                at: resolvedAppBundleURL
            ),
            .removed
        )

        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: resolvedAppBundleURL.path
            )
        )

        try FileManager.default.createDirectory(
            at: resolvedAppBundleURL,
            withIntermediateDirectories: true
        )
        let plist = [
            "CFBundleIdentifier": "io.github.siderefresh.expected",
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        try data.write(
            to: resolvedAppBundleURL.appendingPathComponent("Info.plist")
        )

        XCTAssertNoThrow(
            try plan.validateBuiltAppBundle(at: resolvedAppBundleURL)
        )
        XCTAssertEqual(
            plan.installCommand(
                appBundleURL: resolvedAppBundleURL
            ).arguments[6],
            resolvedAppBundleURL.path
        )
    }

    func testPlanDoesNotRemoveAnAppOutsideItsDerivedData() throws {
        let derivedDataURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let externalDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: derivedDataURL)
            try? FileManager.default.removeItem(at: externalDirectory)
        }
        let externalAppURL = externalDirectory.appendingPathComponent(
            "External.app",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: externalAppURL,
            withIntermediateDirectories: true
        )
        let plan = try IOSAppRenewalPlan(
            containerURL: URL(fileURLWithPath: "/examples/App.xcodeproj"),
            scheme: "App",
            developmentTeam: "ABCDE12345",
            bundleIdentifier: "io.github.siderefresh.expected",
            productName: "App",
            deviceIdentifier: "00008110-001234567890001E",
            derivedDataURL: derivedDataURL
        )

        XCTAssertEqual(
            try plan.removeExistingAppBundle(at: externalAppURL),
            .skippedOutsideDerivedData
        )

        XCTAssertTrue(
            FileManager.default.fileExists(atPath: externalAppURL.path)
        )
    }

    func testPlanDoesNotFollowADerivedDataSymlinkBeforeRemoval()
        throws
    {
        let derivedDataURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let externalDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: derivedDataURL)
            try? FileManager.default.removeItem(at: externalDirectory)
        }
        let externalAppURL = externalDirectory.appendingPathComponent(
            "External.app",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: externalAppURL,
            withIntermediateDirectories: true
        )
        let linkedAppURL = derivedDataURL.appendingPathComponent(
            "Build/Products/Release-iphoneos/Linked.app",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: linkedAppURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.createSymbolicLink(
            at: linkedAppURL,
            withDestinationURL: externalAppURL
        )
        let plan = try IOSAppRenewalPlan(
            containerURL: URL(fileURLWithPath: "/examples/App.xcodeproj"),
            scheme: "App",
            developmentTeam: "ABCDE12345",
            bundleIdentifier: "io.github.siderefresh.expected",
            productName: "App",
            deviceIdentifier: "00008110-001234567890001E",
            derivedDataURL: derivedDataURL
        )

        XCTAssertEqual(
            try plan.removeExistingAppBundle(at: linkedAppURL),
            .skippedOutsideDerivedData
        )

        XCTAssertTrue(
            FileManager.default.fileExists(atPath: externalAppURL.path)
        )
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: linkedAppURL.path)
        )
    }
}
