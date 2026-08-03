import Foundation

public enum XcodeContainerKind: String, Sendable {
    case project
    case workspace

    public var label: String {
        switch self {
        case .project:
            return "Project"
        case .workspace:
            return "Workspace"
        }
    }

    public var localizedLabel: String {
        switch self {
        case .project:
            return "프로젝트"
        case .workspace:
            return "워크스페이스"
        }
    }
}

public struct XcodeApplicationTargetInfo:
    Equatable,
    Hashable,
    Sendable
{
    public let targetName: String
    public let displayName: String
    public let productName: String
    public let bundleIdentifier: String?
    public let developmentTeam: String?
    public let marketingVersion: String?
    public let buildVersion: String?
    public let schemeNames: [String]
    public let iconURL: URL?

    public var unambiguousSchemeName: String? {
        schemeNames.count == 1 ? schemeNames[0] : nil
    }
}

public struct XcodeContainerCandidate: Identifiable, Equatable, Sendable {
    public let url: URL
    public let rootURL: URL
    public let kind: XcodeContainerKind
    public let applications: [XcodeApplicationTargetInfo]
    public let referencedProjectPaths: [String]
    public let projectFileModificationDate: Date?

    public var id: String {
        url.standardizedFileURL.path
    }

    public var displayName: String {
        url.deletingPathExtension().lastPathComponent
    }

    public var applicationTargetNames: [String] {
        applications.map(\.targetName)
    }

    public var applicationDisplayNames: [String] {
        applications.map(\.displayName)
    }

    public var applicationBundleIdentifiers: [String] {
        applications.compactMap(\.bundleIdentifier)
    }

    public var applicationIconURL: URL? {
        applications.compactMap(\.iconURL).first
    }

    public var unambiguousApplication: XcodeApplicationTargetInfo? {
        applications.count == 1 ? applications[0] : nil
    }

    public var applicationNameSummary: String {
        guard let firstName = namesShownToUser.first else {
            return "설치 가능한 앱 미확인"
        }
        guard namesShownToUser.count > 1 else {
            return firstName
        }
        return "\(firstName) 외 \(namesShownToUser.count - 1)개"
    }

    public var applicationNamesText: String {
        namesShownToUser.isEmpty
            ? "설치 가능한 앱 미확인"
            : namesShownToUser.joined(separator: ", ")
    }

    public var applicationTargetNamesText: String {
        applicationTargetNames.isEmpty
            ? "Xcode 대상 미확인"
            : applicationTargetNames.joined(separator: ", ")
    }

    public var applicationBundleIdentifiersText: String {
        applicationBundleIdentifiers.isEmpty
            ? "앱 식별자 미확인"
            : applicationBundleIdentifiers.joined(separator: ", ")
    }

    public var relativePath: String {
        let rootPath = rootURL.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        guard path.hasPrefix(rootPath + "/") else {
            return path
        }
        return String(path.dropFirst(rootPath.count + 1))
    }

    public func referencesProject(
        _ candidate: XcodeContainerCandidate
    ) -> Bool {
        candidate.kind == .project
            && referencedProjectPaths.contains(candidate.id)
    }

    private var namesShownToUser: [String] {
        applicationDisplayNames.isEmpty
            ? applicationTargetNames
            : applicationDisplayNames
    }
}

public struct XcodeContainerScanResult: Equatable, Sendable {
    public let candidates: [XcodeContainerCandidate]
    public let unreadableLocationCount: Int
    public let unreadableLocationURLs: [URL]
    public let reachedResultLimit: Bool

    public init(
        candidates: [XcodeContainerCandidate],
        unreadableLocationCount: Int,
        unreadableLocationURLs: [URL] = [],
        reachedResultLimit: Bool
    ) {
        self.candidates = candidates
        self.unreadableLocationCount = unreadableLocationCount
        self.unreadableLocationURLs = unreadableLocationURLs
        self.reachedResultLimit = reachedResultLimit
    }
}

public struct XcodeContainerScanner: Sendable {
    private static let applicationProductType =
        "com.apple.product-type.application"
    private static let maximumProjectFileSize = 32 * 1_024 * 1_024
    private static let maximumWorkspaceFileSize = 2 * 1_024 * 1_024
    private static let maximumInfoPlistSize = 2 * 1_024 * 1_024
    private static let maximumAssetContentsFileSize =
        1 * 1_024 * 1_024
    private static let maximumIconSearchEntries = 400
    private static let maximumIconSearchDepth = 4
    private static let maximumUnreadableLocationCount = 50
    private static let ignoredDirectoryNames: Set<String> = [
        ".build",
        ".dart_tool",
        ".git",
        ".gradle",
        ".swiftpm",
        ".trash",
        "build",
        "deriveddata",
        "library",
        "node_modules",
        "pods",
    ]

    public init() {}

    public func scan(
        rootURL: URL,
        maximumResults: Int = 200,
        batchSize: Int = 20,
        excludingDirectoryURLs: Set<URL> = [],
        onBatch: (([XcodeContainerCandidate]) -> Void)? = nil
    ) throws -> XcodeContainerScanResult {
        try Task.checkCancellation()
        let root = rootURL.standardizedFileURL
        var isDirectory: ObjCBool = false
        guard root.isFileURL,
              root.path.hasPrefix("/"),
              FileManager.default.fileExists(
                  atPath: root.path,
                  isDirectory: &isDirectory
              ),
              isDirectory.boolValue
        else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        let limit = max(1, maximumResults)
        let resolvedBatchSize = max(1, batchSize)
        let excludedDirectoryPaths = Set(
            excludingDirectoryURLs.map {
                $0.standardizedFileURL.path
            }
        )
        var unreadableLocationCount = 0
        var unreadableLocationURLs: [URL] = []
        var unreadableLocationPaths: Set<String> = []
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { url, _ in
                unreadableLocationCount += 1
                let standardizedURL = url.standardizedFileURL
                if unreadableLocationURLs.count
                    < Self.maximumUnreadableLocationCount,
                   unreadableLocationPaths.insert(
                    standardizedURL.path
                   ).inserted
                {
                    unreadableLocationURLs.append(standardizedURL)
                }
                return true
            }
        ) else {
            throw CocoaError(.fileReadUnknown)
        }

        var results: [XcodeContainerCandidate] = []
        var batch: [XcodeContainerCandidate] = []
        var reachedResultLimit = false
        while let url = enumerator.nextObject() as? URL {
            try Task.checkCancellation()
            if excludedDirectoryPaths.contains(
                url.standardizedFileURL.path
            ) {
                enumerator.skipDescendants()
                continue
            }
            let name = url.lastPathComponent.lowercased()
            if Self.ignoredDirectoryNames.contains(name) {
                enumerator.skipDescendants()
                continue
            }
            guard let candidate = discoveryCandidate(
                for: url,
                relativeTo: root
            ) else {
                continue
            }
            results.append(candidate)
            batch.append(results[results.endIndex - 1])
            if batch.count >= resolvedBatchSize {
                onBatch?(batch)
                batch.removeAll(keepingCapacity: true)
            }
            enumerator.skipDescendants()
            if results.count >= limit {
                reachedResultLimit = true
                break
            }
        }
        if !batch.isEmpty {
            onBatch?(batch)
        }
        let sortedCandidates = results.sorted {
            $0.relativePath.localizedCaseInsensitiveCompare(
                $1.relativePath
            ) == .orderedAscending
        }
        return XcodeContainerScanResult(
            candidates: sortedCandidates,
            unreadableLocationCount: unreadableLocationCount,
            unreadableLocationURLs: unreadableLocationURLs,
            reachedResultLimit: reachedResultLimit
        )
    }

    public func candidate(
        for url: URL,
        relativeTo rootURL: URL
    ) -> XcodeContainerCandidate? {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(
            atPath: url.path,
            isDirectory: &isDirectory
        ),
              isDirectory.boolValue,
              let kind = kind(for: url)
        else {
            return nil
        }
        let standardizedURL = url.standardizedFileURL
        let metadata = metadata(
            for: standardizedURL,
            kind: kind
        )
        return XcodeContainerCandidate(
            url: standardizedURL,
            rootURL: rootURL.standardizedFileURL,
            kind: kind,
            applications: metadata.applications,
            referencedProjectPaths: metadata.referencedProjectPaths,
            projectFileModificationDate:
                metadata.projectFileModificationDate
        )
    }

    public func discoveryCandidate(
        for url: URL,
        relativeTo rootURL: URL
    ) -> XcodeContainerCandidate? {
        guard kind(for: url) != nil else {
            return nil
        }
        let root = rootURL.standardizedFileURL
        let candidateURL = url.standardizedFileURL
        let rootComponents = root.pathComponents
        let candidateComponents = candidateURL.pathComponents
        guard candidateComponents.starts(with: rootComponents) else {
            return nil
        }
        let relativeComponents = candidateComponents
            .dropFirst(rootComponents.count)
            .dropLast()
        guard !relativeComponents.contains(where: {
            let component = $0.lowercased()
            return Self.ignoredDirectoryNames.contains(component)
                || component.hasSuffix(".xcodeproj")
                || component.hasSuffix(".xcworkspace")
        }) else {
            return nil
        }
        guard let candidate = candidate(
            for: candidateURL,
            relativeTo: root
        ),
              !candidate.applicationTargetNames.isEmpty
        else {
            return nil
        }
        return candidate
    }

    private func metadata(
        for url: URL,
        kind: XcodeContainerKind
    ) -> XcodeContainerMetadata {
        switch kind {
        case .project:
            let targets = iOSApplicationTargets(in: url)
            return XcodeContainerMetadata(
                applications: targets,
                referencedProjectPaths: [],
                projectFileModificationDate: fileModificationDate(
                    at: url.appendingPathComponent(
                        "project.pbxproj"
                    )
                )
            )
        case .workspace:
            return workspaceMetadata(url)
        }
    }

    private func fileModificationDate(at url: URL) -> Date? {
        (try? url.resourceValues(
            forKeys: [.contentModificationDateKey]
        ))?.contentModificationDate
    }

    private func iOSApplicationTargets(
        in projectURL: URL
    ) -> [XcodeApplicationTargetInfo] {
        let projectFile = projectURL.appendingPathComponent(
            "project.pbxproj"
        )
        guard let contents = boundedTextFile(
            at: projectFile,
            maximumSize: Self.maximumProjectFileSize
        ),
              contents.contains(Self.applicationProductType)
        else {
            return []
        }
        return applicationTargets(
            in: contents,
            projectURL: projectURL
        )
    }

    private func workspaceMetadata(
        _ workspaceURL: URL
    ) -> XcodeContainerMetadata {
        let contentsURL = workspaceURL.appendingPathComponent(
            "contents.xcworkspacedata"
        )
        guard let data = boundedData(
            at: contentsURL,
            maximumSize: Self.maximumWorkspaceFileSize
        ) else {
            return .empty
        }
        let baseURL = workspaceURL.deletingLastPathComponent()
        let delegate = WorkspaceProjectReferenceParser(
            workspaceBaseURL: baseURL
        )
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        guard parser.parse() else {
            return .empty
        }
        let projectURLs = delegate.projectURLs
        let projects = projectURLs.map { projectURL in
            (
                url: projectURL,
                applications: iOSApplicationTargets(in: projectURL)
            )
        }
        let applicationTargets = Set(
            projects.flatMap { project in
                project.applications.map { application in
                    let workspaceSchemeNames = schemeNames(
                        for: application.targetName,
                        in: workspaceURL
                    )
                    let allSchemeNames = Set(
                        application.schemeNames
                    ).union(workspaceSchemeNames)
                    return XcodeApplicationTargetInfo(
                        targetName: application.targetName,
                        displayName: application.displayName,
                        productName: application.productName,
                        bundleIdentifier:
                            application.bundleIdentifier,
                        developmentTeam:
                            application.developmentTeam,
                        marketingVersion:
                            application.marketingVersion,
                        buildVersion:
                            application.buildVersion,
                        schemeNames: allSchemeNames.sorted {
                            $0.localizedCaseInsensitiveCompare($1)
                                == .orderedAscending
                        },
                        iconURL: application.iconURL
                    )
                }
            }
        )
        let orderedTargets = applicationTargets.sorted {
            let displayOrder = $0.displayName
                .localizedCaseInsensitiveCompare($1.displayName)
            if displayOrder != .orderedSame {
                return displayOrder == .orderedAscending
            }
            return $0.targetName.localizedCaseInsensitiveCompare(
                $1.targetName
            ) == .orderedAscending
        }
        return XcodeContainerMetadata(
            applications: orderedTargets,
            referencedProjectPaths: projectURLs.map {
                $0.standardizedFileURL.path
            },
            projectFileModificationDate: projects
                .filter { !$0.applications.isEmpty }
                .compactMap {
                    fileModificationDate(
                        at: $0.url.appendingPathComponent(
                            "project.pbxproj"
                        )
                    )
                }
                .max()
                ?? fileModificationDate(at: contentsURL)
        )
    }

    private func applicationTargets(
        in projectContents: String,
        projectURL: URL
    ) -> [XcodeApplicationTargetInfo] {
        let sourceRootURL = projectURL.deletingLastPathComponent()
        let blocks = objectBlocks(in: projectContents)
        let blocksByIdentifier = Dictionary(
            blocks.map { ($0.identifier, $0.contents) },
            uniquingKeysWith: { first, _ in first }
        )
        var targets: Set<XcodeApplicationTargetInfo> = []
        for block in blocks.map(\.contents)
        where assignmentValue(named: "isa", in: block)
            == "PBXNativeTarget"
            && assignmentValue(named: "productType", in: block)
                == Self.applicationProductType
        {
            guard let configurationListID = referencedIdentifier(
                named: "buildConfigurationList",
                in: block
            ),
                  let configurationList =
                    blocksByIdentifier[configurationListID],
                  let targetName = assignmentValue(
                      named: "name",
                      in: block
                  ) ?? assignmentValue(
                      named: "productName",
                      in: block
                  ),
                  !targetName.isEmpty
            else {
                continue
            }
            let configurations = referencedIdentifiers(
                named: "buildConfigurations",
                in: configurationList
            ).compactMap { blocksByIdentifier[$0] }
            let iOSConfigurations = configurations.filter(
                isIOSBuildConfiguration
            )
            guard !iOSConfigurations.isEmpty else {
                continue
            }
            let releaseConfigurations = iOSConfigurations.filter {
                assignmentValue(named: "name", in: $0)?
                    .caseInsensitiveCompare("Release")
                    == .orderedSame
            }
            let buildConfigurations = releaseConfigurations.isEmpty
                ? iOSConfigurations
                : releaseConfigurations
            let targetProductName = assignmentValue(
                named: "productName",
                in: block
            ) ?? targetName
            let productName = resolvedProductName(
                targetName: targetName,
                targetProductName: targetProductName,
                configurations: buildConfigurations
            )
            targets.insert(
                XcodeApplicationTargetInfo(
                    targetName: targetName,
                    displayName: applicationDisplayName(
                        targetName: targetName,
                        productName: productName,
                        configurations: buildConfigurations,
                        sourceRootURL: sourceRootURL
                    ),
                    productName: productName,
                    bundleIdentifier: applicationBundleIdentifier(
                        targetName: targetName,
                        productName: productName,
                        configurations: buildConfigurations,
                        sourceRootURL: sourceRootURL
                    ),
                    developmentTeam: developmentTeam(
                        targetName: targetName,
                        productName: productName,
                        configurations: buildConfigurations
                    ),
                    marketingVersion: buildSetting(
                        named: "MARKETING_VERSION",
                        configurations: buildConfigurations
                    ),
                    buildVersion: buildSetting(
                        named: "CURRENT_PROJECT_VERSION",
                        configurations: buildConfigurations
                    ),
                    schemeNames: schemeNames(
                        for: targetName,
                        in: projectURL
                    ),
                    iconURL: applicationIconURL(
                        targetName: targetName,
                        productName: productName,
                        configurations: buildConfigurations,
                        sourceRootURL: sourceRootURL
                    )
                )
            )
        }
        return targets.sorted {
            let displayOrder = $0.displayName
                .localizedCaseInsensitiveCompare($1.displayName)
            if displayOrder != .orderedSame {
                return displayOrder == .orderedAscending
            }
            return $0.targetName.localizedCaseInsensitiveCompare(
                $1.targetName
            ) == .orderedAscending
        }
    }

    private func schemeNames(
        for targetName: String,
        in projectURL: URL
    ) -> [String] {
        let schemeRoots = [
            projectURL.appendingPathComponent(
                "xcshareddata/xcschemes",
                isDirectory: true
            ),
            projectURL.appendingPathComponent(
                "xcuserdata",
                isDirectory: true
            ),
        ]
        var matchingNames: Set<String> = []
        for root in schemeRoots {
            guard let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles],
                errorHandler: { _, _ in true }
            ) else {
                continue
            }
            var inspectedCount = 0
            while let url = enumerator.nextObject() as? URL {
                inspectedCount += 1
                if inspectedCount > 200 {
                    break
                }
                guard url.pathExtension
                    .caseInsensitiveCompare("xcscheme")
                        == .orderedSame,
                      let contents = boundedTextFile(
                          at: url,
                          maximumSize: Self.maximumWorkspaceFileSize
                      )
                else {
                    continue
                }
                let schemeName = url.deletingPathExtension()
                    .lastPathComponent
                if schemeName.caseInsensitiveCompare(targetName)
                    == .orderedSame
                    || contents.contains(
                        "BlueprintName = \"\(targetName)\""
                    )
                {
                    matchingNames.insert(schemeName)
                }
            }
        }
        return matchingNames.sorted {
            $0.localizedCaseInsensitiveCompare($1)
                == .orderedAscending
        }
    }

    private func resolvedProductName(
        targetName: String,
        targetProductName: String,
        configurations: [String]
    ) -> String {
        configurations.compactMap { configuration in
            assignmentValue(
                named: "PRODUCT_NAME",
                in: configuration
            ).flatMap {
                resolvedName(
                    $0,
                    targetName: targetName,
                    productName: targetProductName
                )
            }
        }.first
            ?? resolvedName(
                targetProductName,
                targetName: targetName,
                productName: targetName
            )
            ?? targetName
    }

    private func applicationDisplayName(
        targetName: String,
        productName: String,
        configurations: [String],
        sourceRootURL: URL
    ) -> String {
        let generationIsExplicitlyDisabled = configurations.contains {
            assignmentValue(
                named: "GENERATE_INFOPLIST_FILE",
                in: $0
            )?.caseInsensitiveCompare("NO") == .orderedSame
        }
        let usesSuppliedInfoPlist = configurations.contains {
            guard assignmentValue(named: "INFOPLIST_FILE", in: $0)
                != nil
            else {
                return false
            }
            return assignmentValue(
                named: "GENERATE_INFOPLIST_FILE",
                in: $0
            )?.caseInsensitiveCompare("YES") != .orderedSame
        }
        if usesSuppliedInfoPlist {
            for configuration in configurations {
                if let value = infoPlistApplicationName(
                    configuration: configuration,
                    targetName: targetName,
                    productName: productName,
                    sourceRootURL: sourceRootURL
                ) {
                    return value
                }
            }
            return productName
        }
        if generationIsExplicitlyDisabled {
            return productName
        }
        for key in [
            "INFOPLIST_KEY_CFBundleDisplayName",
            "INFOPLIST_KEY_CFBundleName",
        ] {
            for configuration in configurations {
                if let value = assignmentValue(
                    named: key,
                    in: configuration
                ).flatMap({
                    resolvedName(
                        $0,
                        targetName: targetName,
                        productName: productName
                    )
                }) {
                    return value
                }
            }
        }

        for configuration in configurations {
            if let value = infoPlistApplicationName(
                configuration: configuration,
                targetName: targetName,
                productName: productName,
                sourceRootURL: sourceRootURL
            ) {
                return value
            }
        }
        return productName
    }

    private func applicationBundleIdentifier(
        targetName: String,
        productName: String,
        configurations: [String],
        sourceRootURL: URL
    ) -> String? {
        for key in [
            "PRODUCT_BUNDLE_IDENTIFIER",
            "INFOPLIST_KEY_CFBundleIdentifier",
        ] {
            for configuration in configurations {
                if let value = assignmentValue(
                    named: key,
                    in: configuration
                ).flatMap({
                    resolvedName(
                        $0,
                        targetName: targetName,
                        productName: productName
                    )
                }) {
                    return value
                }
            }
        }
        for configuration in configurations {
            if let value = infoPlistValue(
                keys: ["CFBundleIdentifier"],
                configuration: configuration,
                targetName: targetName,
                productName: productName,
                sourceRootURL: sourceRootURL
            ) {
                return value
            }
        }
        return nil
    }

    private func developmentTeam(
        targetName: String,
        productName: String,
        configurations: [String]
    ) -> String? {
        configurations.compactMap { configuration in
            assignmentValue(
                named: "DEVELOPMENT_TEAM",
                in: configuration
            ).flatMap {
                resolvedName(
                    $0,
                    targetName: targetName,
                    productName: productName
                )
            }
        }.first
    }

    private func buildSetting(
        named name: String,
        configurations: [String]
    ) -> String? {
        configurations.compactMap {
            assignmentValue(named: name, in: $0)
        }.first
    }

    private func applicationIconURL(
        targetName: String,
        productName: String,
        configurations: [String],
        sourceRootURL: URL
    ) -> URL? {
        let iconName = configurations.compactMap { configuration in
            assignmentValue(
                named: "ASSETCATALOG_COMPILER_APPICON_NAME",
                in: configuration
            ).flatMap {
                resolvedName(
                    $0,
                    targetName: targetName,
                    productName: productName
                )
            }
        }.first ?? "AppIcon"
        return findAppIcon(
            named: iconName,
            targetName: targetName,
            productName: productName,
            sourceRootURL: sourceRootURL
        )
    }

    private func findAppIcon(
        named iconName: String,
        targetName: String,
        productName: String,
        sourceRootURL: URL
    ) -> URL? {
        let expectedDirectory =
            "\(iconName).appiconset".lowercased()
        var pendingDirectories: [(url: URL, depth: Int)] = [
            (sourceRootURL, 0)
        ]
        var pendingIndex = 0
        var candidates: [URL] = []
        var inspectedEntryCount = 0
        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey]

        while pendingIndex < pendingDirectories.count,
              inspectedEntryCount < Self.maximumIconSearchEntries,
              candidates.count < 8
        {
            let directory = pendingDirectories[pendingIndex]
            pendingIndex += 1
            guard let children = try? FileManager.default
                .contentsOfDirectory(
                    at: directory.url,
                    includingPropertiesForKeys: Array(resourceKeys),
                    options: [.skipsHiddenFiles]
                )
            else {
                continue
            }

            for url in children {
                inspectedEntryCount += 1
                if inspectedEntryCount > Self.maximumIconSearchEntries {
                    break
                }
                guard let values = try? url.resourceValues(
                    forKeys: resourceKeys
                ),
                    values.isDirectory == true
                else {
                    continue
                }
                let lowercasedName =
                    url.lastPathComponent.lowercased()
                if lowercasedName == expectedDirectory {
                    candidates.append(url)
                    continue
                }
                guard directory.depth < Self.maximumIconSearchDepth,
                      !Self.ignoredDirectoryNames.contains(
                          lowercasedName
                      ),
                      !lowercasedName.hasSuffix(".xcodeproj"),
                      !lowercasedName.hasSuffix(".xcworkspace"),
                      !lowercasedName.hasSuffix(".appiconset")
                else {
                    continue
                }
                pendingDirectories.append(
                    (url, directory.depth + 1)
                )
            }
            if candidates.count >= 8 {
                break
            }
        }
        let orderedCandidates = candidates.sorted {
            iconCandidateScore(
                $0,
                targetName: targetName,
                productName: productName
            ) > iconCandidateScore(
                $1,
                targetName: targetName,
                productName: productName
            )
        }
        return orderedCandidates.lazy.compactMap(
            preferredIconFile(in:)
        ).first
    }

    private func iconCandidateScore(
        _ url: URL,
        targetName: String,
        productName: String
    ) -> Int {
        let components = url.pathComponents.map {
            $0.lowercased()
        }
        var score = -components.count
        if components.contains(targetName.lowercased()) {
            score += 100
        }
        if components.contains(productName.lowercased()) {
            score += 80
        }
        return score
    }

    private func preferredIconFile(in appIconSetURL: URL) -> URL? {
        let contentsURL = appIconSetURL.appendingPathComponent(
            "Contents.json"
        )
        guard let data = boundedData(
            at: contentsURL,
            maximumSize: Self.maximumAssetContentsFileSize
        ),
              let object = try? JSONSerialization.jsonObject(
                  with: data
              ) as? [String: Any],
              let images = object["images"] as? [[String: Any]]
        else {
            return nil
        }
        let files = Set(
            images.compactMap { $0["filename"] as? String }
        ).compactMap { filename -> (URL, Int)? in
            let url = appIconSetURL.appendingPathComponent(filename)
            guard let values = try? url.resourceValues(
                forKeys: [.isRegularFileKey, .fileSizeKey]
            ),
                  values.isRegularFile == true
            else {
                return nil
            }
            return (url, values.fileSize ?? 0)
        }
        return files.max { $0.1 < $1.1 }?.0
    }

    private func infoPlistApplicationName(
        configuration: String,
        targetName: String,
        productName: String,
        sourceRootURL: URL
    ) -> String? {
        infoPlistValue(
            keys: ["CFBundleDisplayName", "CFBundleName"],
            configuration: configuration,
            targetName: targetName,
            productName: productName,
            sourceRootURL: sourceRootURL
        )
    }

    private func infoPlistValue(
        keys: [String],
        configuration: String,
        targetName: String,
        productName: String,
        sourceRootURL: URL
    ) -> String? {
        guard let rawPath = assignmentValue(
            named: "INFOPLIST_FILE",
            in: configuration
        ),
              let path = resolvedBuildPath(
                  rawPath,
                  targetName: targetName,
                  productName: productName,
                  sourceRootURL: sourceRootURL
              )
        else {
            return nil
        }
        let plistURL = path.hasPrefix("/")
            ? URL(fileURLWithPath: path)
            : sourceRootURL.appendingPathComponent(path)
        guard let data = boundedData(
            at: plistURL.standardizedFileURL,
            maximumSize: Self.maximumInfoPlistSize
        ),
              let propertyList = try? PropertyListSerialization
                .propertyList(
                    from: data,
                    options: [],
                    format: nil
                ) as? [String: Any]
        else {
            return nil
        }
        for key in keys {
            if let rawValue = propertyList[key] as? String,
               let value = resolvedName(
                   rawValue,
                   targetName: targetName,
                   productName: productName
               )
            {
                return value
            }
        }
        return nil
    }

    private func resolvedBuildPath(
        _ rawValue: String,
        targetName: String,
        productName: String,
        sourceRootURL: URL
    ) -> String? {
        var value = rawValue.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let sourceRoot = sourceRootURL.standardizedFileURL.path
        for variable in [
            "$(SRCROOT)",
            "${SRCROOT}",
            "$(PROJECT_DIR)",
            "${PROJECT_DIR}",
        ] {
            value = value.replacingOccurrences(
                of: variable,
                with: sourceRoot
            )
        }
        value = value.replacingOccurrences(
            of: "$(TARGET_NAME)",
            with: targetName
        )
        value = value.replacingOccurrences(
            of: "${TARGET_NAME}",
            with: targetName
        )
        value = value.replacingOccurrences(
            of: "$(PRODUCT_NAME)",
            with: productName
        )
        value = value.replacingOccurrences(
            of: "${PRODUCT_NAME}",
            with: productName
        )
        guard !containsUnresolvedBuildVariable(value),
              !value.isEmpty
        else {
            return nil
        }
        return value
    }

    private func resolvedName(
        _ rawValue: String,
        targetName: String,
        productName: String
    ) -> String? {
        var value = rawValue.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        for variable in ["$(TARGET_NAME)", "${TARGET_NAME}"] {
            value = value.replacingOccurrences(
                of: variable,
                with: targetName
            )
        }
        for variable in ["$(PRODUCT_NAME)", "${PRODUCT_NAME}"] {
            value = value.replacingOccurrences(
                of: variable,
                with: productName
            )
        }
        guard !containsUnresolvedBuildVariable(value),
              !value.isEmpty
        else {
            return nil
        }
        return value
    }

    private func containsUnresolvedBuildVariable(
        _ value: String
    ) -> Bool {
        value.contains("$(") || value.contains("${")
    }

    private func isIOSBuildConfiguration(_ block: String) -> Bool {
        if assignmentValue(named: "SDKROOT", in: block)?
            .lowercased() == "iphoneos"
        {
            return true
        }
        if assignmentValue(named: "SUPPORTED_PLATFORMS", in: block)?
            .lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .contains("iphoneos") == true
        {
            return true
        }
        if assignmentValue(
            named: "IPHONEOS_DEPLOYMENT_TARGET",
            in: block
        ) != nil {
            return true
        }
        guard let deviceFamilies = assignmentValue(
            named: "TARGETED_DEVICE_FAMILY",
            in: block
        ) else {
            return false
        }
        return deviceFamilies.split(whereSeparator: {
            !$0.isNumber
        }).contains(where: { $0 == "1" || $0 == "2" })
    }

    private func objectBlocks(in contents: String) -> [PBXObjectBlock] {
        var blocks: [PBXObjectBlock] = []
        var currentLines: [Substring] = []
        var currentIdentifier: String?
        var braceDepth = 0
        for line in contents.split(
            separator: "\n",
            omittingEmptySubsequences: false
        ) {
            if currentLines.isEmpty {
                guard let identifier = objectIdentifier(in: line) else {
                    continue
                }
                currentIdentifier = identifier
            }
            currentLines.append(line)
            braceDepth += braceDelta(in: line)
            if braceDepth == 0, let identifier = currentIdentifier {
                blocks.append(
                    PBXObjectBlock(
                        identifier: identifier,
                        contents: currentLines.map(String.init)
                            .joined(separator: "\n")
                    )
                )
                currentLines.removeAll(keepingCapacity: true)
                currentIdentifier = nil
            }
        }
        return blocks
    }

    private func objectIdentifier(in line: Substring) -> String? {
        let trimmed = line.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard trimmed.hasSuffix("= {"),
              let identifier = trimmed.split(
                  separator: " ",
                  maxSplits: 1
              ).first,
              identifier.count >= 8
        else {
            return nil
        }
        let value = String(identifier)
        return isObjectIdentifier(value) ? value : nil
    }

    private func isObjectIdentifier(_ value: String) -> Bool {
        value.count >= 8 && value.allSatisfy(\.isHexDigit)
    }

    private func braceDelta(in line: Substring) -> Int {
        line.reduce(into: 0) { count, character in
            if character == "{" {
                count += 1
            } else if character == "}" {
                count -= 1
            }
        }
    }

    private func assignmentValue(
        named key: String,
        in block: String
    ) -> String? {
        let prefix = "\(key) = "
        guard let line = block.split(separator: "\n").first(where: {
            $0.trimmingCharacters(in: .whitespaces)
                .hasPrefix(prefix)
        }) else {
            return nil
        }
        var value = String(
            line.trimmingCharacters(in: .whitespaces)
                .dropFirst(prefix.count)
        )
        if value.hasSuffix(";") {
            value.removeLast()
        }
        guard value.first == "\"", value.last == "\"" else {
            return value
        }
        value.removeFirst()
        value.removeLast()
        var decoded = ""
        var isEscaped = false
        for character in value {
            if isEscaped {
                decoded.append(character)
                isEscaped = false
            } else if character == "\\" {
                isEscaped = true
            } else {
                decoded.append(character)
            }
        }
        if isEscaped {
            decoded.append("\\")
        }
        return decoded
    }

    private func referencedIdentifier(
        named key: String,
        in block: String
    ) -> String? {
        guard let value = assignmentValue(named: key, in: block),
              let identifier = value.split(
                  separator: " ",
                  maxSplits: 1
              ).first.map(String.init),
              isObjectIdentifier(identifier)
        else {
            return nil
        }
        return identifier
    }

    private func referencedIdentifiers(
        named key: String,
        in block: String
    ) -> [String] {
        let opening = "\(key) = ("
        var isReadingList = false
        var identifiers: [String] = []
        for line in block.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !isReadingList {
                isReadingList = trimmed == opening
                continue
            }
            if trimmed == ");" {
                break
            }
            guard let identifier = trimmed.split(
                separator: " ",
                maxSplits: 1
            ).first.map(String.init),
                  isObjectIdentifier(identifier)
            else {
                continue
            }
            identifiers.append(identifier)
        }
        return identifiers
    }

    private func boundedTextFile(
        at url: URL,
        maximumSize: Int
    ) -> String? {
        guard let data = boundedData(
            at: url,
            maximumSize: maximumSize
        ) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func boundedData(
        at url: URL,
        maximumSize: Int
    ) -> Data? {
        guard let values = try? url.resourceValues(
            forKeys: [.isRegularFileKey, .fileSizeKey]
        ),
              values.isRegularFile == true,
              let fileSize = values.fileSize,
              fileSize > 0,
              fileSize <= maximumSize
        else {
            return nil
        }
        return try? Data(contentsOf: url, options: .mappedIfSafe)
    }

    private func kind(for url: URL) -> XcodeContainerKind? {
        switch url.pathExtension.lowercased() {
        case "xcodeproj":
            return .project
        case "xcworkspace":
            return .workspace
        default:
            return nil
        }
    }
}

private struct PBXObjectBlock {
    let identifier: String
    let contents: String
}

private struct XcodeContainerMetadata {
    let applications: [XcodeApplicationTargetInfo]
    let referencedProjectPaths: [String]
    let projectFileModificationDate: Date?

    static let empty = XcodeContainerMetadata(
        applications: [],
        referencedProjectPaths: [],
        projectFileModificationDate: nil
    )
}

private final class WorkspaceProjectReferenceParser:
    NSObject,
    XMLParserDelegate
{
    private let workspaceBaseURL: URL
    private var groupBaseURLs: [URL] = []
    private(set) var projectURLs: [URL] = []

    init(workspaceBaseURL: URL) {
        self.workspaceBaseURL = workspaceBaseURL.standardizedFileURL
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        switch elementName {
        case "Group":
            let currentBaseURL =
                groupBaseURLs.last ?? workspaceBaseURL
            let groupBaseURL = attributeDict["location"]
                .flatMap {
                    resolvedURL(
                        for: $0,
                        groupBaseURL: currentBaseURL
                    )
                } ?? currentBaseURL
            groupBaseURLs.append(groupBaseURL)
        case "FileRef":
            guard let location = attributeDict["location"],
                  let url = resolvedURL(
                      for: location,
                      groupBaseURL:
                          groupBaseURLs.last ?? workspaceBaseURL
                  ),
                  url.pathExtension.caseInsensitiveCompare(
                      "xcodeproj"
                  ) == .orderedSame
            else {
                return
            }
            projectURLs.append(url)
        default:
            return
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName == "Group", !groupBaseURLs.isEmpty {
            groupBaseURLs.removeLast()
        }
    }

    private func resolvedURL(
        for location: String,
        groupBaseURL: URL
    ) -> URL? {
        let components = location.split(
            separator: ":",
            maxSplits: 1,
            omittingEmptySubsequences: false
        )
        guard components.count == 2 else {
            return URL(
                fileURLWithPath: location,
                relativeTo: groupBaseURL
            ).standardizedFileURL
        }
        let type = components[0]
        let path = String(components[1])
        switch type {
        case "group":
            return URL(
                fileURLWithPath: path,
                relativeTo: groupBaseURL
            ).standardizedFileURL
        case "container", "self":
            return URL(
                fileURLWithPath: path,
                relativeTo: workspaceBaseURL
            ).standardizedFileURL
        case "absolute":
            let absolutePath = "/" + path.drop(while: { $0 == "/" })
            return URL(fileURLWithPath: absolutePath)
                .standardizedFileURL
        default:
            return nil
        }
    }
}
