import Foundation
import XCTest
@testable import SideRefreshCore

final class IOSAppRenewalProfileTests: XCTestCase {
    func testProfileCreatesTheExplicitHelperCommand() throws {
        let profile = try makeProfile(mode: .execute)

        let command = profile.command(
            helperExecutableURL: URL(
                fileURLWithPath: "/Applications/SideRefresh/SideRefreshIOSRenewal"
            )
        )

        XCTAssertEqual(
            command.executable,
            "/Applications/SideRefresh/SideRefreshIOSRenewal"
        )
        XCTAssertEqual(
            command.arguments,
            [
                "--execute",
                "--build-strategy",
                "incremental",
                "--version-policy",
                "keep",
                "--container",
                "/Projects/MyApp.xcodeproj",
                "--scheme",
                "MyApp",
                "--configuration",
                "Release",
                "--team",
                "ABCDE12345",
                "--bundle-id",
                "com.example.my-app",
                "--product",
                "MyApp",
                "--device",
                "00008110-001234567890001E",
                "--derived-data",
                "/tmp/my-app-derived-data",
            ]
        )
    }

    func testProfileRoundTripsThroughHelperArguments() throws {
        let expected = try makeProfile(
            mode: .dryRun,
            buildStrategy: .cleanRebuild,
            versionPolicy: .automatic,
            sourceAppVersion: IOSAppVersion(
                marketingVersion: "1.2.3",
                buildVersion: "45"
            )
        )

        let parsed = try IOSAppRenewalProfile(
            arguments: expected.arguments
        )

        XCTAssertEqual(parsed, expected)
    }

    func testProfileRoundTripsUserFacingDisplayName() throws {
        let expected = try IOSAppRenewalProfile(
            mode: .execute,
            displayName: "고객용 앱",
            plan: IOSAppRenewalPlan(
                containerURL: URL(
                    fileURLWithPath: "/Projects/Runner.xcodeproj"
                ),
                scheme: "Runner",
                developmentTeam: "ABCDE12345",
                bundleIdentifier: "com.example.customer",
                productName: "Runner",
                deviceIdentifier: "device",
                derivedDataURL: URL(
                    fileURLWithPath: "/tmp/customer-derived-data"
                )
            )
        )

        let parsed = try IOSAppRenewalProfile(
            arguments: expected.arguments
        )

        XCTAssertEqual(parsed.displayName, "고객용 앱")
        XCTAssertEqual(parsed.plan.productName, "Runner")
        XCTAssertEqual(parsed, expected)
    }

    func testLegacyProfileDefaultsToKeepingTheCurrentVersion() throws {
        let arguments = try makeProfile(
            mode: .execute,
            versionPolicy: .automatic,
            sourceAppVersion: IOSAppVersion(
                marketingVersion: "1.2",
                buildVersion: "4"
            )
        ).arguments
        var legacyArguments = arguments
        for option in [
            "--version-policy",
            "--source-marketing-version",
            "--source-build-version",
        ] {
            let index = try XCTUnwrap(
                legacyArguments.firstIndex(of: option)
            )
            legacyArguments.removeSubrange(index...(index + 1))
        }

        let parsed = try IOSAppRenewalProfile(
            arguments: legacyArguments
        )

        XCTAssertEqual(parsed.versionPolicy, .keep)
        XCTAssertNil(parsed.sourceAppVersion)
    }

    func testAutomaticProfileCanResolveItsVersionAtRunTime() throws {
        let profile = try makeProfile(
            mode: .execute,
            versionPolicy: .automatic
        )

        let parsed = try IOSAppRenewalProfile(
            arguments: profile.arguments
        )

        XCTAssertEqual(parsed.versionPolicy, .automatic)
        XCTAssertNil(parsed.sourceAppVersion)
        XCTAssertFalse(
            parsed.arguments.contains("--source-marketing-version")
        )
    }

    func testLegacyProfileDefaultsToIncrementalBuilds() throws {
        let arguments = try makeProfile(
            mode: .execute,
            buildStrategy: .cleanRebuild
        ).arguments
        let strategyIndex = try XCTUnwrap(
            arguments.firstIndex(of: "--build-strategy")
        )
        var legacyArguments = arguments
        legacyArguments.removeSubrange(
            strategyIndex...(strategyIndex + 1)
        )

        let parsed = try IOSAppRenewalProfile(
            arguments: legacyArguments
        )

        XCTAssertEqual(parsed.buildStrategy, .incremental)
    }

    func testProfileRejectsAnUnknownBuildStrategy() throws {
        var arguments = try makeProfile(
            mode: .execute
        ).arguments
        let strategyIndex = try XCTUnwrap(
            arguments.firstIndex(of: "--build-strategy")
        )
        arguments[strategyIndex + 1] = "cached-resign"

        XCTAssertThrowsError(
            try IOSAppRenewalProfile(arguments: arguments)
        ) { error in
            XCTAssertEqual(
                error as? IOSAppRenewalProfileError,
                .invalidValue(
                    option: "--build-strategy",
                    value: "cached-resign"
                )
            )
        }
    }

    func testProfileRejectsAnUnknownVersionPolicy() throws {
        var arguments = try makeProfile(mode: .execute).arguments
        let policyIndex = try XCTUnwrap(
            arguments.firstIndex(of: "--version-policy")
        )
        arguments[policyIndex + 1] = "major"

        XCTAssertThrowsError(
            try IOSAppRenewalProfile(arguments: arguments)
        ) { error in
            XCTAssertEqual(
                error as? IOSAppRenewalProfileError,
                .invalidValue(
                    option: "--version-policy",
                    value: "major"
                )
            )
        }
    }

    func testProfileRejectsDuplicateTargetFields() throws {
        let profile = try makeProfile(mode: .execute)
        let duplicateArguments = profile.arguments + ["--scheme", "OtherApp"]

        XCTAssertThrowsError(
            try IOSAppRenewalProfile(arguments: duplicateArguments)
        ) { error in
            XCTAssertEqual(
                error as? IOSAppRenewalProfileError,
                .duplicateOption("--scheme")
            )
        }
    }

    private func makeProfile(
        mode: IOSAppRenewalMode,
        buildStrategy: IOSAppBuildStrategy = .incremental,
        versionPolicy: IOSAppVersionPolicy = .keep,
        sourceAppVersion: IOSAppVersion? = nil
    ) throws -> IOSAppRenewalProfile {
        try IOSAppRenewalProfile(
            mode: mode,
            buildStrategy: buildStrategy,
            versionPolicy: versionPolicy,
            sourceAppVersion: sourceAppVersion,
            plan: IOSAppRenewalPlan(
                containerURL: URL(
                    fileURLWithPath: "/Projects/MyApp.xcodeproj"
                ),
                scheme: "MyApp",
                configuration: "Release",
                developmentTeam: "ABCDE12345",
                bundleIdentifier: "com.example.my-app",
                productName: "MyApp",
                deviceIdentifier: "00008110-001234567890001E",
                derivedDataURL: URL(
                    fileURLWithPath: "/tmp/my-app-derived-data"
                )
            )
        )
    }

    func testProfileRecognitionRequiresTheBundledHelperIdentity() throws {
        let profile = try makeProfile()
        let helperURL = URL(
            fileURLWithPath: "/Applications/SideRefresh.app/helper"
        )

        XCTAssertNotNil(
            IOSAppRenewalProfile.recognized(
                in: profile.command(helperExecutableURL: helperURL),
                bundledHelperURL: helperURL
            )
        )
        XCTAssertNil(
            IOSAppRenewalProfile.recognized(
                in: profile.command(
                    helperExecutableURL: URL(
                        fileURLWithPath: "/tmp/untrusted-command"
                    )
                ),
                bundledHelperURL: helperURL
            )
        )
        XCTAssertFalse(
            IOSAppRenewalProfile.usesBundledHelper(
                executableURL: URL(
                    fileURLWithPath: "/tmp/untrusted-command"
                ),
                bundledHelperURL: helperURL
            )
        )
    }

    private func makeProfile() throws -> IOSAppRenewalProfile {
        IOSAppRenewalProfile(
            mode: .dryRun,
            plan: try IOSAppRenewalPlan(
                containerURL: URL(
                    fileURLWithPath: "/tmp/Sample.xcodeproj"
                ),
                scheme: "Sample",
                developmentTeam: "ABCDE12345",
                bundleIdentifier: "example.Sample",
                productName: "Sample",
                deviceIdentifier: "device",
                derivedDataURL: URL(
                    fileURLWithPath: "/tmp/SampleDerivedData"
                )
            )
        )
    }
}
