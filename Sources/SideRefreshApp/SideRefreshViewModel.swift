import AppKit
import Combine
import Foundation
import ServiceManagement
import UniformTypeIdentifiers
import SideRefreshCore
import SideRefreshAppPresentation

enum RenewalRunPresentationState {
    case idle
    case running
    case succeeded
    case failed
}

enum RenewalLogMutation {
    case append(String)
    case reset(String)
}

private enum CoreDeviceDiscoveryOutcome: Sendable {
    case success(CoreDeviceSnapshot)
    case failure(SimpleErrorMessageContent)
}

@MainActor
final class SideRefreshViewModel: ObservableObject {
    private struct PresentedError {
        let legacyMessage: String
        let simpleContent: SimpleErrorMessageContent
    }

    private struct GuidedTargetMigrationSnapshot {
        let selectedDeviceIdentifier: String?
        let selectedDeviceName: String?
        let selectedDeviceMarketingName: String?
        let selectedDeviceOperatingSystemVersion: String?
    }

    private struct ProjectScanRequest {
        let rootURL: URL
        let description: SideRefreshLocalizedText
    }

    static let agentPlistName = "io.github.siderefresh.renewal.plist"

    @Published var executablePath = "" {
        didSet { markConfigurationDirty() }
    }
    @Published var argumentsText = "" {
        didSet { markConfigurationDirty() }
    }
    @Published var renewEveryHours = 144 {
        didSet { markConfigurationDirty() }
    }
    @Published var target = RenewalTargetDraft() {
        didSet {
            markConfigurationDirty()
            clearInstalledAppInspectionIfTargetChanged()
            handleAppVersionIdentityChange(from: oldValue)
        }
    }
    @Published var renewalMode = IOSAppRenewalMode.dryRun {
        didSet { markConfigurationDirty() }
    }
    @Published var buildStrategy =
        IOSAppBuildStrategy.incremental
    {
        didSet { markConfigurationDirty() }
    }
    @Published var versionPolicy = IOSAppVersionPolicy.keep {
        didSet { markConfigurationDirty() }
    }
    @Published var connectionRoute = DeviceConnectionRoute(
        rawValue: UserDefaults.standard.string(
            forKey: "side-refresh.connectionRoute"
        ) ?? ""
    ) ?? .automatic {
        didSet {
            guard connectionRoute != oldValue else {
                return
            }
            UserDefaults.standard.set(
                connectionRoute.rawValue,
                forKey: "side-refresh.connectionRoute"
            )
            markConfigurationDirty()
        }
    }
    @Published var customDeviceAddress = UserDefaults.standard.string(
        forKey: "customDeviceAddress"
    ) ?? "" {
        didSet {
            UserDefaults.standard.set(
                customDeviceAddress,
                forKey: "customDeviceAddress"
            )
        }
    }
    @Published var selectedTailnetNodeID = "" {
        didSet {
            guard selectedTailnetNodeID != oldValue else {
                return
            }
            guard !isReconcilingTailnetDiscovery else {
                return
            }
            markConfigurationDirty()
        }
    }
    @Published private(set) var discoveredXcodeContainers:
        [XcodeContainerCandidate] = []
    @Published private var projectScanMessage =
        SideRefreshLocalizedText.key(
            "Mac에서 iOS 앱 프로젝트를 찾을 준비가 됐습니다."
        )
    var projectScanSummary: String {
        projectScanMessage.resolved()
    }
    @Published private(set) var isScanningProjects = false
    @Published private(set) var projectSearchLocations:
        [ProjectSearchLocationAccess] = []
    @Published private(set) var pairedCoreDevices: [CoreDevice] = []
    @Published private(set) var rememberedCoreDeviceName =
        UserDefaults.standard.string(
            forKey: "side-refresh.selectedCoreDeviceName"
        ) ?? ""
    @Published private(set) var rememberedCoreDeviceMarketingName =
        UserDefaults.standard.string(
            forKey: "side-refresh.selectedCoreDeviceMarketingName"
        ) ?? ""
    @Published private var coreDeviceMessage =
        SideRefreshLocalizedText.key(
            "아직 Xcode의 iPhone 목록을 확인하지 않았습니다."
        )
    var coreDeviceSummary: String {
        coreDeviceMessage.resolved()
    }
    @Published private(set) var isDiscoveringCoreDevices = false
    @Published private(set) var coreDeviceDiscoveryHasCompleted = false
    @Published private(set) var tailnetDevices: [TailnetDevice] = []
    @Published private(set) var tailscaleExecutablePath = ""
    @Published private var tailnetMessage =
        SideRefreshLocalizedText.key(
            "아직 Tailscale 기기 목록을 확인하지 않았습니다."
        )
    var tailnetSummary: String {
        tailnetMessage.resolved()
    }
    @Published private(set) var isDiscoveringTailnet = false
    @Published private(set) var tailnetDiscoveryHasCompleted = false
    @Published private(set) var hasGuidedTarget = true
    @Published private(set) var renewalSummary = "설정 확인 중"
    @Published private(set) var agentSummary = "백그라운드 상태 확인 중"
    @Published private(set) var nextRenewalDate: Date?
    @Published private(set) var lastSuccessfulRenewal: Date?
    @Published private(set) var provisioningExpirationDate: Date?
    @Published private(set) var provisioningProfileIdentifier: String?
    @Published private(set) var installedDeviceApp: InstalledDeviceApp?
    @Published private(set) var installedDeveloperApps:
        [InstalledDeviceApp] = []
    @Published private(set) var installedAppSummary =
        "아직 iPhone의 설치 상태를 확인하지 않았습니다."
    @Published private(set) var installedProvisioningProfile:
        ProvisioningProfileMetadata?
    @Published private(set) var installedProvisioningProfileMatchesReceipt =
        false
    @Published private(set) var installedAppCheckedAt: Date?
    @Published private(set) var deviceProfileSummary =
        "실제 iPhone 프로파일을 아직 확인하지 않았습니다."
    @Published private(set) var isInspectingInstalledApp = false
    @Published private(set) var isDiscoveringPersonalTeam = false
    @Published private(set) var personalTeamSelection:
        PersonalTeamSelection?
    @Published private(set) var isConfigured = false
    @Published private(set) var configurationIsDirty = false
    @Published private(set) var settingsSaveConfirmationGeneration = 0
    @Published private(set) var isWorking = false
    @Published private(set) var renewalRunPresentationState:
        RenewalRunPresentationState = .idle
    @Published private(set) var renewalRunCompletedAt: Date?
    @Published private(set) var renewalResultLacksExpirationEvidence =
        false
    @Published private(set) var renewalStatusCheckDidFail = false
    @Published private(set) var renewalProgressEvents:
        [RenewalProgressPhase: RenewalProgressEvent] = [:]
    @Published private(set) var renewalLogText = ""
    @Published private var presentedError: PresentedError?

    var errorMessage: String? {
        presentedError?.legacyMessage
    }

    var simpleErrorMessageContent: SimpleErrorMessageContent? {
        presentedError?.simpleContent
    }

    func presentProductError(_ localizationKey: String) {
        presentedError = PresentedError(
            legacyMessage: localizationKey,
            simpleContent: .productKey(localizationKey)
        )
    }

    func presentVerbatimError(_ message: String) {
        presentedError = PresentedError(
            legacyMessage: message,
            simpleContent: .verbatim(message)
        )
    }

    func dismissError() {
        presentedError = nil
    }

    func languagePreferenceDidChange() {
        objectWillChange.send()
    }

    let renewalLogMutations =
        PassthroughSubject<RenewalLogMutation, Never>()

    private let service = SMAppService.agent(plistName: agentPlistName)
    private var cachedServiceStatus: SMAppService.Status = .notRegistered
    var isLoadingConfiguration = false
    private var loadedTailnetTarget: TailnetTarget?
    private(set) var savedRenewalTarget: RenewalTargetDraft?
    private(set) var savedRenewalMode: IOSAppRenewalMode?
    private(set) var savedConnectionRoute: DeviceConnectionRoute?
    private var projectScanGeneration = 0
    private var projectScanWorker:
        Task<XcodeContainerScanResult, Error>?
    private var projectSpotlightQuery: NSMetadataQuery?
    private var projectSpotlightObserverTokens: [NSObjectProtocol] = []
    private var projectSpotlightTimeoutTask: Task<Void, Never>?
    private var projectSpotlightMetadataTask: Task<Void, Never>?
    private var projectSearchAccessTask: Task<Void, Never>?
    private var projectScanExcludedDirectoryURLs: Set<URL> = []
    private var queuedProjectScanRequests: [ProjectScanRequest] = []
    private var projectScanPreviousLocationStatuses:
        [String: ProjectSearchAccessStatus] = [:]
    private var cachedProjectLoadTask: Task<Void, Never>?
    private var configuredContainerLoadTask: Task<Void, Never>?
    private var configuredContainerLoadGeneration = 0
    var appVersionReloadDebounceTask: Task<Void, Never>?
    private let appVersionResolver = XcodeBuildSettingsVersionResolver()
    private let coreDeviceDiscoveryQueue = DispatchQueue(
        label: "io.github.siderefresh.core-device-discovery",
        qos: .userInitiated
    )
    private var coreDeviceDiscoveryGeneration = 0
    private var coreDeviceDiscoveryTimeoutTimer: Timer?
    private var tailnetDiscoveryTask: Task<Void, Never>?
    private var isReconcilingTailnetDiscovery = false
    private var personalTeamDiscoveryTask: Task<Void, Never>?
    private var personalTeamDiscoveryGeneration = 0
    private var renewalLogCharacterCount = 0
    private var renewalLogMetrics = RenewalLogMetrics(
        maximumPreviewLines: 8
    )
    private var hasRequestedHomeScan = false
    private var manuallyAddedProjectPaths: Set<String> = []
    private var selectedProjectSearchFolderPaths: Set<String> = []
    private var inspectedDeviceIdentifier = ""
    private var inspectedBundleIdentifier = ""
    private var guidedTargetMigrationSnapshot:
        GuidedTargetMigrationSnapshot?

    private static let cachedProjectPathsKey =
        "side-refresh.cachedXcodeContainerPaths"
    private static let manuallyAddedProjectPathsKey =
        "side-refresh.manuallyAddedXcodeContainerPaths"
    private static let selectedProjectSearchFolderPathsKey =
        "side-refresh.selectedProjectSearchFolderPaths"
    private static let selectedCoreDeviceIdentifierKey =
        "side-refresh.selectedCoreDeviceIdentifier"
    private static let selectedCoreDeviceNameKey =
        "side-refresh.selectedCoreDeviceName"
    private static let selectedCoreDeviceMarketingNameKey =
        "side-refresh.selectedCoreDeviceMarketingName"
    private static let selectedCoreDeviceOperatingSystemVersionKey =
        "side-refresh.selectedCoreDeviceOperatingSystemVersion"
    private static let lastDevelopmentTeamIdentifierKey =
        "side-refresh.lastDevelopmentTeamIdentifier"

    init() {
        loadProjectSearchLocations()
        loadCachedXcodeContainers()
        loadConfiguration()
        if !isConfigured,
           let helperURL = bundledIOSRenewalHelperURL()
        {
            executablePath = helperURL.path
        }
        refresh()
    }

    var automationIsReady: Bool {
        isConfigured
            && !configurationIsDirty
            && hasGuidedTarget
            && target.isComplete
            && renewalMode == .execute
            && backgroundAutomationIsEnabled
    }

    var backgroundAutomationIsEnabled: Bool {
        cachedServiceStatus == .enabled
    }

    var backgroundAutomationRequiresApproval: Bool {
        cachedServiceStatus == .requiresApproval
    }

    var backgroundAutomationPresentationState:
        BackgroundAutomationState
    {
        switch cachedServiceStatus {
        case .notRegistered:
            return .notRegistered
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .approvalRequired
        case .notFound:
            return .helperMissing
        @unknown default:
            return .unknown
        }
    }

    var automationConfigurationNeedsSave: Bool {
        configurationIsDirty
            || (
                !isConfigured
                    && hasGuidedTarget
                    && target.isComplete
                    && renewalMode == .execute
            )
    }

    var targetDisplayName: String {
        hasGuidedTarget ? target.displayName : "직접 만든 실행 명령"
    }

    var readinessTitle: String {
        if automationIsReady {
            return "자동 갱신 준비됨"
        }
        if !hasGuidedTarget {
            return "직접 만든 명령 사용 중"
        }
        if renewalMode == .dryRun {
            return "테스트 모드 · 변경 없음"
        }
        if configurationIsDirty || !isConfigured {
            return "설정을 완료하세요"
        }
        return "자동 갱신을 켜세요"
    }

    var selectedTailnetDevice: TailnetDevice? {
        tailnetDevices.first { $0.id == selectedTailnetNodeID }
    }

    var simpleSettingsSaveReadiness: SimpleSettingsSaveReadiness {
        guard hasGuidedTarget else {
            return .appSelectionRequired
        }
        if let missingField = target.firstMissingRequiredField {
            switch missingField {
            case .container:
                return .appSelectionRequired
            case .scheme,
                 .productName,
                 .bundleIdentifier,
                 .developmentTeam:
                return .appConfigurationRequired
            case .deviceIdentifier:
                return .iphoneSelectionRequired
            case .derivedData:
                return .automationConfigurationRequired
            }
        }
        guard !target.configuration.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            return .appConfigurationRequired
        }
        guard connectionRoute == .tailnet else {
            return .complete
        }
        let selectedDeviceCanBeSaved =
            selectedTailnetDevice?.id != nil
                && selectedTailnetDevice?.dnsName != nil
        let canReuseSavedDevice =
            loadedTailnetTarget?.nodeID == selectedTailnetNodeID
        switch TailnetSetupPolicy.requirement(
            executableIsAvailable: tailscaleExecutableIsAvailable,
            hasSelectedDevice: selectedDeviceCanBeSaved,
            canReuseSavedDevice: canReuseSavedDevice
        ) {
        case .installationRequired:
            return .tailscaleInstallationRequired
        case .deviceSelectionRequired:
            return .tailnetDeviceSelectionRequired
        case nil:
            return .complete
        }
    }

    var coreDeviceDisplaySummary: String {
        if isDiscoveringCoreDevices {
            return coreDeviceSummary
        }
        let currentUDID = target.deviceIdentifier.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if let selected = pairedCoreDevices.first(where: {
            $0.udid == currentUDID
        }) {
            return coreDevicePairedMessage(selected).resolved()
        }
        if !currentUDID.isEmpty,
           !currentUDID.hasPrefix("REPLACE_")
        {
            return SideRefreshLocalization.string(
                "저장된 UDID 사용 중"
                    + " · 현재 Xcode 기기 목록에서 확인되지 않음"
            )
        }
        return coreDeviceSummary
    }

    var selectedCoreDeviceDisplayName: String? {
        let currentUDID = target.deviceIdentifier.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if let selected = pairedCoreDevices.first(where: {
            $0.udid == currentUDID
        }) {
            return selected.name
        }
        let rememberedUDID = UserDefaults.standard.string(
            forKey: Self.selectedCoreDeviceIdentifierKey
        ) ?? ""
        guard currentUDID == rememberedUDID,
              !rememberedCoreDeviceName.isEmpty
        else {
            return nil
        }
        return rememberedCoreDeviceName
    }

    var selectedCoreDeviceMarketingName: String? {
        let currentUDID = target.deviceIdentifier.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if let selected = pairedCoreDevices.first(where: {
            $0.udid == currentUDID
        }),
           let marketingName = selected.marketingName?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !marketingName.isEmpty
        {
            return marketingName
        }
        let rememberedUDID = UserDefaults.standard.string(
            forKey: Self.selectedCoreDeviceIdentifierKey
        ) ?? ""
        guard currentUDID == rememberedUDID,
              !rememberedCoreDeviceMarketingName.isEmpty
        else {
            return nil
        }
        return rememberedCoreDeviceMarketingName
    }

    var selectedCoreDeviceOperatingSystemVersion: String? {
        let currentUDID = target.deviceIdentifier.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if let selected = pairedCoreDevices.first(where: {
            $0.udid == currentUDID
        }),
           let version = selected.operatingSystemVersion?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !version.isEmpty
        {
            return version
        }
        let rememberedUDID = UserDefaults.standard.string(
            forKey: Self.selectedCoreDeviceIdentifierKey
        ) ?? ""
        guard currentUDID == rememberedUDID else {
            return nil
        }
        let rememberedVersion = UserDefaults.standard.string(
            forKey: Self.selectedCoreDeviceOperatingSystemVersionKey
        )?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return rememberedVersion.isEmpty ? nil : rememberedVersion
    }

    var selectedCoreDeviceDisplayLabel: String? {
        let identifier = target.deviceIdentifier.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !identifier.isEmpty else {
            return nil
        }
        return RenewalIPhoneNamePolicy.resolve(
            discoveredName: selectedCoreDeviceDisplayName,
            rememberedName: nil,
            deviceIdentifier: identifier,
            discoveredModelName: selectedCoreDeviceMarketingName
        )
    }

    var saveRequiresActiveAgentConfirmation: Bool {
        backgroundAutomationIsEnabled
            && (!isConfigured || configurationIsDirty)
    }

    var missingTargetRequiredField: RenewalTargetRequiredField? {
        hasGuidedTarget ? target.firstMissingRequiredField : nil
    }

    var immediateRenewalConfirmationTitle: String {
        guard hasGuidedTarget else {
            return SideRefreshLocalization.string("지금 갱신할까요?")
        }
        return SideRefreshLocalization.format(
            "%@을 지금 설치할까요?",
            target.displayName
        )
    }

    var immediateRenewalConfirmationMessage: String {
        guard hasGuidedTarget else {
            return SideRefreshLocalization.string(
                "직접 만든 명령은 즉시 갱신에서 실행하지 않습니다."
            )
        }
        let device = selectedCoreDeviceDisplayLabel
            ?? SideRefreshLocalization.string("선택한 iPhone")
        let connection = SideRefreshLocalization.string(
            connectionRoute.title
        )
        let version = versionPolicy == .automatic
            ? SideRefreshLocalization.format(
                "자동 버전업 · %@",
                versionPreviewText
            )
            : SideRefreshLocalization.string("현재 버전 유지")
        return SideRefreshLocalization.format(
            "%@ · %@\n%@ · %@\n완료 후 실제 만료일을 자동으로 기록합니다.",
            device,
            connection,
            SideRefreshLocalization.string(buildStrategyConfirmationText),
            version
        )
    }

    var automaticVersionPreview: IOSAppVersion? {
        guard let source = target.sourceAppVersion else {
            return nil
        }
        return IOSAppVersion.next(
            source: source,
            installed: installedAppVersion
        )
    }

    var versionPreviewText: String {
        guard let source = target.sourceAppVersion else {
            return versionPolicy == .automatic
                ? SideRefreshLocalization.string(
                    "실행 직전 Xcode 설정에서 현재 버전을 확인해 다음 값으로 올립니다."
                )
                : SideRefreshLocalization.string(
                    "현재 Xcode 앱 버전과 빌드 번호를 그대로 유지합니다."
                )
        }
        let sourceText =
            "\(source.marketingVersion) (\(source.buildVersion))"
        guard versionPolicy == .automatic else {
            return SideRefreshLocalization.format(
                "%@ 그대로 유지",
                sourceText
            )
        }
        let currentVersion = IOSAppVersion.resolvedBase(
            source: source,
            installed: installedAppVersion
        )
        let current =
            "\(currentVersion.marketingVersion) (\(currentVersion.buildVersion))"
        guard let next = automaticVersionPreview else {
            return SideRefreshLocalization.string(
                "다음 버전을 계산하지 못했습니다."
            )
        }
        return "\(current) → \(next.marketingVersion) (\(next.buildVersion))"
    }

    var hasDetectedVersionPreview: Bool {
        target.sourceAppVersion != nil
    }

    private var installedAppVersion: IOSAppVersion? {
        installedDeviceApp.flatMap {
            IOSAppVersion(
                marketingVersion: $0.version,
                buildVersion: $0.bundleVersion
            )
        }
    }

    private var buildStrategyConfirmationText: String {
        switch buildStrategy {
        case .incremental:
            return "스마트 증분 빌드"
        case .cleanRebuild:
            return "전체 다시 빌드"
        }
    }

    var canTestCurrentSetup: Bool {
        hasGuidedTarget
            && !isWorking
    }

    var canRenewImmediately: Bool {
        isConfigured
            && !configurationIsDirty
            && !isWorking
            && hasGuidedTarget
            && target.isComplete
            && renewalMode == .execute
    }

    var canRegisterAgent: Bool {
        isConfigured
            && !configurationIsDirty
            && (
                !hasGuidedTarget
                    || (
                        renewalMode == .execute
                            && target.isComplete
                    )
            )
    }

    var hasRenewalRunDetails: Bool {
        renewalRunPresentationState != .idle
            || !renewalLogText.isEmpty
    }

    var orderedRenewalProgressEvents: [RenewalProgressEvent] {
        RenewalProgressPhase.allCases.compactMap {
            renewalProgressEvents[$0]
        }
    }

    var currentRenewalProgressMessage: String {
        orderedRenewalProgressEvents.last?.message
            ?? "갱신을 시작할 준비가 됐습니다."
    }

    var renewalLogLineCount: Int {
        renewalLogMetrics.lineCount
    }

    var renewalLogPreviewText: String {
        renewalLogMetrics.preview
    }

    var registrationConfirmationMessage: String {
        SideRefreshLocalization.format(
            "Mac에 로그인한 동안 SideRefresh가 백그라운드에서 갱신 시점을 확인하도록 등록합니다. Apple ID나 Tailscale 계정에 로그인하는 기능은 아닙니다.\n\n%@",
            targetConfirmationDetails
        )
    }

    var activeConfigurationSaveMessage: String {
        SideRefreshLocalization.format(
            "자동 갱신이 켜져 있습니다. 저장하면 다음 확인부터 아래 설정을 사용합니다.\n\n%@",
            targetConfirmationDetails
        )
    }

    private var targetConfirmationDetails: String {
        guard hasGuidedTarget else {
            return SideRefreshLocalization.format(
                "직접 만든 명령\n실행 파일: %@",
                displayValue(executablePath)
            )
        }
        let mode = SideRefreshLocalization.string(
            renewalMode == .execute
                ? "실행 · 앱 다시 설치"
                : "테스트 · 변경 없음"
        )
        let build = SideRefreshLocalization.string(
            buildStrategy == .incremental
                ? "스마트 증분 빌드"
                : "전체 다시 빌드"
        )
        let version = versionPolicy == .automatic
            ? SideRefreshLocalization.format(
                "자동 버전업 · %@",
                versionPreviewText
            )
            : SideRefreshLocalization.format(
                "현재 버전 유지 · %@",
                versionPreviewText
            )
        let connection = currentConnectionAddress.map {
            "\(SideRefreshLocalization.string(connectionRoute.title)) · \($0)"
        } ?? SideRefreshLocalization.string(connectionRoute.title)
        return [
            SideRefreshLocalization.format("앱: %@", target.displayName),
            SideRefreshLocalization.format(
                "앱 식별자: %@",
                displayValue(target.bundleIdentifier)
            ),
            SideRefreshLocalization.format(
                "앱 구성(Scheme): %@",
                displayValue(target.scheme)
            ),
            SideRefreshLocalization.format(
                "Xcode 파일: %@",
                displayValue(target.containerPath)
            ),
            SideRefreshLocalization.format(
                "iPhone 기기 식별자: %@",
                displayValue(target.deviceIdentifier)
            ),
            SideRefreshLocalization.format("연결: %@", connection),
            SideRefreshLocalization.format("모드: %@", mode),
            SideRefreshLocalization.format("갱신 빌드: %@", build),
            SideRefreshLocalization.format("앱 버전: %@", version),
        ].joined(separator: "\n")
    }

    private func displayValue(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return trimmed.isEmpty
            ? SideRefreshLocalization.string("미입력")
            : trimmed
    }

    var currentConnectionAddress: String? {
        switch connectionRoute {
        case .automatic:
            return nil
        case .tailnet:
            return selectedTailnetDevice?.preferredIPAddress
                ?? (
                    loadedTailnetTarget?.nodeID == selectedTailnetNodeID
                        ? loadedTailnetTarget?.dnsName
                        : nil
                )
        case .custom:
            let value = customDeviceAddress.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            return value.isEmpty ? nil : value
        }
    }

    func loadConfiguration() {
        let fileURL = SideRefreshPaths.defaultConfigurationFile
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            isConfigured = false
            configurationIsDirty = false
            savedRenewalTarget = nil
            savedRenewalMode = nil
            savedConnectionRoute = nil
            return
        }

        do {
            isLoadingConfiguration = true
            defer { isLoadingConfiguration = false }
            let configuration = try AgentConfiguration.load(from: fileURL)
            var loadedConfigurationNeedsSave = false
            executablePath = configuration.command.executable
            argumentsText = configuration.command.arguments.joined(separator: "\n")
            if let helperURL = bundledIOSRenewalHelperURL(),
               let profile = IOSAppRenewalProfile.recognized(
                        in: configuration.command,
                        bundledHelperURL: helperURL
                    )
            {
                target = RenewalTargetDraft(profile: profile)
                savedRenewalTarget = target
                renewalMode = profile.mode
                savedRenewalMode = profile.mode
                buildStrategy = profile.buildStrategy
                versionPolicy = profile.versionPolicy
                hasGuidedTarget = true
                loadConfiguredXcodeContainer(profile.plan.containerURL)
            } else {
                target = RenewalTargetDraft()
                renewalMode = .dryRun
                buildStrategy = .incremental
                versionPolicy = .keep
                hasGuidedTarget = false
                savedRenewalTarget = nil
                savedRenewalMode = nil
            }
            loadedTailnetTarget = configuration.tailnetTarget
            if let tailnetTarget = configuration.tailnetTarget {
                connectionRoute = .tailnet
                savedConnectionRoute = .tailnet
                tailscaleExecutablePath =
                    tailnetTarget.tailscaleExecutable
                if let availablePath =
                    availableTailscaleExecutablePath
                {
                    loadedConfigurationNeedsSave =
                        availablePath != tailnetTarget.tailscaleExecutable
                    tailscaleExecutablePath = availablePath
                }
                selectedTailnetNodeID = tailnetTarget.nodeID
                if loadedConfigurationNeedsSave {
                    tailnetMessage = .key(
                        "Tailscale 설치 위치가 바뀌었습니다."
                            + " 설정을 저장해 주세요."
                    )
                } else {
                    tailnetMessage = tailscaleExecutableIsAvailable
                        ? .key(
                            "저장된 Tailscale iPhone 주소가 있습니다."
                                + " 현재 상태를 확인하세요."
                        )
                        : .key(
                            "저장된 Tailscale 설정이 있지만"
                                + " 실행 가능한 Tailscale을 찾지 못했습니다."
                        )
                }
            } else if connectionRoute == .tailnet {
                connectionRoute = .automatic
                savedConnectionRoute = .automatic
            } else {
                savedConnectionRoute = .automatic
            }
            renewEveryHours = configuration.renewEveryHours
            isConfigured = true
            configurationIsDirty = loadedConfigurationNeedsSave
        } catch {
            isConfigured = false
            savedRenewalTarget = nil
            savedRenewalMode = nil
            savedConnectionRoute = nil
            presentVerbatimError(error.localizedDescription)
        }
    }

    @discardableResult
    func saveConfiguration(
        allowingActiveAgentExecution: Bool = false
    ) -> Bool {
        guard !saveRequiresActiveAgentConfirmation
                || allowingActiveAgentExecution
        else {
            presentProductError(
                "자동 갱신이 켜져 있습니다. 설정을 바꾸려면 확인 창에서 저장을 승인하세요."
            )
            return false
        }
        guard executablePath.hasPrefix("/") else {
            presentProductError("실행 파일은 절대 경로여야 합니다.")
            return false
        }
        guard FileManager.default.isExecutableFile(atPath: executablePath) else {
            presentProductError("실행 가능한 파일을 찾을 수 없습니다.")
            return false
        }

        do {
            let command: RenewalCommand
            if hasGuidedTarget {
                if let missingField =
                    target.firstMissingRequiredField
                {
                    presentProductError(missingField.guidance)
                    return false
                }
                guard let helperURL = bundledIOSRenewalHelperURL(),
                      IOSAppRenewalProfile.usesBundledHelper(
                          executableURL: URL(
                              fileURLWithPath: executablePath
                          ),
                          bundledHelperURL: helperURL
                      )
                else {
                    presentProductError(
                        "안전한 앱 갱신을 위해 SideRefresh에 포함된 갱신 도구가 필요합니다. 앱을 다시 설치해 주세요."
                    )
                    return false
                }
                let profile = try target.profile(
                    mode: renewalMode,
                    buildStrategy: buildStrategy,
                    versionPolicy: versionPolicy
                )
                command = profile.command(
                    helperExecutableURL: helperURL
                )
                isLoadingConfiguration = true
                argumentsText = command.arguments.joined(separator: "\n")
                isLoadingConfiguration = false
            } else {
                let arguments = argumentsText
                    .split(separator: "\n", omittingEmptySubsequences: true)
                    .map(String.init)
                command = RenewalCommand(
                    executableURL: URL(fileURLWithPath: executablePath),
                    arguments: arguments
                )
            }
            let tailnetTarget: TailnetTarget?
            if connectionRoute == .tailnet {
                let resolvedTailscalePath =
                    availableTailscaleExecutablePath
                let hasSelectedDevice =
                    selectedTailnetDevice?.id != nil
                    && selectedTailnetDevice?.dnsName != nil
                let canReuseSavedDevice =
                    loadedTailnetTarget?.nodeID
                        == selectedTailnetNodeID
                if let requirement = TailnetSetupPolicy.requirement(
                    executableIsAvailable:
                        resolvedTailscalePath != nil,
                    hasSelectedDevice: hasSelectedDevice,
                    canReuseSavedDevice: canReuseSavedDevice
                ) {
                    presentProductError(requirement.userMessage)
                    return false
                }
                guard let executablePath =
                        resolvedTailscalePath
                else {
                    presentProductError(
                        TailnetSetupRequirement
                            .installationRequired.userMessage
                    )
                    return false
                }
                if let device = selectedTailnetDevice,
                   let nodeID = device.id,
                   let dnsName = device.dnsName
                {
                    tailnetTarget = TailnetTarget(
                        tailscaleExecutable: executablePath,
                        nodeID: nodeID,
                        dnsName: dnsName
                    )
                } else if let loadedTailnetTarget,
                          loadedTailnetTarget.nodeID
                              == selectedTailnetNodeID
                {
                    tailnetTarget = TailnetTarget(
                        tailscaleExecutable: executablePath,
                        nodeID: loadedTailnetTarget.nodeID,
                        dnsName: loadedTailnetTarget.dnsName
                    )
                } else {
                    presentProductError(
                        TailnetSetupRequirement
                            .deviceSelectionRequired.userMessage
                    )
                    return false
                }
            } else {
                tailnetTarget = nil
            }
            let configuration = AgentConfiguration(
                stateFileURL: SideRefreshPaths.defaultStateFile,
                renewalInterval: try RenewalInterval(hours: renewEveryHours),
                tailnetTarget: tailnetTarget,
                command: command
            )
            try configuration.write(to: SideRefreshPaths.defaultConfigurationFile)
            if Self.isValidDevelopmentTeamIdentifier(
                target.developmentTeam
            ) {
                UserDefaults.standard.set(
                    target.developmentTeam,
                    forKey:
                        Self.lastDevelopmentTeamIdentifierKey
                )
            }
            loadedTailnetTarget = tailnetTarget
            savedRenewalTarget = hasGuidedTarget ? target : nil
            savedRenewalMode = hasGuidedTarget ? renewalMode : nil
            savedConnectionRoute = tailnetTarget == nil
                ? .automatic
                : .tailnet
            guidedTargetMigrationSnapshot = nil
            isConfigured = true
            configurationIsDirty = false
            refresh()
            return true
        } catch {
            presentVerbatimError(error.localizedDescription)
            return false
        }
    }

    func announceSettingsSaved() {
        settingsSaveConfirmationGeneration += 1
    }

    func loadBundledSample() {
        guard let runner = bundledIOSRenewalHelperURL(),
              let resources = Bundle.main.resourceURL
        else {
            presentProductError(
                "SideRefresh에 포함된 iOS 앱 갱신 도구를 찾을 수 없습니다. 앱을 다시 설치해 주세요."
            )
            return
        }
        let project = resources
            .appendingPathComponent("Samples", isDirectory: true)
            .appendingPathComponent("SideRefreshSampleApp", isDirectory: true)
            .appendingPathComponent("SideRefreshSample.xcodeproj")
        guard FileManager.default.isExecutableFile(atPath: runner.path),
              FileManager.default.fileExists(atPath: project.path)
        else {
            presentProductError(
                "SideRefresh 앱 안에서 예제 프로젝트를 찾을 수 없습니다. 앱을 다시 설치해 주세요."
            )
            return
        }

        let currentDeviceIdentifier =
            target.deviceIdentifier.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        let rememberedDeviceIdentifier =
            UserDefaults.standard.string(
                forKey: Self.selectedCoreDeviceIdentifierKey
            ) ?? ""
        let selectedDeviceIdentifier =
            currentDeviceIdentifier.hasPrefix("REPLACE_")
                || currentDeviceIdentifier.isEmpty
            ? rememberedDeviceIdentifier
            : currentDeviceIdentifier
        let preferredTeamIdentifiers = [
            target.developmentTeam,
            UserDefaults.standard.string(
                forKey:
                    Self.lastDevelopmentTeamIdentifierKey
            ) ?? "",
        ]

        executablePath = runner.path
        target = RenewalTargetDraft()
        target.containerPath = project.path
        target.scheme = "SideRefreshSample"
        target.configuration = "Release"
        target.developmentTeam = ""
        target.bundleIdentifier = Self.sampleBundleIdentifier
        target.productName = "SideRefreshSample"
        target.sourceMarketingVersion = "1.0"
        target.sourceBuildVersion = "1"
        target.deviceIdentifier = selectedDeviceIdentifier
        target.derivedDataPath = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(
                "Library/Caches/SideRefresh/SampleDerivedData",
                isDirectory: true
            )
            .path
        renewalMode = .dryRun
        buildStrategy = .incremental
        versionPolicy = .keep
        connectionRoute = .automatic
        loadedTailnetTarget = nil
        hasGuidedTarget = true
        syncArgumentsPreview()
        renewEveryHours = RenewalInterval.personalTeamDefault.hours
        renewalSummary = "이 Mac의 Personal Team을 확인하는 중…"
        startPersonalTeamDiscovery(
            preferredTeamIdentifiers:
                preferredTeamIdentifiers,
            repairingBundledSample: true
        )
    }

    private func startPersonalTeamDiscovery(
        preferredTeamIdentifiers: [String]? = nil,
        includeSigningIdentities: Bool = false,
        repairingBundledSample: Bool = false
    ) {
        personalTeamDiscoveryGeneration += 1
        let generation = personalTeamDiscoveryGeneration
        personalTeamDiscoveryTask?.cancel()
        isDiscoveringPersonalTeam = true
        personalTeamSelection = nil
        let containerPath = target.containerPath
        let derivedDataPath = target.derivedDataPath
        let preferred = preferredTeamIdentifiers ?? [
            target.developmentTeam,
            UserDefaults.standard.string(
                forKey:
                    Self.lastDevelopmentTeamIdentifierKey
            ) ?? "",
        ]
        personalTeamDiscoveryTask = Task { [weak self] in
            let selection = await Task.detached(
                priority: .userInitiated
            ) {
                Self.discoverPersonalTeam(
                    preferredTeamIdentifiers: preferred,
                    containerPath: containerPath,
                    derivedDataPath: derivedDataPath,
                    includeSigningIdentities:
                        includeSigningIdentities
                )
            }.value
            guard let self,
                  !Task.isCancelled,
                  generation == self.personalTeamDiscoveryGeneration,
                  containerPath == self.target.containerPath
            else {
                return
            }
            self.isDiscoveringPersonalTeam = false
            self.personalTeamSelection = selection
            switch selection {
            case .selected(let candidate):
                self.target.developmentTeam = candidate.identifier
                if repairingBundledSample {
                    self.target.bundleIdentifier =
                        Self.sampleBundleIdentifier
                }
                self.syncArgumentsPreview()
                self.configurationIsDirty = true
                self.renewalSummary = Self.personalTeamSummary(
                    for: candidate
                )
            case .confirmationRequired:
                self.renewalSummary =
                    "Apple Development 인증서에서 Team 후보를 찾았습니다. Xcode에서 Personal Team인지 확인한 뒤 직접 선택해 주세요."
            case .notFound:
                self.renewalSummary =
                    "Personal Team 준비가 필요합니다. 앱 화면의 가이드를 확인하세요."
            case .ambiguous:
                self.renewalSummary =
                    "Personal Team이 여러 개입니다. 사용할 Team ID를 직접 선택해 주세요."
            }
        }
    }

    nonisolated private static func discoverPersonalTeam(
        preferredTeamIdentifiers: [String],
        containerPath: String,
        derivedDataPath: String,
        includeSigningIdentities: Bool
    ) -> PersonalTeamSelection {
        let projectTeamIdentifiers =
            XcodeContainerScanner().candidate(
                for: URL(fileURLWithPath: containerPath),
                relativeTo: FileManager.default
                    .homeDirectoryForCurrentUser
            )?.applications.compactMap(\.developmentTeam)
            ?? []
        let reader = ProvisioningProfileReader(
            runner: BoundedProcessRunner(executionTimeout: 3)
        )
        let profiles = localProvisioningProfileURLs(
            derivedDataPath: derivedDataPath
        )
            .prefix(64)
            .compactMap {
                try? reader.read(profileURL: $0)
            }
        let identityTeamIdentifiers =
            includeSigningIdentities
            ? (
                try? AppleDevelopmentIdentityReader()
                    .readTeamIdentifiers()
            ) ?? []
            : []
        return PersonalTeamSelector.select(
            from: profiles,
            projectTeamIdentifiers:
                projectTeamIdentifiers,
            signingIdentityTeamIdentifiers:
                identityTeamIdentifiers,
            preferredTeamIdentifiers:
                preferredTeamIdentifiers
        )
    }

    nonisolated private static func localProvisioningProfileURLs(
        derivedDataPath: String
    )
        -> [URL]
    {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        var urls: [URL] = []
        let selectedDerivedDataURL = URL(
            fileURLWithPath: derivedDataPath
        )
        urls.append(
            contentsOf: EmbeddedProvisioningProfileLocator.profiles(
                inDerivedDataURL: selectedDerivedDataURL
            )
        )
        for derivedDataName in [
            "DerivedData",
            "SampleDerivedData",
        ] {
            let derivedDataURL = home.appendingPathComponent(
                "Library/Caches/SideRefresh/\(derivedDataName)",
                isDirectory: true
            )
            urls.append(
                contentsOf: EmbeddedProvisioningProfileLocator.profiles(
                    inDerivedDataURL: derivedDataURL
                )
            )
        }

        for directory in [
            home.appendingPathComponent(
                "Library/Developer/Xcode/UserData/Provisioning Profiles",
                isDirectory: true
            ),
            home.appendingPathComponent(
                "Library/MobileDevice/Provisioning Profiles",
                isDirectory: true
            ),
        ] {
            let contents = (
                try? fileManager.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: [
                        .isRegularFileKey,
                        .contentModificationDateKey,
                    ],
                    options: [.skipsHiddenFiles]
                )
            ) ?? []
            urls.append(
                contentsOf: contents
                    .filter {
                        ["mobileprovision", "provisionprofile"]
                            .contains($0.pathExtension.lowercased())
                    }
                    .sorted {
                        let lhs = try? $0.resourceValues(
                            forKeys: [.contentModificationDateKey]
                        ).contentModificationDate
                        let rhs = try? $1.resourceValues(
                            forKeys: [.contentModificationDateKey]
                        ).contentModificationDate
                        return (lhs ?? .distantPast)
                            > (rhs ?? .distantPast)
                    }
            )
        }

        var seen: Set<URL> = []
        return urls.filter {
            seen.insert($0).inserted
        }
    }

    func rediscoverPersonalTeam() {
        let preferred = Self.isValidDevelopmentTeamIdentifier(
            target.developmentTeam
        )
            ? [target.developmentTeam]
            : []
        renewalSummary =
            "이 Mac의 Personal Team과 Apple Development 인증서를 확인하는 중…"
        startPersonalTeamDiscovery(
            preferredTeamIdentifiers: preferred,
            includeSigningIdentities: true
        )
    }

    func usePersonalTeamCandidate(
        _ candidate: PersonalTeamCandidate
    ) {
        target.developmentTeam = candidate.identifier
        personalTeamSelection = .selected(candidate)
        syncArgumentsPreview()
        configurationIsDirty = true
        renewalSummary = Self.personalTeamSummary(
            for: candidate
        )
    }

    nonisolated private static func personalTeamSummary(
        for candidate: PersonalTeamCandidate
    ) -> String {
        switch candidate.source {
        case .xcodeProject:
            return "Xcode 프로젝트에서 Team ID \(candidate.identifier)을 확인했습니다."
        case .activeLocalProvision:
            return "Personal Team \(candidate.identifier)을 확인했습니다."
        case .expiredLocalProvision:
            return "Team ID \(candidate.identifier)을 찾았습니다. Xcode에서 서명 준비를 새로 확인하세요."
        case .appleDevelopmentIdentity:
            return "Apple Development Team \(candidate.identifier)을 찾았습니다. Xcode에서 Personal Team인지 확인하세요."
        }
    }

    private static func isValidDevelopmentTeamIdentifier(
        _ value: String
    ) -> Bool {
        value.count == 10
            && value.rangeOfCharacter(
                from: CharacterSet.alphanumerics.inverted
            ) == nil
    }

    private static let sampleBundleIdentifier =
        "io.github.siderefresh.sample"

    func addProjectContainer() async -> String? {
        let panel = NSOpenPanel()
        panel.title = SideRefreshLocalization.string(
            "Xcode 프로젝트 직접 선택"
        )
        panel.message =
            SideRefreshLocalization.string(
                "앱을 여는 데 사용하는 .xcworkspace 또는 .xcodeproj 파일을 선택하세요. 둘 다 있으면 .xcworkspace를 권장합니다."
            )
        panel.prompt = SideRefreshLocalization.string(
            "이 프로젝트 선택"
        )
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.resolvesAliases = true
        panel.treatsFilePackagesAsDirectories = false
        panel.allowedContentTypes = [
            UTType(filenameExtension: "xcodeproj"),
            UTType(filenameExtension: "xcworkspace"),
        ].compactMap { $0 }
        if !target.containerPath.isEmpty {
            panel.directoryURL = URL(
                fileURLWithPath: target.containerPath
            ).deletingLastPathComponent()
        } else {
            panel.directoryURL = FileManager.default
                .homeDirectoryForCurrentUser
        }
        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }
        let homeURL =
            FileManager.default.homeDirectoryForCurrentUser
        let candidate = await Task.detached(
            priority: .userInitiated
        ) {
            XcodeContainerScanner().candidate(
                for: url,
                relativeTo: homeURL
            )
        }.value
        guard !Task.isCancelled else {
            return nil
        }
        guard let candidate else {
            presentProductError(
                "iOS 앱이 포함된 Xcode 프로젝트(.xcodeproj) 또는 워크스페이스(.xcworkspace)를 선택하세요."
            )
            return nil
        }
        manuallyAddedProjectPaths.insert(candidate.id)
        mergeDiscoveredContainers([candidate])
        projectScanMessage = .format(
            "%@ 항목을 목록에 추가했습니다.",
            .localizedKey(candidate.kind.localizedLabel)
        )
        return candidate.id
    }

    func chooseProjectSearchFolder() {
        chooseProjectSearchFolder(matching: nil)
    }

    func requestProjectSearchAccess(
        for location: ProjectSearchLocationAccess
    ) {
        switch location.status {
        case .selectionRequired, .missing:
            chooseProjectSearchFolder(matching: location)
        case .verificationRequired,
             .allowed,
             .partiallyBlocked,
             .blocked:
            if location.kind == .home {
                rescanHomeDirectory()
            } else {
                startProjectScan(
                    rootURL: location.url,
                    description: projectSearchLocationTitle(
                        for: location
                    )
                )
            }
        case .checking:
            break
        }
    }

    func prepareProjectSearch() {
        refreshProjectSearchLocationCatalog()
        var requests: [ProjectScanRequest] = []
        if !hasRequestedHomeScan {
            hasRequestedHomeScan = true
            requests.append(
                ProjectScanRequest(
                    rootURL:
                        FileManager.default
                            .homeDirectoryForCurrentUser,
                    description: .key(
                        "허용된 검색 위치"
                    )
                )
            )
        }
        requests.append(
            contentsOf: standaloneProjectScanRequests()
        )
        startProjectScanSequence(requests)
    }

    func openFilesAndFoldersPrivacySettings() {
        guard let url = URL(
            string:
                "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func chooseProjectSearchFolder(
        matching expectedLocation: ProjectSearchLocationAccess?
    ) {
        let panel = NSOpenPanel()
        let expectedTitle = expectedLocation.map {
            projectSearchLocationTitle(for: $0)
        }
        panel.title =
            expectedTitle.map {
                SideRefreshLocalizedText.format(
                    "%@ 접근 확인",
                    .verbatim($0.resolved())
                ).resolved()
            }
            ?? SideRefreshLocalization.string(
                "프로젝트가 있는 폴더 선택"
            )
        if let expectedLocation {
            panel.message = SideRefreshLocalization.format(
                "왼쪽에서 ‘%@’ 폴더를 연 다음, 오른쪽 아래 ‘이 위치 확인’을 눌러 주세요.",
                expectedLocation.url.lastPathComponent
            )
        } else {
            panel.message =
                SideRefreshLocalization.string(
                    "선택한 폴더와 그 안의 하위 폴더에서 Xcode 프로젝트 설정과 앱 아이콘을 확인합니다. 소스 파일은 읽거나 수정하지 않습니다."
                )
        }
        panel.prompt =
            expectedLocation == nil
            ? SideRefreshLocalization.string("이 폴더에서 찾기")
            : SideRefreshLocalization.string("이 위치 확인")
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.resolvesAliases = true
        panel.treatsFilePackagesAsDirectories = false
        panel.allowedContentTypes = [.folder]
        panel.directoryURL =
            expectedLocation?.url.deletingLastPathComponent()
            ?? FileManager.default.homeDirectoryForCurrentUser
        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }
        let selectedURL = url.standardizedFileURL
        if let expectedLocation,
           selectedURL != expectedLocation.url.standardizedFileURL
        {
            presentVerbatimError(
                SideRefreshLocalization.format(
                    "‘%@’ 폴더를 선택해 주세요. 다른 위치는 아래 ‘다른 위치에서 찾기’에서 추가할 수 있습니다.",
                    expectedLocation.url.lastPathComponent
                )
            )
            return
        }
        selectedProjectSearchFolderPaths.insert(selectedURL.path)
        saveSelectedProjectSearchFolders()
        refreshProjectSearchLocationCatalog()
        updateProjectSearchLocation(
            at: selectedURL,
            status: .checking
        )
        startProjectScan(
            rootURL: selectedURL,
            description:
                expectedTitle
                ?? .verbatim(selectedURL.lastPathComponent)
        )
    }

    func rescanHomeDirectory() {
        hasRequestedHomeScan = true
        startProjectScan(
            rootURL: FileManager.default.homeDirectoryForCurrentUser,
            description: .key(
                "허용된 검색 위치"
            )
        )
    }

    func refreshProjectSearchAccessAfterActivation() {
        guard !isScanningProjects else {
            return
        }
        let selectedPaths = selectedProjectSearchFolderPaths
        let locations = projectSearchLocations.filter {
            $0.kind != .home
                && selectedPaths.contains($0.id)
                && (
                    $0.status == .allowed
                        || $0.status == .partiallyBlocked
                        || $0.status == .blocked
                )
        }
        guard !locations.isEmpty else {
            return
        }
        projectSearchAccessTask?.cancel()
        projectSearchAccessTask = Task { [weak self] in
            let results = await Task.detached(
                priority: .utility
            ) {
                locations.map {
                    (
                        $0,
                        Self.probeProjectSearchAccess(at: $0.url)
                    )
                }
            }.value
            guard !Task.isCancelled, let self else {
                return
            }
            var gainedLocations: [ProjectSearchLocationAccess] = []
            var lostLocationURLs: [URL] = []
            for (location, probe) in results {
                let status = ProjectSearchLocationAccess
                    .resolvedStatusAfterRootProbe(
                        probe: probe,
                        previousStatus: location.status
                    )
                if location.status == .blocked,
                   status == .allowed
                {
                    gainedLocations.append(location)
                } else if (
                    location.status == .allowed
                        || location.status == .partiallyBlocked
                ),
                          status != .allowed,
                          status != .partiallyBlocked
                {
                    lostLocationURLs.append(location.url)
                }
                self.updateProjectSearchLocation(
                    at: location.url,
                    status: status
                )
            }
            self.projectSearchAccessTask = nil
            if !lostLocationURLs.isEmpty {
                self.removeDiscoveredContainers(
                    inside: lostLocationURLs
                )
            }
            if !gainedLocations.isEmpty {
                self.startProjectScanSequence(
                    gainedLocations.map {
                        ProjectScanRequest(
                            rootURL: $0.url,
                            description:
                                self.projectSearchLocationTitle(
                                    for: $0
                                )
                        )
                    }
                )
            }
        }
    }

    func cancelProjectScan() {
        projectSearchAccessTask?.cancel()
        projectSearchAccessTask = nil
        cancelActiveProjectScan()
        queuedProjectScanRequests.removeAll()
        isScanningProjects = false
        projectScanMessage = .key(
            "검색을 중단했습니다. 기존 결과는 그대로 사용할 수 있습니다."
        )
    }

    func cancelProjectSearchActivity() {
        projectSearchAccessTask?.cancel()
        projectSearchAccessTask = nil
        if isScanningProjects {
            cancelProjectScan()
        }
    }

    @discardableResult
    func useXcodeContainer(_ path: String) -> Bool {
        guard let candidate = discoveredXcodeContainers.first(
            where: { $0.id == path }
        ) else {
            return false
        }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(
            atPath: candidate.id,
            isDirectory: &isDirectory
        ),
              isDirectory.boolValue
        else {
            discoveredXcodeContainers.removeAll { $0.id == path }
            manuallyAddedProjectPaths.remove(path)
            cacheDiscoveredContainers()
            presentProductError(
                "선택한 프로젝트가 이동되었거나 삭제되었습니다. 다시 찾아 선택하세요."
            )
            return false
        }
        let selection = XcodeContainerSelection(candidate: candidate)
        var updatedTarget = target
        updatedTarget.containerPath = selection.containerPath
        updatedTarget.scheme = selection.scheme
        updatedTarget.appDisplayName = selection.displayName
        updatedTarget.productName = selection.productName
        updatedTarget.bundleIdentifier = selection.bundleIdentifier
        updatedTarget.developmentTeam =
            SimpleAppSelectionTeamPolicy.resolve(
                detected: selection.developmentTeam,
                current: target.developmentTeam,
                remembered: UserDefaults.standard.string(
                    forKey: Self.lastDevelopmentTeamIdentifierKey
                ) ?? ""
            )
        updatedTarget.sourceMarketingVersion =
            selection.marketingVersion
        updatedTarget.sourceBuildVersion = selection.buildVersion
        if let application = candidate.unambiguousApplication {
            if application.unambiguousSchemeName == nil {
                projectScanMessage =
                    application.schemeNames.isEmpty
                    ? .key(
                        "앱 정보를 채웠습니다. 앱 구성(Scheme)과 Apple 팀 ID를 Xcode에서 확인해 주세요."
                    )
                    : .key(
                        "앱 구성이 여러 개입니다. Xcode에서 사용할 Scheme을 직접 확인해 주세요."
                    )
            } else if application.developmentTeam == nil {
                projectScanMessage =
                    updatedTarget.developmentTeam.isEmpty
                    ? .key(
                        "앱 정보를 채웠습니다. Apple 개발 팀 ID는 Xcode에서 확인해 주세요."
                    )
                    : .key(
                        "앱 정보를 채우고 저장된 Apple 개발 팀 ID를 사용했습니다."
                    )
            } else {
                projectScanMessage = .key(
                    "선택한 앱의 빌드 및 서명 정보를 자동으로 채웠습니다."
                )
            }
        } else if candidate.applications.count > 1 {
            projectScanMessage = .key(
                "설치 가능한 앱이 여러 개입니다. 아래 빌드 정보를 직접 확인해 주세요."
            )
        } else {
            projectScanMessage = .key(
                "설치 가능한 앱 정보를 자동으로 확인하지 못했습니다. Xcode에서 빌드 정보를 확인해 주세요."
            )
        }
        target = updatedTarget
        sortDiscoveredContainers()
        loadConfiguredXcodeContainer(
            URL(fileURLWithPath: updatedTarget.containerPath)
        )
        return true
    }

    func loadConfiguredXcodeContainer(_ url: URL) {
        cancelPendingAppVersionReload()
        invalidateConfiguredXcodeContainerLoad()
        let generation = configuredContainerLoadGeneration
        let versionRequest = appVersionResolutionRequest(for: url)
        let homeURL =
            FileManager.default.homeDirectoryForCurrentUser
        let appVersionResolver = appVersionResolver
        configuredContainerLoadTask = Task.detached(
            priority: .utility
        ) { [weak self] in
            let candidate = XcodeContainerScanner().candidate(
                for: url,
                relativeTo: homeURL
            )
            guard !Task.isCancelled, let candidate else {
                return
            }
            let resolvedVersion: IOSAppVersion?
            if let versionRequest {
                do {
                    resolvedVersion = try await appVersionResolver.resolve(
                        query: versionRequest.query,
                        buildSettingOverrides:
                            versionRequest.buildSettingOverrides
                    )
                } catch is CancellationError {
                    return
                } catch {
                    resolvedVersion = nil
                }
            } else {
                resolvedVersion = nil
            }
            guard !Task.isCancelled else {
                return
            }
            await self?.publishConfiguredXcodeContainer(
                candidate,
                resolvedVersion: resolvedVersion,
                versionRequest: versionRequest,
                generation: generation
            )
        }
    }

    private func publishConfiguredXcodeContainer(
        _ candidate: XcodeContainerCandidate,
        resolvedVersion: IOSAppVersion?,
        versionRequest: AppVersionResolutionRequest?,
        generation: Int
    ) {
        guard generation == configuredContainerLoadGeneration else {
            return
        }
        mergeDiscoveredContainers([candidate])
        guard target.containerPath == candidate.id else {
            configuredContainerLoadTask = nil
            return
        }
        let currentRequest = appVersionResolutionRequest(
            for: URL(fileURLWithPath: target.containerPath)
        )
        guard versionRequest == currentRequest else {
            configuredContainerLoadTask = nil
            return
        }
        let application = candidate.applications.first {
            $0.bundleIdentifier == target.bundleIdentifier
        }
        if let application {
            var updatedTarget = target
            updatedTarget.appDisplayName = application.displayName
            let projectMetadataVersion = IOSAppVersion(
                marketingVersion: application.marketingVersion ?? "",
                buildVersion: application.buildVersion ?? ""
            )
            let detectedVersion = AppVersionResolutionPolicy.resolve(
                xcode: resolvedVersion,
                projectMetadata: projectMetadataVersion
            )
            let versionChanged: Bool
            if let detectedVersion {
                versionChanged =
                    updatedTarget.sourceMarketingVersion
                        != detectedVersion.marketingVersion
                    || updatedTarget.sourceBuildVersion
                        != detectedVersion.buildVersion
                updatedTarget.sourceMarketingVersion =
                    detectedVersion.marketingVersion
                updatedTarget.sourceBuildVersion =
                    detectedVersion.buildVersion
            } else {
                versionChanged = false
            }
            if updatedTarget != target {
                if versionPolicy == .automatic && versionChanged {
                    target = updatedTarget
                } else {
                    let wasDirty = configurationIsDirty
                    isLoadingConfiguration = true
                    target = updatedTarget
                    if !wasDirty {
                        savedRenewalTarget = updatedTarget
                    }
                    isLoadingConfiguration = false
                }
            }
        }
        configuredContainerLoadTask = nil
    }

    func appVersionResolutionRequest(
        for containerURL: URL
    ) -> AppVersionResolutionRequest? {
        makeAppVersionResolutionRequest(
            for: target,
            containerURL: containerURL
        )
    }

    func appVersionResolutionRequest(
        for draft: RenewalTargetDraft
    ) -> AppVersionResolutionRequest? {
        let path = draft.containerPath.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !path.isEmpty else {
            return nil
        }
        return makeAppVersionResolutionRequest(
            for: draft,
            containerURL: URL(fileURLWithPath: path)
        )
    }

    private func makeAppVersionResolutionRequest(
        for draft: RenewalTargetDraft,
        containerURL: URL
    ) -> AppVersionResolutionRequest? {
        let derivedDataPath = draft.derivedDataPath.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !derivedDataPath.isEmpty else {
            return nil
        }
        return AppVersionResolutionRequest(
            containerURL: containerURL,
            scheme: draft.scheme,
            configuration: draft.configuration,
            bundleIdentifier: draft.bundleIdentifier,
            derivedDataURL: URL(
                fileURLWithPath: derivedDataPath
            ),
            developmentTeam: draft.developmentTeam
        )
    }

    func invalidateConfiguredXcodeContainerLoad() {
        configuredContainerLoadGeneration += 1
        configuredContainerLoadTask?.cancel()
        configuredContainerLoadTask = nil
    }

    func waitForConfiguredXcodeContainerLoad() async {
        let task = configuredContainerLoadTask
        await task?.value
    }

    func restoreTargetAfterCancelledAppSelection(
        _ previousTarget: RenewalTargetDraft,
        configurationWasDirty: Bool
    ) {
        cancelPendingAppVersionReload()
        invalidateConfiguredXcodeContainerLoad()
        let wasLoadingConfiguration = isLoadingConfiguration
        isLoadingConfiguration = true
        target = previousTarget
        isLoadingConfiguration = wasLoadingConfiguration
        configurationIsDirty = configurationWasDirty
        refresh()
    }

    @discardableResult
    func useGuidedTargetEditor() -> Bool {
        guard let helperURL = bundledIOSRenewalHelperURL() else {
            presentProductError(
                "SideRefresh에 포함된 iOS 앱 갱신 도구를 찾을 수 없습니다. 앱을 다시 설치해 주세요."
            )
            return false
        }
        if isConfigured,
           !hasGuidedTarget,
           guidedTargetMigrationSnapshot == nil
        {
            guidedTargetMigrationSnapshot =
                GuidedTargetMigrationSnapshot(
                    selectedDeviceIdentifier:
                        UserDefaults.standard.string(
                            forKey:
                                Self.selectedCoreDeviceIdentifierKey
                        ),
                    selectedDeviceName:
                        UserDefaults.standard.string(
                            forKey:
                                Self.selectedCoreDeviceNameKey
                        ),
                    selectedDeviceMarketingName:
                        UserDefaults.standard.string(
                            forKey:
                                Self.selectedCoreDeviceMarketingNameKey
                        ),
                    selectedDeviceOperatingSystemVersion:
                        UserDefaults.standard.string(
                            forKey: Self
                                .selectedCoreDeviceOperatingSystemVersionKey
                        )
                )
        }
        executablePath = helperURL.path
        hasGuidedTarget = true
        target = RenewalTargetDraft()
        renewalMode = .dryRun
        buildStrategy = .incremental
        versionPolicy = .keep
        markConfigurationDirty()
        return true
    }

    func cancelGuidedTargetMigration() {
        coreDeviceDiscoveryGeneration += 1
        coreDeviceDiscoveryTimeoutTimer?.invalidate()
        coreDeviceDiscoveryTimeoutTimer = nil
        isDiscoveringCoreDevices = false

        personalTeamDiscoveryGeneration += 1
        personalTeamDiscoveryTask?.cancel()
        personalTeamDiscoveryTask = nil
        isDiscoveringPersonalTeam = false
        personalTeamSelection = nil

        cancelPendingAppVersionReload()
        invalidateConfiguredXcodeContainerLoad()
        cancelProjectSearchActivity()
        restoreGuidedTargetMigrationPreferences()
        loadConfiguration()
    }

    private func restoreGuidedTargetMigrationPreferences() {
        guard let snapshot = guidedTargetMigrationSnapshot else {
            return
        }
        restoreUserDefault(
            snapshot.selectedDeviceIdentifier,
            forKey: Self.selectedCoreDeviceIdentifierKey
        )
        restoreUserDefault(
            snapshot.selectedDeviceName,
            forKey: Self.selectedCoreDeviceNameKey
        )
        restoreUserDefault(
            snapshot.selectedDeviceMarketingName,
            forKey: Self.selectedCoreDeviceMarketingNameKey
        )
        restoreUserDefault(
            snapshot.selectedDeviceOperatingSystemVersion,
            forKey: Self.selectedCoreDeviceOperatingSystemVersionKey
        )
        rememberedCoreDeviceName =
            snapshot.selectedDeviceName ?? ""
        rememberedCoreDeviceMarketingName =
            snapshot.selectedDeviceMarketingName ?? ""
        guidedTargetMigrationSnapshot = nil
    }

    private func restoreUserDefault(
        _ value: String?,
        forKey key: String
    ) {
        if let value {
            UserDefaults.standard.set(value, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    func discoverCoreDevices() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.discoverCoreDevices()
            }
            return
        }
        guard !isDiscoveringCoreDevices else {
            return
        }
        coreDeviceDiscoveryGeneration += 1
        let generation = coreDeviceDiscoveryGeneration
        coreDeviceDiscoveryTimeoutTimer?.invalidate()
        isDiscoveringCoreDevices = true
        coreDeviceMessage = .key(
            "Xcode에서 페어링된 iPhone을 찾는 중…"
        )
        let completion:
            @MainActor @Sendable (CoreDeviceDiscoveryOutcome) -> Void =
        { [weak self] outcome in
            self?.finishCoreDeviceDiscovery(
                outcome,
                generation: generation
            )
        }
        coreDeviceDiscoveryQueue.async {
            let outcome: CoreDeviceDiscoveryOutcome
            do {
                outcome = .success(try CoreDeviceReader().read())
            } catch {
                outcome = .failure(
                    .verbatim(error.localizedDescription)
                )
            }
            Self.performOnMainRunLoop {
                completion(outcome)
            }
        }
        let timeoutTimer = Timer(
            timeInterval: 20,
            repeats: false
        ) { _ in
            MainActor.assumeIsolated {
                completion(
                    .failure(
                        .productKey(
                            "Xcode의 iPhone 목록 확인 시간이 초과되었습니다. Xcode에서 iPhone 연결 상태를 확인한 뒤 다시 시도해 주세요."
                        )
                    )
                )
            }
        }
        RunLoop.main.add(timeoutTimer, forMode: .common)
        coreDeviceDiscoveryTimeoutTimer = timeoutTimer
    }

    private nonisolated static func performOnMainRunLoop(
        _ operation: @escaping @MainActor @Sendable () -> Void
    ) {
        let mainRunLoop = CFRunLoopGetMain()
        CFRunLoopPerformBlock(
            mainRunLoop,
            CFRunLoopMode.commonModes.rawValue as CFString
        ) {
            MainActor.assumeIsolated {
                operation()
            }
        }
        CFRunLoopWakeUp(mainRunLoop)
    }

    private func finishCoreDeviceDiscovery(
        _ outcome: CoreDeviceDiscoveryOutcome,
        generation: Int
    ) {
        guard generation == coreDeviceDiscoveryGeneration,
              isDiscoveringCoreDevices
        else {
            return
        }
        coreDeviceDiscoveryTimeoutTimer?.invalidate()
        coreDeviceDiscoveryTimeoutTimer = nil
        isDiscoveringCoreDevices = false
        coreDeviceDiscoveryHasCompleted = true
        switch outcome {
        case let .success(snapshot):
            let paired = snapshot.pairedIPhones
            pairedCoreDevices = paired
            let currentUDID = target.deviceIdentifier
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            if paired.isEmpty {
                if snapshot.iPhones.isEmpty {
                    coreDeviceMessage = .key(
                        "Xcode가 알고 있는 iPhone을 찾지 못했습니다."
                    )
                } else {
                    coreDeviceMessage = .format(
                        "iPhone %ld대를 찾았지만 먼저 Xcode에서 페어링해야 합니다.",
                        .integer(snapshot.iPhones.count)
                    )
                }
            } else if let current = paired.first(where: {
                $0.udid == currentUDID
            }) {
                rememberCoreDevice(current)
                coreDeviceMessage = coreDevicePairedMessage(current)
            } else if !currentUDID.isEmpty {
                coreDeviceMessage = .format(
                    "페어링된 iPhone %ld대를 찾았습니다. 현재 직접 입력한 UDID를 유지합니다.",
                    .integer(paired.count)
                )
            } else {
                coreDeviceMessage = .format(
                    "페어링된 iPhone %ld대를 찾았습니다. 사용할 기기를 선택하세요.",
                    .integer(paired.count)
                )
            }
        case let .failure(errorContent):
            pairedCoreDevices = []
            coreDeviceMessage = .key(
                "Xcode의 iPhone 목록을 읽지 못했습니다."
            )
            switch errorContent {
            case let .productKey(localizationKey):
                presentProductError(localizationKey)
            case let .verbatim(message):
                presentVerbatimError(message)
            }
        }
    }

    func selectCoreDevice(udid: String) {
        target.deviceIdentifier = udid
        guard let device = pairedCoreDevices.first(where: {
            $0.udid == udid
        }) else {
            return
        }
        rememberCoreDevice(device)
        coreDeviceMessage = coreDevicePairedMessage(device)
    }

    private func rememberCoreDevice(_ device: CoreDevice) {
        rememberedCoreDeviceName = device.name
        rememberedCoreDeviceMarketingName =
            device.marketingName?.trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""
        UserDefaults.standard.set(
            device.udid,
            forKey: Self.selectedCoreDeviceIdentifierKey
        )
        UserDefaults.standard.set(
            device.name,
            forKey: Self.selectedCoreDeviceNameKey
        )
        if rememberedCoreDeviceMarketingName.isEmpty {
            UserDefaults.standard.removeObject(
                forKey: Self.selectedCoreDeviceMarketingNameKey
            )
        } else {
            UserDefaults.standard.set(
                rememberedCoreDeviceMarketingName,
                forKey: Self.selectedCoreDeviceMarketingNameKey
            )
        }
        let operatingSystemVersion = device.operatingSystemVersion?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if operatingSystemVersion.isEmpty {
            UserDefaults.standard.removeObject(
                forKey:
                    Self.selectedCoreDeviceOperatingSystemVersionKey
            )
        } else {
            UserDefaults.standard.set(
                operatingSystemVersion,
                forKey:
                    Self.selectedCoreDeviceOperatingSystemVersionKey
            )
        }
    }

    private func coreDeviceDisplayLabel(_ device: CoreDevice) -> String {
        RenewalIPhoneNamePolicy.resolve(
            discoveredName: device.name,
            rememberedName: nil,
            deviceIdentifier: device.udid,
            discoveredModelName: device.marketingName
        )
    }

    private func coreDevicePairedMessage(
        _ device: CoreDevice
    ) -> SideRefreshLocalizedText {
        .format(
            "%@ 선택됨 · Xcode의 페어링된 기기 목록에서 확인됨",
            .verbatim(coreDeviceDisplayLabel(device))
        )
    }

    func discoverTailnetDevices() {
        guard !isDiscoveringTailnet else {
            return
        }
        let executableURLs = availableTailscaleExecutableURLs
        guard !executableURLs.isEmpty else {
            tailnetDevices = []
            tailnetDiscoveryHasCompleted = true
            tailnetMessage = .key(
                tailscaleApplicationIsInstalled
                    ? "Tailscale 앱은 발견했지만 상태 명령을 실행할 수 없습니다."
                    : "Mac에 Tailscale 설치가 필요합니다."
            )
            presentProductError(
                TailnetSetupRequirement
                    .installationRequired.userMessage
            )
            return
        }
        isDiscoveringTailnet = true
        tailnetMessage = .key(
            "Tailscale에서 iPhone을 찾는 중…"
        )
        tailnetDiscoveryTask = Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                self.isDiscoveringTailnet = false
                self.tailnetDiscoveryHasCompleted = true
                self.tailnetDiscoveryTask = nil
            }
            do {
                let discovery = try await Task.detached(
                    priority: .userInitiated
                ) {
                    try Self.readConnectedTailnet(
                        executableURLs: executableURLs
                    )
                }.value
                tailscaleExecutablePath = discovery.executable
                tailnetDevices = discovery.snapshot.iOSDevices
                let reconciledNodeID = TailnetSelectionReconciler
                    .selectedNodeID(
                        savedTarget: loadedTailnetTarget,
                        currentNodeID: selectedTailnetNodeID,
                        devices: tailnetDevices
                    ) ?? ""
                isReconcilingTailnetDiscovery = true
                selectedTailnetNodeID = reconciledNodeID
                isReconcilingTailnetDiscovery = false
                if tailnetDevices.isEmpty {
                    tailnetMessage = .key(
                        "Tailscale에 연결된 iPhone을 찾지 못했습니다."
                    )
                } else if loadedTailnetTarget != nil,
                          selectedTailnetNodeID.isEmpty
                {
                    tailnetMessage = .key(
                        "이전에 저장한 iPhone을 찾지 못했습니다. 목록에서 다시 선택해 주세요."
                    )
                } else {
                    let onlineCount = tailnetDevices.filter {
                        $0.isOnline == true
                    }.count
                    tailnetMessage = .format(
                        "iPhone %ld대 발견 · Tailscale 온라인 %ld대",
                        .integer(tailnetDevices.count),
                        .integer(onlineCount)
                    )
                }
            } catch {
                tailnetDevices = []
                tailnetMessage = .key(
                    "Tailscale 기기 목록을 읽지 못했습니다."
                )
                presentVerbatimError(error.localizedDescription)
            }
        }
    }

    func prepareConnectionCheck() {
        renewalRunPresentationState = .idle
        renewalRunCompletedAt = nil
        renewalResultLacksExpirationEvidence = false
        renewalStatusCheckDidFail = false
        renewalProgressEvents = [:]
    }

    func copyCurrentConnectionAddress() {
        guard let address = currentConnectionAddress else {
            presentProductError("복사할 연결 주소가 없습니다.")
            return
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(address, forType: .string)
    }

    func refresh() {
        renewalStatusCheckDidFail = false
        refreshAgentStatus()
        guard isConfigured else {
            renewalSummary = "먼저 갱신할 앱을 설정하세요"
            return
        }
        guard !configurationIsDirty else {
            renewalSummary =
                "대상이 변경되었습니다. 저장 후 현재 대상의 일정을 확인하세요."
            return
        }
        if hasGuidedTarget,
           let missingField = target.firstMissingRequiredField
        {
            renewalSummary = missingField.guidance
            return
        }

        do {
            let configuration = try AgentConfiguration.load(
                from: SideRefreshPaths.defaultConfigurationFile
            )
            let status = try RenewalEngine(
                stateFileURL: configuration.stateFileURL,
                renewalInterval: configuration.renewalInterval
            ).status(for: configuration.command)
            lastSuccessfulRenewal = status.lastSuccessfulRenewal
            nextRenewalDate = status.nextDue
            provisioningExpirationDate =
                status.provisioningExpirationDate
            provisioningProfileIdentifier =
                status.provisioningProfileIdentifier
            if status.isDue {
                renewalSummary =
                    status.provisioningExpirationDate == nil
                    ? "갱신 필요"
                    : "서명 갱신 필요"
            } else if let nextDue = status.nextDue {
                renewalSummary = SideRefreshLocalization.format(
                    "다음 갱신 %@",
                    SideRefreshLocalization.date(
                        nextDue,
                        dateStyle: .medium,
                        timeStyle: .short
                    )
                )
            } else {
                renewalSummary = "갱신 필요"
            }
        } catch {
            renewalStatusCheckDidFail = true
            renewalSummary = "상태 확인 실패"
            presentVerbatimError(error.localizedDescription)
        }
    }

    func testCurrentSetup() {
        guard canTestCurrentSetup else {
            return
        }
        do {
            guard let helperURL = bundledIOSRenewalHelperURL() else {
                presentProductError(
                    "SideRefresh에 포함된 iOS 앱 갱신 도구를 찾을 수 없습니다. 앱을 다시 설치해 주세요."
                )
                return
            }
            let command = try target.profile(
                mode: .dryRun,
                buildStrategy: buildStrategy,
                versionPolicy: versionPolicy
            ).command(
                helperExecutableURL: helperURL
            )
            isWorking = true
            Task {
                do {
                    let result = try await Task.detached(
                        priority: .userInitiated
                    ) {
                        try BoundedProcessRunner(
                            executionTimeout: 30
                        ).run(command)
                    }.value
                    if result.exitCode == 0 {
                        renewalSummary =
                            "설정 테스트 통과 · iPhone 변경 없음"
                    } else if result.standardError.isEmpty {
                        presentVerbatimError(
                            SideRefreshLocalization.format(
                                "설정 테스트를 완료하지 못했습니다(종료 코드 %lld).",
                                Int64(result.exitCode)
                            )
                        )
                    } else {
                        presentVerbatimError(result.standardError)
                    }
                } catch {
                    presentVerbatimError(error.localizedDescription)
                }
                isWorking = false
            }
        } catch {
            presentVerbatimError(error.localizedDescription)
        }
    }

    func renewImmediately() {
        guard canRenewImmediately else {
            if let missingField = target.firstMissingRequiredField {
                presentProductError(missingField.guidance)
            }
            return
        }
        beginRenewalRun()
        isWorking = true
        Task {
            do {
                receiveRenewalUpdate(
                    .progress(
                        RenewalProgressEvent(
                            phase: .preparing,
                            state: .started,
                            message: "저장된 갱신 설정을 읽습니다."
                        )
                    )
                )
                let configuration = try AgentConfiguration.load(
                    from: SideRefreshPaths.defaultConfigurationFile
                )
                receiveRenewalUpdate(
                    .progress(
                        RenewalProgressEvent(
                            phase: .preparing,
                            state: .succeeded,
                            message:
                                "\(target.displayName) 갱신 설정을 확인했습니다."
                        )
                    )
                )
                let updateBuffer = RenewalRunUpdateBuffer()
                let (signals, signalContinuation) =
                    AsyncStream<Void>.makeStream(
                        bufferingPolicy: .bufferingNewest(1)
                    )
                let updateConsumer = Task {
                    [weak self] in
                    for await _ in signals {
                        guard let self else {
                            continue
                        }
                        updateBuffer.drain().forEach {
                            self.receiveRenewalUpdate($0)
                        }
                    }
                    guard let self else {
                        return
                    }
                    updateBuffer.drain().forEach {
                        self.receiveRenewalUpdate($0)
                    }
                }
                let progress: RenewalProgressHandler = { update in
                    updateBuffer.append(update)
                    signalContinuation.yield()
                }
                let workerResult: Result<
                    RenewalRunResult,
                    Error
                >
                do {
                    workerResult = .success(
                        try await Task.detached(
                            priority: .userInitiated
                        ) {
                            try ConfiguredRenewalRunner()
                                .runImmediately(
                                    configuration,
                                    progress: progress
                                )
                        }.value
                    )
                } catch {
                    workerResult = .failure(error)
                }
                signalContinuation.finish()
                await updateConsumer.value

                switch workerResult {
                case .success(let result) where result.succeeded:
                    finishRenewalRun(
                        succeeded: true,
                        message: "앱을 다시 설치하고 갱신 영수증을 저장했습니다."
                    )
                    if result.provisioningExpirationDate == nil {
                        renewalResultLacksExpirationEvidence = true
                        presentProductError(
                            "앱은 설치됐지만 서명 만료일을 기록하지 못했습니다. 안전한 자동 갱신 상태로 판단하지 않습니다."
                        )
                    }
                case .success(let result):
                    let standardError =
                        result.processResult?.standardError ?? ""
                    finishRenewalRun(
                        succeeded: false,
                        message: "앱을 바로 갱신하지 못했습니다."
                    )
                    if let knownMessage =
                        RenewalFailureUserMessage.message(
                            for: standardError
                        )
                    {
                        presentProductError(knownMessage)
                    } else if standardError.isEmpty {
                        presentProductError(
                            "앱을 바로 갱신하지 못했습니다."
                        )
                    } else {
                        presentProductError(
                            "앱을 바로 갱신하지 못했습니다. 상세 로그에서 실패 단계를 확인해 주세요."
                        )
                    }
                case .failure(let error):
                    finishRenewalRun(
                        succeeded: false,
                        message: error.localizedDescription
                    )
                    presentVerbatimError(error.localizedDescription)
                }
            } catch {
                finishRenewalRun(
                    succeeded: false,
                    message: error.localizedDescription
                )
                presentVerbatimError(error.localizedDescription)
            }
            isWorking = false
            refresh()
            renewalSummary =
                renewalRunPresentationState == .succeeded
                ? "방금 다시 설치 성공"
                : "즉시 갱신 실패 · 로그 확인 필요"
        }
    }

    func copyRenewalLog() {
        guard !renewalLogText.isEmpty else {
            return
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(
            renewalLogText,
            forType: .string
        )
    }

    func clearRenewalLog() {
        guard !isWorking else {
            return
        }
        resetRenewalLog()
    }

    private func beginRenewalRun() {
        renewalProgressEvents = [:]
        resetRenewalLog()
        renewalRunCompletedAt = nil
        renewalResultLacksExpirationEvidence = false
        renewalRunPresentationState = .running
        renewalSummary = "갱신 준비 중"
    }

    private func finishRenewalRun(
        succeeded: Bool,
        message: String
    ) {
        let state: RenewalProgressState =
            succeeded ? .succeeded : .failed
        receiveRenewalUpdate(
            .progress(
                RenewalProgressEvent(
                    phase: .completed,
                    state: state,
                    message: message
                )
            )
        )
        renewalRunCompletedAt = Date()
        renewalRunPresentationState =
            succeeded ? .succeeded : .failed
    }

    private func receiveRenewalUpdate(
        _ update: RenewalRunUpdate
    ) {
        switch update {
        case .progress(let event):
            renewalProgressEvents[event.phase] = event
            if renewalRunPresentationState == .running {
                renewalSummary = event.message
            }
            let timestamp = SideRefreshLocalization.date(
                Date(),
                dateStyle: .none,
                timeStyle: .medium
            )
            appendRenewalLog(
                "[\(timestamp)] "
                    + event.message
                    + "\n"
            )
        case .log(let text):
            appendRenewalLog(text)
        }
    }

    private func appendRenewalLog(_ text: String) {
        let maximumCharacters = 300_000
        renewalLogMetrics.append(text)
        renewalLogText.append(text)
        renewalLogCharacterCount += text.count
        if renewalLogCharacterCount > maximumCharacters {
            renewalLogText =
                "[이전 로그 일부 생략]\n"
                + String(
                    renewalLogText.suffix(maximumCharacters)
                )
            renewalLogMetrics.reset(to: renewalLogText)
            renewalLogCharacterCount = renewalLogText.count
            renewalLogMutations.send(.reset(renewalLogText))
        } else {
            renewalLogMutations.send(.append(text))
        }
    }

    private func resetRenewalLog() {
        renewalLogText = ""
        renewalLogCharacterCount = 0
        renewalLogMetrics.reset()
        renewalLogMutations.send(.reset(""))
    }

    func inspectInstalledApp() {
        guard !isInspectingInstalledApp else {
            return
        }
        let deviceIdentifier = target.deviceIdentifier
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let bundleIdentifier = target.bundleIdentifier
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !deviceIdentifier.isEmpty,
              !bundleIdentifier.isEmpty
        else {
            presentProductError(
                "설치할 iPhone과 앱 식별자(Bundle ID)를 먼저 선택해 주세요."
            )
            return
        }
        isInspectingInstalledApp = true
        inspectedDeviceIdentifier = deviceIdentifier
        inspectedBundleIdentifier = bundleIdentifier
        installedAppSummary =
            "선택한 iPhone에서 개발자 앱을 확인하는 중…"
        deviceProfileSummary =
            "Apple Development 프로파일을 확인하는 중…"
        let ideviceprovisionURL = deviceProvisioningToolURL()
        Task {
            do {
                let apps = try await Task.detached(
                    priority: .userInitiated
                ) {
                    try InstalledAppReader().readDeveloperApps(
                        deviceIdentifier: deviceIdentifier
                    )
                }.value
                guard currentInspectionTargetMatches(
                    deviceIdentifier: deviceIdentifier,
                    bundleIdentifier: bundleIdentifier
                ) else {
                    isInspectingInstalledApp = false
                    return
                }
                let app = apps.first {
                    $0.bundleIdentifier == bundleIdentifier
                }
                installedDeveloperApps = apps
                installedDeviceApp = app
                installedAppCheckedAt = Date()
                if let app {
                    installedAppSummary =
                        "개발자 앱 \(apps.count)개 · 갱신 대상 \(app.name) 설치됨"
                } else {
                    installedAppSummary =
                        "개발자 앱 \(apps.count)개 · 갱신 대상 앱은 설치되지 않음"
                }

                if let ideviceprovisionURL {
                    await inspectDeviceProvisioningProfiles(
                        deviceIdentifier: deviceIdentifier,
                        bundleIdentifier: bundleIdentifier,
                        executableURL: ideviceprovisionURL
                    )
                } else {
                    installedProvisioningProfile = nil
                    installedProvisioningProfileMatchesReceipt = false
                    deviceProfileSummary =
                        "실제 Apple Development 프로파일 조회 도구가 설치되지 않았습니다."
                }
            } catch {
                installedDeviceApp = nil
                installedDeveloperApps = []
                installedProvisioningProfile = nil
                installedProvisioningProfileMatchesReceipt = false
                installedAppCheckedAt = nil
                installedAppSummary = "iPhone 설치 상태 확인 실패"
                deviceProfileSummary =
                    "Apple Development 프로파일 확인 안 됨"
                presentVerbatimError(error.localizedDescription)
            }
            isInspectingInstalledApp = false
        }
    }

    private func inspectDeviceProvisioningProfiles(
        deviceIdentifier: String,
        bundleIdentifier: String,
        executableURL: URL
    ) async {
        do {
            let profiles = try await Task.detached(
                priority: .userInitiated
            ) {
                let reader = DeviceProvisioningProfileReader()
                return try reader.readWithUSBThenNetwork(
                    deviceIdentifier: deviceIdentifier,
                    ideviceprovisionURL: executableURL
                )
            }.value
            guard currentInspectionTargetMatches(
                deviceIdentifier: deviceIdentifier,
                bundleIdentifier: bundleIdentifier
            ) else {
                return
            }
            let matches = DeviceProvisioningProfileReader.profiles(
                matching: bundleIdentifier,
                in: profiles
            )
            let exactReceiptMatch = matches.first {
                guard !configurationIsDirty else {
                    return false
                }
                guard let identifier =
                    provisioningProfileIdentifier
                else {
                    return false
                }
                return $0.identifier == identifier
            }
            if let profile = exactReceiptMatch {
                installedProvisioningProfile = profile
                installedProvisioningProfileMatchesReceipt = true
                let signer = profile.developerCertificateNames.first
                    ?? profile.teamName
                    ?? profile.teamIdentifiers.first
                    ?? "Apple Development"
                let expirationDescription = SideRefreshLocalization.date(
                    profile.expirationDate,
                    dateStyle: .medium,
                    timeStyle: .short
                )
                deviceProfileSummary =
                    "\(signer) · SideRefresh 설치 영수증 UUID와 같은 프로파일이 기기에 있음 · 만료 \(expirationDescription)"
            } else if matches.isEmpty {
                installedProvisioningProfile = nil
                installedProvisioningProfileMatchesReceipt = false
                deviceProfileSummary =
                    "선택한 Bundle ID의 프로비저닝 프로파일을 찾지 못했습니다."
            } else if matches.count == 1, let candidate = matches.first {
                installedProvisioningProfile = candidate
                installedProvisioningProfileMatchesReceipt = false
                deviceProfileSummary =
                    "Bundle ID가 맞는 프로파일 후보입니다. SideRefresh 설치 영수증의 UUID와 일치하지 않아 현재 앱의 프로파일로 확정하지 않습니다."
            } else {
                installedProvisioningProfile = nil
                installedProvisioningProfileMatchesReceipt = false
                deviceProfileSummary =
                    "같은 Bundle ID의 프로파일 \(matches.count)개가 있어 현재 앱의 프로파일을 확정하지 못했습니다."
            }
        } catch {
            installedProvisioningProfile = nil
            installedProvisioningProfileMatchesReceipt = false
            deviceProfileSummary = error.localizedDescription
        }
    }

    private func currentInspectionTargetMatches(
        deviceIdentifier: String,
        bundleIdentifier: String
    ) -> Bool {
        target.deviceIdentifier.trimmingCharacters(
            in: .whitespacesAndNewlines
        ) == deviceIdentifier
            && target.bundleIdentifier.trimmingCharacters(
                in: .whitespacesAndNewlines
            ) == bundleIdentifier
    }

    private func clearInstalledAppInspectionIfTargetChanged() {
        guard !inspectedDeviceIdentifier.isEmpty
                || !inspectedBundleIdentifier.isEmpty
        else {
            return
        }
        guard !currentInspectionTargetMatches(
            deviceIdentifier: inspectedDeviceIdentifier,
            bundleIdentifier: inspectedBundleIdentifier
        ) else {
            return
        }
        inspectedDeviceIdentifier = ""
        inspectedBundleIdentifier = ""
        installedDeviceApp = nil
        installedDeveloperApps = []
        installedProvisioningProfile = nil
        installedProvisioningProfileMatchesReceipt = false
        installedAppCheckedAt = nil
        installedAppSummary =
            "대상이 바뀌었습니다. 새 iPhone의 설치 상태를 확인해 주세요."
        deviceProfileSummary =
            "대상이 바뀌어 Apple Development 정보를 다시 확인해야 합니다."
    }

    private func deviceProvisioningToolURL() -> URL? {
        var candidates: [URL] = []
        if let resourceURL = Bundle.main.resourceURL {
            candidates.append(
                resourceURL.appendingPathComponent(
                    "ideviceprovision"
                )
            )
        }
        candidates.append(
            URL(fileURLWithPath: "/opt/homebrew/bin/ideviceprovision")
        )
        candidates.append(
            URL(fileURLWithPath: "/usr/local/bin/ideviceprovision")
        )
        return candidates.first {
            FileManager.default.isExecutableFile(atPath: $0.path)
        }
    }

    func registerAgent() {
        guard canRegisterAgent else {
            presentProductError(
                hasGuidedTarget && renewalMode != .execute
                ? "자동 갱신을 켜려면 ‘실제 갱신 사용’을 선택해 저장해 주세요. 설정 테스트는 백그라운드 일정으로 등록하지 않습니다."
                : "변경한 앱과 갱신 설정을 먼저 저장해 주세요."
            )
            return
        }
        do {
            try service.register()
            refreshAgentStatus()
        } catch {
            presentVerbatimError(error.localizedDescription)
            refreshAgentStatus()
        }
    }

    func unregisterAgent() {
        do {
            try service.unregister()
            refreshAgentStatus()
        } catch {
            presentVerbatimError(error.localizedDescription)
            refreshAgentStatus()
        }
    }

    func openLoginItemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    func refreshAgentStatus() {
        let status = service.status
        cachedServiceStatus = status
        let summary: String
        switch status {
        case .notRegistered:
            summary = "백그라운드 갱신 꺼짐"
        case .enabled:
            summary = "백그라운드 갱신 켜짐"
        case .requiresApproval:
            summary = "macOS에서 백그라운드 실행 허용 필요"
        case .notFound:
            summary = "백그라운드 실행 파일을 찾지 못함"
        @unknown default:
            summary = "백그라운드 실행 상태를 확인할 수 없음"
        }
        if agentSummary != summary {
            agentSummary = summary
        }
    }

    private func markConfigurationDirty() {
        guard !isLoadingConfiguration, isConfigured else {
            return
        }
        configurationIsDirty = true
        installedProvisioningProfileMatchesReceipt = false
        if installedProvisioningProfile != nil {
            deviceProfileSummary =
                "대상이 변경되어 이전 설치 영수증과의 일치 표시는 무효화했습니다. 저장 후 다시 확인해 주세요."
        }
        renewalSummary =
            "대상이 변경되었습니다. 저장 후 현재 대상의 일정을 확인하세요."
    }

    private func syncArgumentsPreview() {
        guard let profile = try? target.profile(
            mode: renewalMode,
            buildStrategy: buildStrategy,
            versionPolicy: versionPolicy
        ) else {
            argumentsText = ""
            return
        }
        argumentsText = profile.arguments.joined(separator: "\n")
    }

    private func loadProjectSearchLocations() {
        selectedProjectSearchFolderPaths = Set(
            UserDefaults.standard.stringArray(
                forKey:
                    Self.selectedProjectSearchFolderPathsKey
            ) ?? []
        )
        refreshProjectSearchLocationCatalog()
    }

    private func refreshProjectSearchLocationCatalog() {
        let previousStatuses = Dictionary(
            uniqueKeysWithValues: projectSearchLocations.map {
                ($0.id, $0.status)
            }
        )
        let selectedURLs = selectedProjectSearchFolderPaths.map {
            URL(fileURLWithPath: $0, isDirectory: true)
        }
        projectSearchLocations = ProjectSearchLocationAccess
            .standardLocations(
                homeDirectoryURL:
                    FileManager.default.homeDirectoryForCurrentUser,
                selectedLocationURLs: selectedURLs,
                fileExists: {
                    FileManager.default.fileExists(
                        atPath: $0.path
                    )
                }
            )
            .map { location in
                guard location.status != .missing else {
                    return location
                }
                guard let previousStatus =
                    previousStatuses[location.id]
                else {
                    return location
                }
                var preserved = location
                preserved.status = previousStatus
                return preserved
            }
    }

    private func saveSelectedProjectSearchFolders() {
        UserDefaults.standard.set(
            selectedProjectSearchFolderPaths.sorted(),
            forKey: Self.selectedProjectSearchFolderPathsKey
        )
    }

    private func standaloneProjectScanRequests()
        -> [ProjectScanRequest]
    {
        let home = FileManager.default.homeDirectoryForCurrentUser
            .standardizedFileURL
        let excludedHomeLocations =
            excludedProjectSearchDirectoryURLs(for: home)
        return projectSearchLocations.compactMap { location in
            let isSearchable: Bool
            switch location.status {
            case .verificationRequired,
                 .checking,
                 .allowed,
                 .partiallyBlocked:
                isSearchable = true
            case .selectionRequired, .blocked, .missing:
                isSearchable = false
            }
            return location.kind != .home
                && isSearchable
                && selectedProjectSearchFolderPaths.contains(
                    location.id
                )
                && (
                    !Self.url(location.url, isInside: home)
                        || excludedHomeLocations.contains {
                            Self.url(
                                location.url,
                                isInside: $0
                            )
                        }
                )
                ? ProjectScanRequest(
                    rootURL: location.url,
                    description:
                        projectSearchLocationTitle(for: location)
                )
                : nil
        }
    }

    private func removeDiscoveredContainers(
        inside rootURLs: [URL]
    ) {
        let roots = rootURLs.map(\.standardizedFileURL)
        discoveredXcodeContainers.removeAll { candidate in
            roots.contains {
                Self.url(candidate.url, isInside: $0)
            }
        }
        manuallyAddedProjectPaths = Set(
            manuallyAddedProjectPaths.filter { path in
                let url = URL(fileURLWithPath: path)
                return !roots.contains {
                    Self.url(url, isInside: $0)
                }
            }
        )
        cacheDiscoveredContainers()
    }

    nonisolated private static func probeProjectSearchAccess(
        at url: URL
    ) -> ProjectSearchAccessProbe {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(
            atPath: url.path,
            isDirectory: &isDirectory
        ),
              isDirectory.boolValue
        else {
            return .missing
        }
        do {
            _ = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            return .accessible
        } catch {
            return projectSearchAccessProbe(for: error)
        }
    }

    nonisolated private static func projectSearchAccessProbe(
        for error: Error
    ) -> ProjectSearchAccessProbe {
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain {
            if nsError.code
                == CocoaError.Code.fileReadNoSuchFile.rawValue
            {
                return .missing
            }
            if nsError.code
                == CocoaError.Code.fileReadNoPermission.rawValue
            {
                return .permissionDenied
            }
        }
        if nsError.domain == NSPOSIXErrorDomain,
           nsError.code == Int(EACCES)
                || nsError.code == Int(EPERM)
        {
            return .permissionDenied
        }
        if let underlyingError = nsError.userInfo[
            NSUnderlyingErrorKey
        ] as? NSError,
           underlyingError.domain == NSPOSIXErrorDomain,
           underlyingError.code == Int(EACCES)
                || underlyingError.code == Int(EPERM)
        {
            return .permissionDenied
        }
        return .failed
    }

    private func updateProjectSearchLocation(
        at url: URL,
        status: ProjectSearchAccessStatus
    ) {
        let path = url.standardizedFileURL.path
        guard let index = projectSearchLocations.firstIndex(
            where: { $0.id == path }
        ) else {
            return
        }
        projectSearchLocations[index].status = status
    }

    private func projectSearchLocationTitle(
        for location: ProjectSearchLocationAccess
    ) -> SideRefreshLocalizedText {
        switch location.kind {
        case .home:
            return .key("홈 폴더의 일반 위치")
        case .desktop:
            return .key("데스크탑")
        case .documents:
            return .key("문서")
        case .downloads:
            return .key("다운로드")
        case .custom:
            return .verbatim(location.url.lastPathComponent)
        }
    }

    private func excludedProjectSearchDirectoryURLs(
        for rootURL: URL
    ) -> Set<URL> {
        let home = FileManager.default.homeDirectoryForCurrentUser
            .standardizedFileURL
        guard rootURL.standardizedFileURL == home else {
            return []
        }
        return Set(
            projectSearchLocations.compactMap { location in
                guard location.kind.requiresExplicitSelection else {
                    return nil
                }
                return location.url
            }
        )
    }

    private func beginProjectSearchLocationChecks(
        rootURL: URL,
        excluding excludedURLs: Set<URL>
    ) {
        let root = rootURL.standardizedFileURL
        for index in projectSearchLocations.indices {
            let locationURL =
                projectSearchLocations[index].url
                    .standardizedFileURL
            let isIncluded: Bool
            if root
                == FileManager.default.homeDirectoryForCurrentUser
                    .standardizedFileURL
            {
                isIncluded = Self.url(locationURL, isInside: root)
                    && !excludedURLs.contains {
                        Self.url(locationURL, isInside: $0)
                    }
            } else {
                isIncluded = locationURL == root
            }
            if isIncluded {
                if projectScanPreviousLocationStatuses[
                    projectSearchLocations[index].id
                ] == nil {
                    projectScanPreviousLocationStatuses[
                        projectSearchLocations[index].id
                    ] = restorableProjectSearchStatus(
                        for: projectSearchLocations[index]
                    )
                }
                projectSearchLocations[index].status = .checking
            }
        }
    }

    private func finishProjectSearchLocationChecks(
        rootURL: URL,
        probe: ProjectSearchAccessProbe,
        unreadableLocationURLs: [URL]
    ) {
        let root = rootURL.standardizedFileURL
        for index in projectSearchLocations.indices
        where projectSearchLocations[index].status == .checking {
            let location = projectSearchLocations[index]
            let isIncluded =
                root
                == FileManager.default.homeDirectoryForCurrentUser
                    .standardizedFileURL
                ? Self.url(location.url, isInside: root)
                    && !projectScanExcludedDirectoryURLs.contains {
                        Self.url(location.url, isInside: $0)
                    }
                : location.url.standardizedFileURL == root
            guard isIncluded else {
                continue
            }
            let relevantUnreadableLocationURLs: [URL]
            if location.kind == .home {
                let protectedLocationURLs =
                    ProjectSearchLocationAccess
                        .protectedLocationURLs(
                            homeDirectoryURL: root
                        )
                relevantUnreadableLocationURLs =
                    unreadableLocationURLs.filter { unreadableURL in
                        !protectedLocationURLs.contains {
                            Self.url(
                                unreadableURL,
                                isInside: $0
                            )
                        }
                    }
            } else {
                relevantUnreadableLocationURLs =
                    unreadableLocationURLs
            }
            projectSearchLocations[index].status =
                ProjectSearchLocationAccess.resolvedStatus(
                    probe: probe,
                    rootURL: location.url,
                    unreadableLocationURLs:
                        relevantUnreadableLocationURLs
                )
            projectScanPreviousLocationStatuses.removeValue(
                forKey: location.id
            )
        }
    }

    private func restorableProjectSearchStatus(
        for location: ProjectSearchLocationAccess
    ) -> ProjectSearchAccessStatus {
        location.status.restoredAfterCancelledCheck
    }

    private func restoreProjectSearchLocationsAfterCancellation() {
        for index in projectSearchLocations.indices {
            let id = projectSearchLocations[index].id
            let status = projectScanPreviousLocationStatuses[id]
                ?? projectSearchLocations[index].status
            projectSearchLocations[index].status =
                status.restoredAfterCancelledCheck
        }
        projectScanPreviousLocationStatuses.removeAll()
    }

    nonisolated private static func url(
        _ candidateURL: URL,
        isInside rootURL: URL
    ) -> Bool {
        let candidatePath = candidateURL.standardizedFileURL.path
        let rootPath = rootURL.standardizedFileURL.path
        return candidatePath == rootPath
            || candidatePath.hasPrefix(rootPath + "/")
    }

    nonisolated private static func cachedProjectURLIsAuthorized(
        _ projectURL: URL,
        homeDirectoryURL: URL,
        selectedSearchFolderPaths: Set<String>,
        manuallyAddedProjectPaths: Set<String>
    ) -> Bool {
        let project = projectURL.standardizedFileURL
        if manuallyAddedProjectPaths.contains(project.path) {
            return true
        }
        let protectedURLs =
            ProjectSearchLocationAccess.protectedLocationURLs(
                homeDirectoryURL: homeDirectoryURL
            )
        guard protectedURLs.contains(
            where: { url(project, isInside: $0) }
        ) else {
            return true
        }
        return selectedSearchFolderPaths.contains {
            url(
                project,
                isInside: URL(
                    fileURLWithPath: $0,
                    isDirectory: true
                )
            )
        }
    }

    private func startProjectScan(
        rootURL: URL,
        description: SideRefreshLocalizedText
    ) {
        startProjectScanSequence(
            [
                ProjectScanRequest(
                    rootURL: rootURL,
                    description: description
                ),
            ]
        )
    }

    private func startProjectScanSequence(
        _ requests: [ProjectScanRequest]
    ) {
        guard !requests.isEmpty else {
            return
        }
        cancelActiveProjectScan()
        queuedProjectScanRequests = requests
        startNextProjectScan()
    }

    private func cancelActiveProjectScan() {
        projectScanGeneration += 1
        stopProjectSpotlightQuery()
        projectSpotlightMetadataTask?.cancel()
        projectSpotlightMetadataTask = nil
        projectScanWorker?.cancel()
        projectScanWorker = nil
        restoreProjectSearchLocationsAfterCancellation()
    }

    private func startNextProjectScan() {
        guard !queuedProjectScanRequests.isEmpty else {
            isScanningProjects = false
            return
        }
        let request = queuedProjectScanRequests.removeFirst()
        projectScanGeneration += 1
        let generation = projectScanGeneration
        isScanningProjects = true
        projectScanMessage = .format(
            "%@에서 iOS 앱 프로젝트를 찾는 중…",
            .localizedText(request.description)
        )

        let root = request.rootURL.standardizedFileURL
        projectScanExcludedDirectoryURLs =
            excludedProjectSearchDirectoryURLs(for: root)
        beginProjectSearchLocationChecks(
            rootURL: root,
            excluding: projectScanExcludedDirectoryURLs
        )
        let home = FileManager.default.homeDirectoryForCurrentUser
            .standardizedFileURL
        if root == home {
            startProjectSpotlightScan(
                rootURL: root,
                description: request.description,
                generation: generation
            )
        } else {
            startFileSystemProjectScan(
                rootURL: root,
                description: request.description,
                generation: generation
            )
        }
    }

    private func startProjectSpotlightScan(
        rootURL: URL,
        description: SideRefreshLocalizedText,
        generation: Int
    ) {
        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUserHomeScope]
        query.predicate = ProjectSpotlightQueryPredicate.make(
            excludingDirectoryURLs:
                projectScanExcludedDirectoryURLs
        )
        projectSpotlightQuery = query

        let center = NotificationCenter.default
        let updateToken = center.addObserver(
            forName: .NSMetadataQueryDidUpdate,
            object: query,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self,
                      let activeQuery = self.projectSpotlightQuery
                else {
                    return
                }
                self.publishProjectSpotlightResults(
                    query: activeQuery,
                    rootURL: rootURL,
                    description: description,
                    generation: generation
                )
            }
        }
        let finishToken = center.addObserver(
            forName: .NSMetadataQueryDidFinishGathering,
            object: query,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self,
                      let activeQuery = self.projectSpotlightQuery
                else {
                    return
                }
                self.finishProjectSpotlightScan(
                    query: activeQuery,
                    rootURL: rootURL,
                    description: description,
                    generation: generation
                )
            }
        }
        projectSpotlightObserverTokens = [updateToken, finishToken]

        projectSpotlightTimeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled,
                  let self,
                  let activeQuery = self.projectSpotlightQuery
            else {
                return
            }
            self.finishProjectSpotlightScan(
                query: activeQuery,
                rootURL: rootURL,
                description: description,
                generation: generation
            )
        }

        guard query.start() else {
            finishProjectSpotlightScan(
                query: query,
                rootURL: rootURL,
                description: description,
                generation: generation
            )
            return
        }
    }

    private func publishProjectSpotlightResults(
        query: NSMetadataQuery,
        rootURL: URL,
        description: SideRefreshLocalizedText,
        generation: Int
    ) {
        guard generation == projectScanGeneration,
              projectSpotlightQuery === query
        else {
            return
        }
        query.disableUpdates()
        defer {
            query.enableUpdates()
        }
        let urls: [URL] = (0..<query.resultCount).compactMap {
            guard let item = query.result(at: $0) as? NSMetadataItem,
                  let url = item.value(
                      forAttribute: NSMetadataItemURLKey
                  ) as? URL
            else {
                return nil
            }
            guard !self.projectScanExcludedDirectoryURLs
                .contains(
                    where: {
                        Self.url(url, isInside: $0)
                    }
                )
            else {
                return nil
            }
            return url
        }
        guard !urls.isEmpty else {
            return
        }
        projectSpotlightMetadataTask?.cancel()
        projectSpotlightMetadataTask = Task.detached(
            priority: .utility
        ) { [weak self] in
            let scanner = XcodeContainerScanner()
            var candidates: [XcodeContainerCandidate] = []
            for url in urls.prefix(200) {
                guard !Task.isCancelled else {
                    return
                }
                if let candidate = scanner.discoveryCandidate(
                    for: url,
                    relativeTo: rootURL
                ) {
                    candidates.append(candidate)
                }
            }
            guard !Task.isCancelled else {
                return
            }
            await self?.publishSpotlightCandidates(
                candidates,
                description: description,
                generation: generation
            )
        }
    }

    private func publishSpotlightCandidates(
        _ candidates: [XcodeContainerCandidate],
        description: SideRefreshLocalizedText,
        generation: Int
    ) {
        guard generation == projectScanGeneration else {
            return
        }
        mergeDiscoveredContainers(
            candidates,
            limitsAutomaticResults: true
        )
        if !candidates.isEmpty {
            projectScanMessage = .format(
                "%@에서 빠르게 %ld개 찾음 · 계속 확인 중…",
                .localizedText(description),
                .integer(candidates.count)
            )
        }
    }

    private func finishProjectSpotlightScan(
        query: NSMetadataQuery,
        rootURL: URL,
        description: SideRefreshLocalizedText,
        generation: Int
    ) {
        guard generation == projectScanGeneration,
              projectSpotlightQuery === query
        else {
            return
        }
        publishProjectSpotlightResults(
            query: query,
            rootURL: rootURL,
            description: description,
            generation: generation
        )
        stopProjectSpotlightQuery()
        startFileSystemProjectScan(
            rootURL: rootURL,
            description: description,
            generation: generation
        )
    }

    private func stopProjectSpotlightQuery() {
        projectSpotlightTimeoutTask?.cancel()
        projectSpotlightTimeoutTask = nil
        if let query = projectSpotlightQuery {
            query.stop()
        }
        projectSpotlightQuery = nil
        let center = NotificationCenter.default
        projectSpotlightObserverTokens.forEach(center.removeObserver)
        projectSpotlightObserverTokens.removeAll()
    }

    private func startFileSystemProjectScan(
        rootURL: URL,
        description: SideRefreshLocalizedText,
        generation: Int
    ) {
        let excludedDirectoryURLs =
            projectScanExcludedDirectoryURLs
        let (batches, continuation) = AsyncStream.makeStream(
            of: [XcodeContainerCandidate].self
        )
        let worker = Task.detached(priority: .utility) {
            defer {
                continuation.finish()
            }
            return try XcodeContainerScanner().scan(
                rootURL: rootURL,
                maximumResults: 200,
                batchSize: 20,
                excludingDirectoryURLs: excludedDirectoryURLs
            ) {
                continuation.yield($0)
            }
        }
        projectScanWorker = worker
        let batchConsumer = Task { [weak self] in
            for await batch in batches {
                guard let self,
                      generation == self.projectScanGeneration
                else {
                    return
                }
                self.mergeDiscoveredContainers(
                    batch,
                    limitsAutomaticResults: true
                )
                self.projectScanMessage = .format(
                    "%@에서 %ld개 찾음 · 계속 확인 중…",
                    .localizedText(description),
                    .integer(self.discoveredXcodeContainers.count)
                )
            }
        }
        Task { [weak self] in
            do {
                let result = try await worker.value
                _ = await batchConsumer.value
                guard let self,
                      generation == self.projectScanGeneration
                else {
                    return
                }
                self.mergeDiscoveredContainers(
                    result.candidates,
                    limitsAutomaticResults: true
                )
                self.finishProjectSearchLocationChecks(
                    rootURL: rootURL,
                    probe: .accessible,
                    unreadableLocationURLs:
                        result.unreadableLocationURLs
                )
                let hasUnreadableFolders =
                    result.unreadableLocationCount > 0
                let summary: SideRefreshLocalizedText
                if result.candidates.isEmpty {
                    summary = .format(
                        hasUnreadableFolders
                            ? "%@에서 iOS 앱 프로젝트를 찾지 못했습니다. 일부 폴더를 확인하지 못했습니다."
                            : "%@에서 iOS 앱 프로젝트를 찾지 못했습니다.",
                        .localizedText(description)
                    )
                } else if result.reachedResultLimit {
                    summary = .format(
                        hasUnreadableFolders
                            ? "%@에서 200개 발견 · 최대 200개까지만 보여줍니다. 일부 폴더를 확인하지 못했습니다."
                            : "%@에서 200개 발견 · 최대 200개까지만 보여줍니다.",
                        .localizedText(description)
                    )
                } else {
                    summary = .format(
                        hasUnreadableFolders
                            ? "%@에서 %ld개 발견 · 일부 폴더를 확인하지 못했습니다."
                            : "%@에서 %ld개 발견",
                        .localizedText(description),
                        .integer(result.candidates.count)
                    )
                }
                self.finishCurrentProjectScan(summary: summary)
            } catch is CancellationError {
                batchConsumer.cancel()
                _ = await batchConsumer.value
                guard let self,
                      generation == self.projectScanGeneration
                else {
                    return
                }
                self
                    .restoreProjectSearchLocationsAfterCancellation()
                self.finishCurrentProjectScan(
                    summary: .key(
                        "프로젝트 검색 중단됨"
                    )
                )
            } catch {
                batchConsumer.cancel()
                _ = await batchConsumer.value
                guard let self,
                      generation == self.projectScanGeneration
                else {
                    return
                }
                self.finishProjectSearchLocationChecks(
                    rootURL: rootURL,
                    probe:
                        Self.projectSearchAccessProbe(for: error),
                    unreadableLocationURLs: []
                )
                self.presentVerbatimError(
                    error.localizedDescription
                )
                self.finishCurrentProjectScan(
                    summary: .key(
                        "프로젝트 검색 실패"
                    )
                )
            }
        }
    }

    private func finishCurrentProjectScan(
        summary: SideRefreshLocalizedText
    ) {
        projectScanWorker = nil
        projectScanMessage = summary
        if queuedProjectScanRequests.isEmpty {
            isScanningProjects = false
        } else {
            startNextProjectScan()
        }
    }

    private func mergeDiscoveredContainers(
        _ candidates: [XcodeContainerCandidate],
        limitsAutomaticResults: Bool = false
    ) {
        var containersByPath = Dictionary(
            uniqueKeysWithValues: discoveredXcodeContainers.map {
                ($0.id, $0)
            }
        )
        for candidate in candidates {
            containersByPath[candidate.id] = candidate
        }
        discoveredXcodeContainers = containersByPath.values
            .filter {
                FileManager.default.fileExists(atPath: $0.url.path)
            }
        sortDiscoveredContainers()
        if limitsAutomaticResults {
            let protectedPaths = manuallyAddedProjectPaths.union(
                target.containerPath.isEmpty
                    ? Set<String>()
                    : Set([target.containerPath])
            )
            let protectedCandidates = discoveredXcodeContainers.filter {
                protectedPaths.contains($0.id)
            }
            let automaticCandidates = discoveredXcodeContainers.filter {
                !protectedPaths.contains($0.id)
            }
            discoveredXcodeContainers =
                protectedCandidates
                + automaticCandidates.prefix(200)
            sortDiscoveredContainers()
        }
        cacheDiscoveredContainers()
    }

    private func sortDiscoveredContainers() {
        discoveredXcodeContainers.sort {
            let firstIsSelected = $0.id == target.containerPath
            let secondIsSelected = $1.id == target.containerPath
            if firstIsSelected != secondIsSelected {
                return firstIsSelected
            }
            let nameOrder = $0.applicationNameSummary
                .localizedCaseInsensitiveCompare(
                    $1.applicationNameSummary
                )
            if nameOrder != .orderedSame {
                return nameOrder == .orderedAscending
            }
            return $0.relativePath.localizedCaseInsensitiveCompare(
                $1.relativePath
            ) == .orderedAscending
        }
    }

    private func cacheDiscoveredContainers() {
        UserDefaults.standard.set(
            discoveredXcodeContainers.map(\.id),
            forKey: Self.cachedProjectPathsKey
        )
        UserDefaults.standard.set(
            Array(manuallyAddedProjectPaths),
            forKey: Self.manuallyAddedProjectPathsKey
        )
    }

    private func loadCachedXcodeContainers() {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        manuallyAddedProjectPaths = Set(
            UserDefaults.standard.stringArray(
                forKey: Self.manuallyAddedProjectPathsKey
            ) ?? []
        )
        let paths = (
            UserDefaults.standard.stringArray(
                forKey: Self.cachedProjectPathsKey
            ) ?? []
        )
        guard !paths.isEmpty else {
            return
        }
        let manuallyAddedPaths = manuallyAddedProjectPaths
        let selectedSearchFolderPaths =
            selectedProjectSearchFolderPaths
        projectScanMessage = .format(
            "이전 검색 결과 %ld개를 백그라운드에서 불러오는 중…",
            .integer(paths.count)
        )
        cachedProjectLoadTask = Task.detached(
            priority: .utility
        ) { [weak self] in
            let scanner = XcodeContainerScanner()
            var candidates: [XcodeContainerCandidate] = []
            for path in paths {
                guard !Task.isCancelled else {
                    return
                }
                let url = URL(fileURLWithPath: path)
                guard Self.cachedProjectURLIsAuthorized(
                    url,
                    homeDirectoryURL: homeURL,
                    selectedSearchFolderPaths:
                        selectedSearchFolderPaths,
                    manuallyAddedProjectPaths:
                        manuallyAddedPaths
                ) else {
                    continue
                }
                guard FileManager.default.fileExists(
                    atPath: path
                ) else {
                    continue
                }
                let candidate: XcodeContainerCandidate?
                if manuallyAddedPaths.contains(
                    url.standardizedFileURL.path
                ) {
                    candidate = scanner.candidate(
                        for: url,
                        relativeTo: homeURL
                    )
                } else {
                    candidate = scanner.discoveryCandidate(
                        for: url,
                        relativeTo: homeURL
                    )
                }
                if let candidate {
                    candidates.append(candidate)
                }
            }
            guard !Task.isCancelled else {
                return
            }
            await self?.publishCachedProjectCandidates(candidates)
        }
    }

    private func publishCachedProjectCandidates(
        _ candidates: [XcodeContainerCandidate]
    ) {
        mergeDiscoveredContainers(candidates)
        manuallyAddedProjectPaths =
            manuallyAddedProjectPaths.intersection(
                candidates.map(\.id)
            )
        projectScanMessage = .format(
            "이전 검색 결과 %ld개를 불러왔습니다. 필요하면 홈 폴더를 다시 검색하세요.",
            .integer(candidates.count)
        )
    }

    private func bundledIOSRenewalHelperURL() -> URL? {
        guard let url = Bundle.main.resourceURL?
            .appendingPathComponent("SideRefreshIOSRenewal"),
              FileManager.default.isExecutableFile(atPath: url.path)
        else {
            return nil
        }
        return url
    }

    nonisolated private static func readConnectedTailnet(
        executableURLs: [URL]
    ) throws -> (
        executable: String,
        snapshot: TailnetSnapshot
    ) {
        var lastError: Error?
        for executableURL in executableURLs
        where FileManager.default.isExecutableFile(
            atPath: executableURL.path
        ) {
            do {
                let snapshot = try TailscaleStatusReader().read(
                    executableURL: executableURL
                )
                return (executableURL.path, snapshot)
            } catch {
                lastError = error
            }
        }
        if let lastError {
            throw lastError
        }
        throw TailscaleStatusReaderError.invalidExecutable(
            executableURLs.map(\.path).joined(separator: " 또는 ")
        )
    }
}
