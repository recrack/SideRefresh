import Foundation
import XCTest
@testable import SideRefreshCore

final class XcodeContainerScannerTests: XCTestCase {
    func testAutomaticScannerShowsOnlyIOSApplicationProjects() throws {
        let fixture = try Fixture()
        try fixture.createXcodeProject(
            "Projects/PhoneApp.xcodeproj",
            productType: "com.apple.product-type.application",
            sdkRoot: "iphoneos"
        )
        let macApp = try fixture.createXcodeProject(
            "Projects/MacTool.xcodeproj",
            productType: "com.apple.product-type.application",
            sdkRoot: "macosx"
        )
        try fixture.createXcodeProject(
            "Projects/SharedKit.xcodeproj",
            productType: "com.apple.product-type.framework",
            sdkRoot: "iphoneos"
        )

        let result = try XcodeContainerScanner().scan(
            rootURL: fixture.root
        )

        XCTAssertEqual(
            result.candidates.map(\.relativePath),
            ["Projects/PhoneApp.xcodeproj"]
        )
        XCTAssertNotNil(
            XcodeContainerScanner().candidate(
                for: macApp,
                relativeTo: fixture.root
            ),
            "Manual selection should still accept a valid Xcode container."
        )
    }

    func testAutomaticScannerSkipsLocationsAwaitingUserApproval()
        throws
    {
        let fixture = try Fixture()
        try fixture.createXcodeProject(
            "Projects/Visible.xcodeproj",
            productType: "com.apple.product-type.application",
            sdkRoot: "iphoneos"
        )
        try fixture.createXcodeProject(
            "Documents/Protected.xcodeproj",
            productType: "com.apple.product-type.application",
            sdkRoot: "iphoneos"
        )

        let result = try XcodeContainerScanner().scan(
            rootURL: fixture.root,
            excludingDirectoryURLs: [
                fixture.root.appendingPathComponent(
                    "Documents",
                    isDirectory: true
                ),
            ]
        )

        XCTAssertEqual(
            result.candidates.map(\.relativePath),
            ["Projects/Visible.xcodeproj"]
        )
        XCTAssertTrue(result.unreadableLocationURLs.isEmpty)
    }

    func testCandidateExposesTheIOSApplicationTargetName() throws {
        let fixture = try Fixture()
        try fixture.createXcodeProject(
            "Projects/InternalContainer.xcodeproj",
            productType: "com.apple.product-type.application",
            sdkRoot: "iphoneos",
            targetName: "Customer App"
        )

        let result = try XcodeContainerScanner().scan(
            rootURL: fixture.root
        )

        XCTAssertEqual(result.candidates.count, 1)
        XCTAssertEqual(
            result.candidates[0].applicationTargetNames,
            ["Customer App"]
        )
        XCTAssertEqual(
            result.candidates[0].displayName,
            "InternalContainer"
        )
        XCTAssertEqual(
            result.candidates[0].applicationDisplayNames,
            ["Customer App"]
        )
    }

    func testCandidateExposesTheInstalledApplicationDisplayName()
        throws
    {
        let fixture = try Fixture()
        try fixture.createXcodeProject(
            "Projects/InternalContainer.xcodeproj",
            targets: [
                .init(
                    name: "InternalTarget",
                    productType:
                        "com.apple.product-type.application",
                    sdkRoot: "iphoneos",
                    productName: "InternalBinary",
                    displayName: "고객용 앱",
                    bundleIdentifier: "com.example.customer",
                    developmentTeam: "ABCDE12345",
                    schemeName: "CustomerScheme",
                    appIconName: "AppIcon"
                ),
            ]
        )
        try fixture.createAppIcon(
            "Projects/InternalTarget/Assets.xcassets/AppIcon.appiconset"
        )

        let candidate = try XCTUnwrap(
            XcodeContainerScanner().scan(
                rootURL: fixture.root
            ).candidates.first
        )

        XCTAssertEqual(
            candidate.applicationDisplayNames,
            ["고객용 앱"]
        )
        XCTAssertEqual(
            candidate.applicationTargetNames,
            ["InternalTarget"]
        )
        XCTAssertEqual(candidate.applicationNameSummary, "고객용 앱")
        XCTAssertEqual(
            candidate.applicationBundleIdentifiersText,
            "com.example.customer"
        )
        XCTAssertEqual(
            candidate.applicationTargetNamesText,
            "InternalTarget"
        )
        let application = try XCTUnwrap(
            candidate.unambiguousApplication
        )
        XCTAssertEqual(application.productName, "InternalBinary")
        XCTAssertEqual(
            application.bundleIdentifier,
            "com.example.customer"
        )
        XCTAssertEqual(application.developmentTeam, "ABCDE12345")
        XCTAssertEqual(
            application.unambiguousSchemeName,
            "CustomerScheme"
        )
        XCTAssertEqual(
            application.iconURL?.lastPathComponent,
            "AppIcon-1024.png"
        )
    }

    func testSelectionUsesAlreadyDiscoveredApplicationMetadata()
        throws
    {
        let fixture = try Fixture()
        try fixture.createXcodeProject(
            "Projects/ReadyToUse.xcodeproj",
            targets: [
                .init(
                    name: "InternalTarget",
                    productType:
                        "com.apple.product-type.application",
                    sdkRoot: "iphoneos",
                    productName: "CustomerApp",
                    displayName: "고객용 앱",
                    bundleIdentifier: "com.example.customer",
                    developmentTeam: "ABCDE12345",
                    schemeName: "CustomerScheme",
                    releaseDisplayName: "고객용 앱",
                    releaseBundleIdentifier:
                        "com.example.customer",
                    releaseDevelopmentTeam: "ABCDE12345",
                    releaseMarketingVersion: "2.1",
                    releaseBuildVersion: "42"
                ),
            ]
        )
        let candidate = try XCTUnwrap(
            XcodeContainerScanner().scan(rootURL: fixture.root)
                .candidates.first
        )

        let selection = XcodeContainerSelection(candidate: candidate)

        XCTAssertEqual(selection.containerPath, candidate.id)
        XCTAssertEqual(selection.scheme, "CustomerScheme")
        XCTAssertEqual(selection.displayName, "고객용 앱")
        XCTAssertEqual(selection.productName, "CustomerApp")
        XCTAssertEqual(
            selection.bundleIdentifier,
            "com.example.customer"
        )
        XCTAssertEqual(selection.developmentTeam, "ABCDE12345")
        XCTAssertEqual(selection.marketingVersion, "2.1")
        XCTAssertEqual(selection.buildVersion, "42")
    }

    func testCandidateDoesNotGuessASchemeFromTheTargetName()
        throws
    {
        let fixture = try Fixture()
        try fixture.createIOSAppProject(
            "Projects/NoScheme/NoScheme.xcodeproj"
        )

        let application = try XCTUnwrap(
            XcodeContainerScanner().scan(rootURL: fixture.root)
                .candidates.first?.unambiguousApplication
        )

        XCTAssertTrue(application.schemeNames.isEmpty)
        XCTAssertNil(application.unambiguousSchemeName)
    }

    func testCandidateDoesNotChooseBetweenMultipleSchemes() throws {
        let fixture = try Fixture()
        try fixture.createXcodeProject(
            "Projects/ManySchemes/ManySchemes.xcodeproj",
            targets: [
                .init(
                    name: "Phone",
                    productType:
                        "com.apple.product-type.application",
                    sdkRoot: "iphoneos",
                    schemeName: "Consumer"
                ),
            ]
        )
        try fixture.createScheme(
            projectPath:
                "Projects/ManySchemes/ManySchemes.xcodeproj",
            name: "Internal",
            targetName: "Phone"
        )

        let application = try XCTUnwrap(
            XcodeContainerScanner().scan(rootURL: fixture.root)
                .candidates.first?.unambiguousApplication
        )

        XCTAssertEqual(
            application.schemeNames,
            ["Consumer", "Internal"]
        )
        XCTAssertNil(application.unambiguousSchemeName)
    }

    func testCandidatePrefillsValuesFromReleaseConfiguration()
        throws
    {
        let fixture = try Fixture()
        try fixture.createXcodeProject(
            "Projects/Configurations/App.xcodeproj",
            targets: [
                .init(
                    name: "App",
                    productType:
                        "com.apple.product-type.application",
                    sdkRoot: "iphoneos",
                    productName: "DebugApp",
                    displayName: "Debug 이름",
                    bundleIdentifier: "com.example.debug",
                    developmentTeam: "DEBUG12345",
                    schemeName: "App",
                    releaseProductName: "ReleaseApp",
                    releaseDisplayName: "출시 앱",
                    releaseBundleIdentifier: "com.example.release",
                    releaseDevelopmentTeam: "RELSE12345",
                    releaseMarketingVersion: "2.4.9",
                    releaseBuildVersion: "73"
                ),
            ]
        )

        let application = try XCTUnwrap(
            XcodeContainerScanner().scan(rootURL: fixture.root)
                .candidates.first?.unambiguousApplication
        )

        XCTAssertEqual(application.displayName, "출시 앱")
        XCTAssertEqual(application.productName, "ReleaseApp")
        XCTAssertEqual(
            application.bundleIdentifier,
            "com.example.release"
        )
        XCTAssertEqual(application.developmentTeam, "RELSE12345")
        XCTAssertEqual(application.marketingVersion, "2.4.9")
        XCTAssertEqual(application.buildVersion, "73")
    }

    func testCandidateReadsDisplayNameFromLegacyInfoPlist() throws {
        let fixture = try Fixture()
        try fixture.createInfoPlist(
            "Projects/Legacy/Info.plist",
            displayName: "설치되는 이름"
        )
        try fixture.createXcodeProject(
            "Projects/Legacy/Legacy.xcodeproj",
            targets: [
                .init(
                    name: "LegacyTarget",
                    productType:
                        "com.apple.product-type.application",
                    sdkRoot: "iphoneos",
                    productName: "LegacyBinary",
                    infoPlistFile: "Info.plist"
                ),
            ]
        )

        let candidate = try XCTUnwrap(
            XcodeContainerScanner().scan(
                rootURL: fixture.root
            ).candidates.first
        )

        XCTAssertEqual(
            candidate.applicationDisplayNames,
            ["설치되는 이름"]
        )
    }

    func testCandidateUsesSuppliedInfoPlistWhenGenerationIsDisabled()
        throws
    {
        let fixture = try Fixture()
        try fixture.createInfoPlist(
            "Projects/Flutter/Info.plist",
            displayName: "휴대폰에 보이는 이름"
        )
        try fixture.createXcodeProject(
            "Projects/Flutter/Runner.xcodeproj",
            targets: [
                .init(
                    name: "Runner",
                    productType:
                        "com.apple.product-type.application",
                    sdkRoot: "iphoneos",
                    productName: "Runner",
                    displayName: "적용되지 않는 설정",
                    infoPlistFile: "Info.plist",
                    generateInfoPlistFile: false
                ),
            ]
        )

        let application = try XCTUnwrap(
            XcodeContainerScanner().scan(rootURL: fixture.root)
                .candidates.first?.unambiguousApplication
        )

        XCTAssertEqual(application.displayName, "휴대폰에 보이는 이름")
        XCTAssertEqual(application.productName, "Runner")
    }

    func testCandidateDefaultsToSuppliedInfoPlistWithoutGenerationSetting()
        throws
    {
        let fixture = try Fixture()
        try fixture.createInfoPlist(
            "Projects/LegacyDefault/Info.plist",
            displayName: "기본 plist 이름"
        )
        try fixture.createXcodeProject(
            "Projects/LegacyDefault/App.xcodeproj",
            targets: [
                .init(
                    name: "App",
                    productType:
                        "com.apple.product-type.application",
                    sdkRoot: "iphoneos",
                    productName: "AppBinary",
                    displayName: "무시할 빌드 설정",
                    infoPlistFile: "Info.plist"
                ),
            ]
        )

        let application = try XCTUnwrap(
            XcodeContainerScanner().scan(rootURL: fixture.root)
                .candidates.first?.unambiguousApplication
        )

        XCTAssertEqual(application.displayName, "기본 plist 이름")
        XCTAssertEqual(application.productName, "AppBinary")
    }

    func testCandidateIgnoresGeneratedDisplayNameWhenGenerationIsDisabledWithoutAPlist()
        throws
    {
        let fixture = try Fixture()
        try fixture.createXcodeProject(
            "Projects/NoGeneratedPlist/App.xcodeproj",
            targets: [
                .init(
                    name: "InternalTarget",
                    productType:
                        "com.apple.product-type.application",
                    sdkRoot: "iphoneos",
                    productName: "InstalledProduct",
                    displayName: "적용되지 않는 설정",
                    generateInfoPlistFile: false
                ),
            ]
        )

        let application = try XCTUnwrap(
            XcodeContainerScanner().scan(rootURL: fixture.root)
                .candidates.first?.unambiguousApplication
        )

        XCTAssertEqual(application.displayName, "InstalledProduct")
    }

    func testCandidateDoesNotPresentContainerNameAsAnAppTarget()
        throws
    {
        let fixture = try Fixture()
        let macApp = try fixture.createXcodeProject(
            "Projects/InternalContainer.xcodeproj",
            productType: "com.apple.product-type.application",
            sdkRoot: "macosx"
        )

        let candidate = try XCTUnwrap(
            XcodeContainerScanner().candidate(
                for: macApp,
                relativeTo: fixture.root
            )
        )

        XCTAssertTrue(candidate.applicationTargetNames.isEmpty)
        XCTAssertEqual(
            candidate.applicationNameSummary,
            "설치 가능한 앱 미확인"
        )
        XCTAssertNotEqual(
            candidate.applicationNameSummary,
            candidate.displayName
        )
    }

    func testMixedPlatformProjectExposesOnlyIOSApplicationTargets()
        throws
    {
        let fixture = try Fixture()
        try fixture.createXcodeProject(
            "Projects/Products.xcodeproj",
            targets: [
                .init(
                    name: "Phone",
                    productType:
                        "com.apple.product-type.application",
                    sdkRoot: "iphoneos"
                ),
                .init(
                    name: "Desktop",
                    productType:
                        "com.apple.product-type.application",
                    sdkRoot: "macosx"
                ),
                .init(
                    name: "Television",
                    productType:
                        "com.apple.product-type.application",
                    sdkRoot: "appletvos"
                ),
            ]
        )

        let result = try XcodeContainerScanner().scan(
            rootURL: fixture.root
        )

        XCTAssertEqual(result.candidates.count, 1)
        XCTAssertEqual(
            result.candidates[0].applicationTargetNames,
            ["Phone"]
        )
    }

    func testIOSFrameworkDoesNotMakeMacApplicationAnIOSApp()
        throws
    {
        let fixture = try Fixture()
        try fixture.createXcodeProject(
            "Projects/MixedFrameworks.xcodeproj",
            targets: [
                .init(
                    name: "Desktop",
                    productType:
                        "com.apple.product-type.application",
                    sdkRoot: "macosx"
                ),
                .init(
                    name: "PhoneKit",
                    productType:
                        "com.apple.product-type.framework",
                    sdkRoot: "iphoneos"
                ),
            ]
        )

        let result = try XcodeContainerScanner().scan(
            rootURL: fixture.root
        )

        XCTAssertTrue(result.candidates.isEmpty)
    }

    func testCheckedInSampleExposesItsRealApplicationTargetName()
        throws
    {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let project = repositoryRoot.appendingPathComponent(
            "Examples/SideRefreshSampleApp/SideRefreshSample.xcodeproj"
        )

        let candidate = try XCTUnwrap(
            XcodeContainerScanner().discoveryCandidate(
                for: project,
                relativeTo: repositoryRoot
            )
        )

        XCTAssertEqual(
            candidate.applicationTargetNames,
            ["SideRefreshSample"]
        )
        XCTAssertEqual(
            candidate.unambiguousApplication?.marketingVersion,
            "1.0"
        )
        XCTAssertEqual(
            candidate.unambiguousApplication?.buildVersion,
            "1"
        )
    }

    func testScannerFindsNestedProjectsAndWorkspaces() throws {
        let fixture = try Fixture()
        try fixture.createIOSAppProject(
            "Projects/Native/MyApp.xcodeproj"
        )
        try fixture.createIOSAppProject(
            "Projects/Flutter/ios/Runner.xcodeproj"
        )
        try fixture.createWorkspace(
            "Projects/Flutter/ios/Runner.xcworkspace",
            projectLocation: "Runner.xcodeproj"
        )

        let result = try XcodeContainerScanner().scan(
            rootURL: fixture.root
        )

        XCTAssertEqual(
            Set(result.candidates.map(\.relativePath)),
            [
                "Projects/Native/MyApp.xcodeproj",
                "Projects/Flutter/ios/Runner.xcworkspace",
                "Projects/Flutter/ios/Runner.xcodeproj",
            ]
        )
        let candidatesByPath = Dictionary(
            uniqueKeysWithValues: result.candidates.map {
                ($0.relativePath, $0)
            }
        )
        let workspace = try XCTUnwrap(
            candidatesByPath[
                "Projects/Flutter/ios/Runner.xcworkspace"
            ]
        )
        let project = try XCTUnwrap(
            candidatesByPath[
                "Projects/Flutter/ios/Runner.xcodeproj"
            ]
        )
        XCTAssertEqual(workspace.applicationTargetNames, ["Runner"])
        XCTAssertTrue(workspace.referencesProject(project))
        let relationshipIndex = XcodeContainerRelationshipIndex(
            candidates: result.candidates
        )
        XCTAssertTrue(
            relationshipIndex.hasRelatedContainer(for: workspace)
        )
        XCTAssertTrue(
            relationshipIndex.hasRelatedContainer(for: project)
        )
        let unrelatedProject = try XCTUnwrap(
            candidatesByPath[
                "Projects/Native/MyApp.xcodeproj"
            ]
        )
        XCTAssertFalse(
            relationshipIndex.hasRelatedContainer(
                for: unrelatedProject
            )
        )
        XCTAssertEqual(
            relationshipIndex.preferredCandidates(
                from: result.candidates
            ).map(\.relativePath),
            [
                "Projects/Flutter/ios/Runner.xcworkspace",
                "Projects/Native/MyApp.xcodeproj",
            ]
        )
        XCTAssertEqual(
            relationshipIndex.preferredCandidateID(
                for: project.id
            ),
            workspace.id,
            "A saved project selection should resolve to its workspace row."
        )
        XCTAssertEqual(
            relationshipIndex.unambiguousPreferredCandidateID(
                for: project.id
            ),
            workspace.id
        )
    }

    func testCandidatesExposeTheLatestProjectFileModificationDate()
        throws
    {
        let fixture = try Fixture()
        let project = try fixture.createIOSAppProject(
            "Projects/Phone/Phone.xcodeproj"
        )
        let workspace = try fixture.createWorkspace(
            "Projects/Phone/Phone.xcworkspace",
            projectLocation: "Phone.xcodeproj"
        )
        let projectDate = Date(timeIntervalSince1970: 1_750_000_000)
        let workspaceDate = Date(timeIntervalSince1970: 1_800_000_000)
        try FileManager.default.setAttributes(
            [.modificationDate: projectDate],
            ofItemAtPath: project
                .appendingPathComponent("project.pbxproj").path
        )
        try FileManager.default.setAttributes(
            [.modificationDate: workspaceDate],
            ofItemAtPath: workspace
                .appendingPathComponent(
                    "contents.xcworkspacedata"
                ).path
        )

        let candidates = try XcodeContainerScanner().scan(
            rootURL: fixture.root
        ).candidates
        let projectCandidate = try XCTUnwrap(
            candidates.first { $0.kind == .project }
        )
        let workspaceCandidate = try XCTUnwrap(
            candidates.first { $0.kind == .workspace }
        )

        XCTAssertEqual(
            try XCTUnwrap(projectCandidate.projectFileModificationDate)
                .timeIntervalSince1970,
            projectDate.timeIntervalSince1970,
            accuracy: 1
        )
        XCTAssertEqual(
            try XCTUnwrap(workspaceCandidate.projectFileModificationDate)
                .timeIntervalSince1970,
            projectDate.timeIntervalSince1970,
            accuracy: 1,
            "The workspace row represents the referenced project too."
        )
    }

    func testRelationshipIndexKeepsAnAmbiguousMultiAppWorkspace()
        throws
    {
        let fixture = try Fixture()
        try fixture.createIOSAppProject(
            "Projects/Suite/Phone.xcodeproj"
        )
        try fixture.createIOSAppProject(
            "Projects/Suite/Companion.xcodeproj"
        )
        try fixture.createWorkspace(
            "Projects/Suite/Suite.xcworkspace",
            contents: """
            <?xml version="1.0" encoding="UTF-8"?>
            <Workspace version="1.0">
                <FileRef location="group:Phone.xcodeproj"/>
                <FileRef location="group:Companion.xcodeproj"/>
            </Workspace>
            """
        )

        let candidates = try XcodeContainerScanner().scan(
            rootURL: fixture.root
        ).candidates
        let relationshipIndex = XcodeContainerRelationshipIndex(
            candidates: candidates
        )
        let preferredCandidates = relationshipIndex.preferredCandidates(
            from: candidates
        )
        let workspace = try XCTUnwrap(
            candidates.first { $0.kind == .workspace }
        )

        XCTAssertEqual(
            Set(preferredCandidates.map(\.relativePath)),
            [
                "Projects/Suite/Companion.xcodeproj",
                "Projects/Suite/Phone.xcodeproj",
                "Projects/Suite/Suite.xcworkspace",
            ],
            "A workspace representing multiple apps is not the same app row."
        )
        XCTAssertFalse(
            relationshipIndex.hasRelatedContainer(for: workspace),
            "An umbrella workspace must not be presented as a preferred pair."
        )
    }

    func testRelationshipIndexIgnoresDuplicateProjectReferences()
        throws
    {
        let fixture = try Fixture()
        try fixture.createIOSAppProject(
            "Projects/Phone/Phone.xcodeproj"
        )
        try fixture.createWorkspace(
            "Projects/Phone/Phone.xcworkspace",
            contents: """
            <?xml version="1.0" encoding="UTF-8"?>
            <Workspace version="1.0">
                <FileRef location="group:Phone.xcodeproj"/>
                <FileRef location="group:Phone.xcodeproj"/>
            </Workspace>
            """
        )

        let candidates = try XcodeContainerScanner().scan(
            rootURL: fixture.root
        ).candidates
        let relationshipIndex = XcodeContainerRelationshipIndex(
            candidates: candidates
        )
        let project = try XCTUnwrap(
            candidates.first { $0.kind == .project }
        )
        let workspace = try XCTUnwrap(
            candidates.first { $0.kind == .workspace }
        )

        XCTAssertEqual(
            relationshipIndex.preferredCandidates(
                from: candidates
            ).map(\.id),
            [workspace.id]
        )
        XCTAssertEqual(
            relationshipIndex.preferredCandidateID(for: project.id),
            workspace.id
        )
    }

    func testRelationshipIndexKeepsTwoProjectsWithTheSameAppIdentity()
        throws
    {
        let fixture = try Fixture()
        let sharedTarget = Fixture.Target(
            name: "SharedApp",
            productType: "com.apple.product-type.application",
            sdkRoot: "iphoneos",
            productName: "SharedApp",
            bundleIdentifier: "com.example.shared"
        )
        try fixture.createXcodeProject(
            "Projects/Suite/Old.xcodeproj",
            targets: [sharedTarget]
        )
        try fixture.createXcodeProject(
            "Projects/Suite/New.xcodeproj",
            targets: [sharedTarget]
        )
        try fixture.createWorkspace(
            "Projects/Suite/Suite.xcworkspace",
            contents: """
            <?xml version="1.0" encoding="UTF-8"?>
            <Workspace version="1.0">
                <FileRef location="group:Old.xcodeproj"/>
                <FileRef location="group:New.xcodeproj"/>
            </Workspace>
            """
        )

        let candidates = try XcodeContainerScanner().scan(
            rootURL: fixture.root
        ).candidates
        let relationshipIndex = XcodeContainerRelationshipIndex(
            candidates: candidates
        )

        XCTAssertEqual(
            Set(
                relationshipIndex.preferredCandidates(
                    from: candidates
                ).map(\.relativePath)
            ),
            [
                "Projects/Suite/New.xcodeproj",
                "Projects/Suite/Old.xcodeproj",
                "Projects/Suite/Suite.xcworkspace",
            ],
            "One workspace cannot represent two distinct app projects."
        )
        XCTAssertFalse(
            candidates.contains {
                relationshipIndex.recommendsWorkspace(for: $0)
            }
        )
    }

    func testRelationshipIndexHidesOneProjectReferencedByTwoWorkspaces()
        throws
    {
        let fixture = try Fixture()
        try fixture.createIOSAppProject(
            "Projects/Phone/Phone.xcodeproj"
        )
        for workspaceName in ["Primary", "Secondary"] {
            try fixture.createWorkspace(
                "Projects/Phone/\(workspaceName).xcworkspace",
                contents: """
                <?xml version="1.0" encoding="UTF-8"?>
                <Workspace version="1.0">
                    <FileRef location="group:Phone.xcodeproj"/>
                </Workspace>
                """
            )
        }

        let candidates = try XcodeContainerScanner().scan(
            rootURL: fixture.root
        ).candidates
        let relationshipIndex = XcodeContainerRelationshipIndex(
            candidates: candidates
        )
        let project = try XCTUnwrap(
            candidates.first { $0.kind == .project }
        )
        let workspaceIDs = Set(
            candidates
                .filter { $0.kind == .workspace }
                .map(\.id)
        )

        XCTAssertEqual(
            Set(
                relationshipIndex.preferredCandidates(
                    from: candidates
                ).map(\.id)
            ),
            workspaceIDs,
            "Both distinct workspaces stay visible, but their shared project row is hidden."
        )
        XCTAssertEqual(
            relationshipIndex.preferredCandidateIDs(for: project.id),
            workspaceIDs,
            "Searching the hidden project should reveal both representative workspaces."
        )
        XCTAssertEqual(
            relationshipIndex.preferredCandidateID(for: project.id),
            project.id,
            "An ambiguous saved project must not silently choose one workspace."
        )
        XCTAssertNil(
            relationshipIndex.unambiguousPreferredCandidateID(
                for: project.id
            ),
            "The picker must require an explicit workspace choice."
        )
        XCTAssertTrue(
            candidates.allSatisfy {
                relationshipIndex.recommendsWorkspace(for: $0)
            }
        )
    }

    func testWorkspaceResolvesProjectsInsideNestedGroups() throws {
        let fixture = try Fixture()
        try fixture.createIOSAppProject(
            "Projects/Monorepo/Apps/Phone/Phone.xcodeproj"
        )
        try fixture.createWorkspace(
            "Projects/Monorepo/Main.xcworkspace",
            contents: """
            <?xml version="1.0" encoding="UTF-8"?>
            <Workspace version="1.0">
                <Group location="group:Apps" name="Apps">
                    <Group location="group:Phone" name="Phone">
                        <FileRef location="group:Phone.xcodeproj"/>
                    </Group>
                </Group>
            </Workspace>
            """
        )

        let result = try XcodeContainerScanner().scan(
            rootURL: fixture.root
        )
        let candidatesByPath = Dictionary(
            uniqueKeysWithValues: result.candidates.map {
                ($0.relativePath, $0)
            }
        )
        let workspace = try XCTUnwrap(
            candidatesByPath["Projects/Monorepo/Main.xcworkspace"]
        )
        let project = try XCTUnwrap(
            candidatesByPath[
                "Projects/Monorepo/Apps/Phone/Phone.xcodeproj"
            ]
        )

        XCTAssertEqual(workspace.applicationTargetNames, ["Phone"])
        XCTAssertTrue(workspace.referencesProject(project))
    }

    func testWorkspaceUsesASchemeStoredOnlyInTheWorkspace() throws {
        let fixture = try Fixture()
        try fixture.createXcodeProject(
            "Projects/App/App.xcodeproj",
            targets: [
                .init(
                    name: "Phone",
                    productType:
                        "com.apple.product-type.application",
                    sdkRoot: "iphoneos"
                ),
            ]
        )
        try fixture.createWorkspace(
            "Projects/App/App.xcworkspace",
            projectLocation: "App.xcodeproj"
        )
        try fixture.createScheme(
            projectPath: "Projects/App/App.xcworkspace",
            name: "WorkspacePhone",
            targetName: "Phone"
        )

        let workspace = try XCTUnwrap(
            XcodeContainerScanner().scan(rootURL: fixture.root)
                .candidates.first {
                    $0.kind == .workspace
                }
        )
        let application = try XCTUnwrap(
            workspace.unambiguousApplication
        )

        XCTAssertEqual(
            application.unambiguousSchemeName,
            "WorkspacePhone"
        )
    }

    func testScannerSkipsGeneratedAndPrivateTrees() throws {
        let fixture = try Fixture()
        try fixture.createIOSAppProject("Projects/App/App.xcodeproj")
        try fixture.createIOSAppProject(
            "Projects/App/node_modules/Dependency.xcodeproj"
        )
        try fixture.createIOSAppProject(
            "Projects/App/ios/Pods/Pods.xcodeproj"
        )
        try fixture.createIOSAppProject(
            "Library/Caches/Derived.xcodeproj"
        )
        try fixture.createIOSAppProject(
            ".hidden/Hidden.xcodeproj"
        )

        let result = try XcodeContainerScanner().scan(
            rootURL: fixture.root
        )

        XCTAssertEqual(
            result.candidates.map(\.relativePath),
            ["Projects/App/App.xcodeproj"]
        )
    }

    func testScannerHonorsResultLimit() throws {
        let fixture = try Fixture()
        try fixture.createIOSAppProject("Projects/A.xcodeproj")
        try fixture.createIOSAppProject("Projects/B.xcodeproj")

        let result = try XcodeContainerScanner().scan(
            rootURL: fixture.root,
            maximumResults: 1
        )

        XCTAssertEqual(result.candidates.count, 1)
        XCTAssertTrue(result.reachedResultLimit)
    }

    func testScannerPublishesSmallBatches() throws {
        let fixture = try Fixture()
        try fixture.createIOSAppProject("Projects/A.xcodeproj")
        try fixture.createIOSAppProject("Projects/B.xcodeproj")
        try fixture.createIOSAppProject("Projects/C.xcodeproj")
        var batchSizes: [Int] = []

        let result = try XcodeContainerScanner().scan(
            rootURL: fixture.root,
            batchSize: 2
        ) { batch in
            batchSizes.append(batch.count)
        }

        XCTAssertEqual(result.candidates.count, 3)
        XCTAssertEqual(batchSizes, [2, 1])
    }

    func testScannerThrowsWhenItsTaskIsCancelled() async throws {
        let fixture = try Fixture()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try XcodeContainerScanner().scan(
                rootURL: fixture.root
            )
        }

        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Expected.
        }
    }

    func testSpotlightCandidateRejectsWorkspaceInsideProjectPackage()
        throws
    {
        let fixture = try Fixture()
        let nestedWorkspace = try fixture.createDirectory(
            "Projects/App.xcodeproj/project.xcworkspace"
        )

        let candidate = XcodeContainerScanner().discoveryCandidate(
            for: nestedWorkspace,
            relativeTo: fixture.root
        )

        XCTAssertNil(candidate)
    }

    func testSpotlightCandidateRejectsNonIOSApplicationProject() throws {
        let fixture = try Fixture()
        let macApp = try fixture.createXcodeProject(
            "Projects/MacTool.xcodeproj",
            productType: "com.apple.product-type.application",
            sdkRoot: "macosx"
        )

        let candidate = XcodeContainerScanner().discoveryCandidate(
            for: macApp,
            relativeTo: fixture.root
        )

        XCTAssertNil(candidate)
    }

    func testScannerRejectsWorkspaceWithoutAnIOSApplicationProject()
        throws
    {
        let fixture = try Fixture()
        try fixture.createXcodeProject(
            "Projects/MacTool.xcodeproj",
            productType: "com.apple.product-type.application",
            sdkRoot: "macosx"
        )
        try fixture.createWorkspace(
            "Projects/Tools.xcworkspace",
            projectLocation: "MacTool.xcodeproj"
        )

        let result = try XcodeContainerScanner().scan(
            rootURL: fixture.root
        )

        XCTAssertTrue(result.candidates.isEmpty)
    }

    func testCandidateRejectsRegularFileWithProjectExtension() throws {
        let fixture = try Fixture()
        let fakeProject = fixture.root.appendingPathComponent(
            "NotAProject.xcodeproj"
        )
        XCTAssertTrue(
            FileManager.default.createFile(
                atPath: fakeProject.path,
                contents: Data()
            )
        )

        let candidate = XcodeContainerScanner().candidate(
            for: fakeProject,
            relativeTo: fixture.root
        )

        XCTAssertNil(candidate)
    }

    private final class Fixture {
        struct Target {
            let name: String
            let productType: String
            let sdkRoot: String
            let productName: String?
            let displayName: String?
            let infoPlistFile: String?
            let generateInfoPlistFile: Bool?
            let bundleIdentifier: String?
            let developmentTeam: String?
            let schemeName: String?
            let appIconName: String?
            let releaseProductName: String?
            let releaseDisplayName: String?
            let releaseBundleIdentifier: String?
            let releaseDevelopmentTeam: String?
            let releaseMarketingVersion: String?
            let releaseBuildVersion: String?

            init(
                name: String,
                productType: String,
                sdkRoot: String,
                productName: String? = nil,
                displayName: String? = nil,
                infoPlistFile: String? = nil,
                generateInfoPlistFile: Bool? = nil,
                bundleIdentifier: String? = nil,
                developmentTeam: String? = nil,
                schemeName: String? = nil,
                appIconName: String? = nil,
                releaseProductName: String? = nil,
                releaseDisplayName: String? = nil,
                releaseBundleIdentifier: String? = nil,
                releaseDevelopmentTeam: String? = nil,
                releaseMarketingVersion: String? = nil,
                releaseBuildVersion: String? = nil
            ) {
                self.name = name
                self.productType = productType
                self.sdkRoot = sdkRoot
                self.productName = productName
                self.displayName = displayName
                self.infoPlistFile = infoPlistFile
                self.generateInfoPlistFile = generateInfoPlistFile
                self.bundleIdentifier = bundleIdentifier
                self.developmentTeam = developmentTeam
                self.schemeName = schemeName
                self.appIconName = appIconName
                self.releaseProductName = releaseProductName
                self.releaseDisplayName = releaseDisplayName
                self.releaseBundleIdentifier =
                    releaseBundleIdentifier
                self.releaseDevelopmentTeam =
                    releaseDevelopmentTeam
                self.releaseMarketingVersion =
                    releaseMarketingVersion
                self.releaseBuildVersion = releaseBuildVersion
            }
        }

        let root: URL

        init() throws {
            root = FileManager.default.temporaryDirectory
                .appendingPathComponent(
                    UUID().uuidString,
                    isDirectory: true
                )
            try FileManager.default.createDirectory(
                at: root,
                withIntermediateDirectories: true
            )
        }

        @discardableResult
        func createDirectory(_ relativePath: String) throws -> URL {
            let url = root.appendingPathComponent(
                relativePath,
                isDirectory: true
            )
            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true
            )
            return url
        }

        func createInfoPlist(
            _ relativePath: String,
            displayName: String
        ) throws {
            let url = root.appendingPathComponent(relativePath)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try PropertyListSerialization.data(
                fromPropertyList: [
                    "CFBundleDisplayName": displayName,
                ],
                format: .xml,
                options: 0
            )
            try data.write(to: url)
        }

        func createAppIcon(_ relativePath: String) throws {
            let appIconSet = try createDirectory(relativePath)
            let iconURL = appIconSet.appendingPathComponent(
                "AppIcon-1024.png"
            )
            try Data(repeating: 0xA5, count: 64).write(to: iconURL)
            let contents = """
            {
              "images": [
                {
                  "filename": "AppIcon-1024.png",
                  "idiom": "ios-marketing",
                  "scale": "1x",
                  "size": "1024x1024"
                }
              ],
              "info": {
                "author": "xcode",
                "version": 1
              }
            }
            """
            try Data(contents.utf8).write(
                to: appIconSet.appendingPathComponent("Contents.json")
            )
        }

        @discardableResult
        func createXcodeProject(
            _ relativePath: String,
            productType: String,
            sdkRoot: String,
            targetName: String? = nil
        ) throws -> URL {
            try createXcodeProject(
                relativePath,
                targets: [
                    Target(
                        name: targetName
                            ?? URL(fileURLWithPath: relativePath)
                                .deletingPathExtension()
                                .lastPathComponent,
                        productType: productType,
                        sdkRoot: sdkRoot
                    ),
                ]
            )
        }

        @discardableResult
        func createXcodeProject(
            _ relativePath: String,
            targets: [Target]
        ) throws -> URL {
            let project = try createDirectory(relativePath)
            let projectFile = project.appendingPathComponent(
                "project.pbxproj"
            )
            let targetBlocks = targets.enumerated().map {
                index,
                target in
                let targetID = objectID(index + 1)
                let debugConfigurationID =
                    objectID(index + 1_001)
                let releaseConfigurationID =
                    objectID(index + 3_001)
                let configurationListID = objectID(index + 2_001)
                let productName = target.productName ?? target.name
                let displayNameSetting = target.displayName.map {
                    "INFOPLIST_KEY_CFBundleDisplayName = \"\($0)\";"
                } ?? ""
                let infoPlistSetting = target.infoPlistFile.map {
                    "INFOPLIST_FILE = \"\($0)\";"
                } ?? ""
                let generateInfoPlistSetting =
                    target.generateInfoPlistFile.map {
                        let value = $0 ? "YES" : "NO"
                        return "GENERATE_INFOPLIST_FILE = \(value);"
                    } ?? ""
                let bundleIdentifierSetting =
                    target.bundleIdentifier.map {
                        "PRODUCT_BUNDLE_IDENTIFIER = \"\($0)\";"
                    } ?? ""
                let developmentTeamSetting =
                    target.developmentTeam.map {
                        "DEVELOPMENT_TEAM = \"\($0)\";"
                    } ?? ""
                let appIconSetting = target.appIconName.map {
                    "ASSETCATALOG_COMPILER_APPICON_NAME = \"\($0)\";"
                } ?? ""
                let hasReleaseConfiguration =
                    target.releaseProductName != nil
                    || target.releaseDisplayName != nil
                    || target.releaseBundleIdentifier != nil
                    || target.releaseDevelopmentTeam != nil
                    || target.releaseMarketingVersion != nil
                    || target.releaseBuildVersion != nil
                let releaseProductName =
                    target.releaseProductName ?? productName
                let releaseDisplayNameSetting =
                    target.releaseDisplayName.map {
                        "INFOPLIST_KEY_CFBundleDisplayName = \"\($0)\";"
                    } ?? ""
                let releaseBundleIdentifierSetting =
                    target.releaseBundleIdentifier.map {
                        "PRODUCT_BUNDLE_IDENTIFIER = \"\($0)\";"
                    } ?? ""
                let releaseDevelopmentTeamSetting =
                    target.releaseDevelopmentTeam.map {
                        "DEVELOPMENT_TEAM = \"\($0)\";"
                    } ?? ""
                let releaseMarketingVersionSetting =
                    target.releaseMarketingVersion.map {
                        "MARKETING_VERSION = \"\($0)\";"
                    } ?? ""
                let releaseBuildVersionSetting =
                    target.releaseBuildVersion.map {
                        "CURRENT_PROJECT_VERSION = \"\($0)\";"
                    } ?? ""
                let releaseConfigurationBlock =
                    hasReleaseConfiguration
                    ? """
                    \(releaseConfigurationID) /* Release */ = {
                        isa = XCBuildConfiguration;
                        buildSettings = {
                            SDKROOT = \(target.sdkRoot);
                            PRODUCT_NAME = "\(releaseProductName)";
                            \(releaseDisplayNameSetting)
                            \(releaseBundleIdentifierSetting)
                            \(releaseDevelopmentTeamSetting)
                            \(releaseMarketingVersionSetting)
                            \(releaseBuildVersionSetting)
                        };
                        name = Release;
                    };
                    """
                    : ""
                let releaseConfigurationReference =
                    hasReleaseConfiguration
                    ? "\(releaseConfigurationID) /* Release */,"
                    : ""
                return """
                    \(targetID) /* \(target.name) */ = {
                        isa = PBXNativeTarget;
                        buildConfigurationList = \(configurationListID) /* Build configuration list for PBXNativeTarget "\(target.name)" */;
                        name = "\(target.name)";
                        productName = "\(productName)";
                        productType = "\(target.productType)";
                    };
                    \(debugConfigurationID) /* Debug */ = {
                        isa = XCBuildConfiguration;
                        buildSettings = {
                            SDKROOT = \(target.sdkRoot);
                            PRODUCT_NAME = "\(productName)";
                            \(displayNameSetting)
                            \(infoPlistSetting)
                            \(generateInfoPlistSetting)
                            \(bundleIdentifierSetting)
                            \(developmentTeamSetting)
                            \(appIconSetting)
                        };
                        name = Debug;
                    };
                    \(configurationListID) /* Build configuration list */ = {
                        isa = XCConfigurationList;
                        buildConfigurations = (
                            \(debugConfigurationID) /* Debug */,
                            \(releaseConfigurationReference)
                        );
                        defaultConfigurationName = Debug;
                    };
                    \(releaseConfigurationBlock)
                """
            }
            .joined(separator: "\n")
            let contents = """
            {
            \(targetBlocks)
            }
            """
            try Data(contents.utf8).write(to: projectFile)
            for target in targets {
                guard let schemeName = target.schemeName else {
                    continue
                }
                try createScheme(
                    projectPath: relativePath,
                    name: schemeName,
                    targetName: target.name
                )
            }
            return project
        }

        func createScheme(
            projectPath: String,
            name: String,
            targetName: String
        ) throws {
            let schemeDirectory = try createDirectory(
                "\(projectPath)/xcshareddata/xcschemes"
            )
            let scheme = """
            <?xml version="1.0" encoding="UTF-8"?>
            <Scheme version="1.7">
                <BuildableReference
                    BlueprintName = "\(targetName)">
                </BuildableReference>
            </Scheme>
            """
            try Data(scheme.utf8).write(
                to: schemeDirectory.appendingPathComponent(
                    "\(name).xcscheme"
                )
            )
        }

        @discardableResult
        func createIOSAppProject(_ relativePath: String) throws -> URL {
            try createXcodeProject(
                relativePath,
                productType: "com.apple.product-type.application",
                sdkRoot: "iphoneos"
            )
        }

        @discardableResult
        func createWorkspace(
            _ relativePath: String,
            projectLocation: String
        ) throws -> URL {
            try createWorkspace(
                relativePath,
                contents: """
                <?xml version="1.0" encoding="UTF-8"?>
                <Workspace version="1.0">
                    <FileRef location="group:\(projectLocation)"/>
                </Workspace>
                """
            )
        }

        @discardableResult
        func createWorkspace(
            _ relativePath: String,
            contents: String
        ) throws -> URL {
            let workspace = try createDirectory(relativePath)
            let contentsFile = workspace.appendingPathComponent(
                "contents.xcworkspacedata"
            )
            try Data(contents.utf8).write(to: contentsFile)
            return workspace
        }

        private func objectID(_ value: Int) -> String {
            String(format: "%024X", value)
        }

        deinit {
            try? FileManager.default.removeItem(at: root)
        }
    }
}
