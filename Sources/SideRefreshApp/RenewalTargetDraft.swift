import Foundation
import SideRefreshCore

enum DeviceConnectionRoute: String, CaseIterable, Identifiable {
    case automatic
    case tailnet
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic:
            return "추가 주소 없음"
        case .tailnet:
            return "Tailscale 주소 · 실험적"
        case .custom:
            return "IP/DNS 직접 입력"
        }
    }
}

enum RenewalTargetRequiredField {
    case container
    case scheme
    case productName
    case bundleIdentifier
    case developmentTeam
    case deviceIdentifier
    case derivedData

    var guidance: String {
        switch self {
        case .container:
            return "Mac에서 빌드해 설치할 Xcode 프로젝트나 워크스페이스를 선택해 주세요."
        case .scheme:
            return "앱 구성(Scheme)이 비어 있습니다. 앱 화면에서 Xcode가 사용하는 Scheme을 확인해 주세요."
        case .productName:
            return "빌드 결과 앱 이름이 비어 있습니다. 앱 화면에서 Xcode의 Product Name을 확인해 주세요."
        case .bundleIdentifier:
            return "앱 식별자(Bundle ID)가 비어 있습니다. 앱 화면에서 Xcode의 Bundle Identifier를 확인해 주세요."
        case .developmentTeam:
            return "Apple 개발 팀 ID가 비어 있습니다. 앱 화면에서 Xcode > Signing & Capabilities의 Team을 확인해 주세요."
        case .deviceIdentifier:
            return "설치할 iPhone을 아직 선택하지 않았습니다. iPhone 화면에서 ‘Xcode에서 찾기’를 누르고 기기를 선택해 주세요."
        case .derivedData:
            return "임시 빌드 폴더가 비어 있습니다. 자동화 화면의 고급 설정에서 경로를 확인해 주세요."
        }
    }

    var setupArea: RenewalTargetSetupArea {
        switch self {
        case .container,
             .scheme,
             .productName,
             .bundleIdentifier,
             .developmentTeam:
            return .app
        case .deviceIdentifier:
            return .iphone
        case .derivedData:
            return .automation
        }
    }
}

enum RenewalTargetSetupArea {
    case app
    case iphone
    case automation
}

struct RenewalTargetDraft: Equatable {
    var containerPath = ""
    var scheme = ""
    var configuration = "Release"
    var developmentTeam = ""
    var bundleIdentifier = ""
    var appDisplayName = ""
    var productName = ""
    var sourceMarketingVersion = ""
    var sourceBuildVersion = ""
    var deviceIdentifier = ""
    var derivedDataPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(
            "Library/Caches/SideRefresh/DerivedData",
            isDirectory: true
        )
        .path

    init() {}

    init(profile: IOSAppRenewalProfile) {
        let plan = profile.plan
        containerPath = plan.containerURL.path
        scheme = plan.scheme
        configuration = plan.configuration
        developmentTeam = plan.developmentTeam
        bundleIdentifier = plan.bundleIdentifier
        appDisplayName = profile.displayName ?? ""
        productName = plan.productName
        sourceMarketingVersion =
            profile.sourceAppVersion?.marketingVersion ?? ""
        sourceBuildVersion =
            profile.sourceAppVersion?.buildVersion ?? ""
        deviceIdentifier = plan.deviceIdentifier
        derivedDataPath = plan.derivedDataURL.path
    }

    var displayName: String {
        let visibleName = appDisplayName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if !visibleName.isEmpty {
            return visibleName
        }
        if !productName.isEmpty {
            return productName
        }
        if !scheme.isEmpty {
            return scheme
        }
        if !containerPath.isEmpty {
            return URL(fileURLWithPath: containerPath)
                .deletingPathExtension()
                .lastPathComponent
        }
        return "갱신할 앱을 선택하세요"
    }

    var projectName: String {
        guard !containerPath.isEmpty else {
            return "Xcode 프로젝트를 선택하세요"
        }
        return URL(fileURLWithPath: containerPath).lastPathComponent
    }

    var isComplete: Bool {
        firstMissingRequiredField == nil
            && !configuration.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
    }

    var firstMissingRequiredField: RenewalTargetRequiredField? {
        let requiredValues: [
            (RenewalTargetRequiredField, String)
        ] = [
            (.container, containerPath),
            (.scheme, scheme),
            (.productName, productName),
            (.bundleIdentifier, bundleIdentifier),
            (.developmentTeam, developmentTeam),
            (.deviceIdentifier, deviceIdentifier),
            (.derivedData, derivedDataPath),
        ]
        return requiredValues.first { field, value in
            let trimmed = value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            return trimmed.isEmpty
                || Self.isPlaceholderOrInvalid(
                    field: field,
                    value: trimmed
                )
        }?.0
    }

    var sourceAppVersion: IOSAppVersion? {
        IOSAppVersion(
            marketingVersion: sourceMarketingVersion,
            buildVersion: sourceBuildVersion
        )
    }

    private static func isPlaceholderOrInvalid(
        field: RenewalTargetRequiredField,
        value: String
    ) -> Bool {
        let normalized = value.uppercased()
        if normalized.contains("REPLACE_")
            || normalized.contains("REPLACE-ME")
            || normalized.hasPrefix("YOUR_")
        {
            return true
        }
        switch field {
        case .developmentTeam:
            return value.count != 10
                || value.rangeOfCharacter(
                    from: CharacterSet.alphanumerics.inverted
                ) != nil
        case .bundleIdentifier:
            return !value.contains(".")
        case .container,
             .scheme,
             .productName,
             .deviceIdentifier,
             .derivedData:
            return false
        }
    }

    func profile(
        mode: IOSAppRenewalMode,
        buildStrategy: IOSAppBuildStrategy = .incremental,
        versionPolicy: IOSAppVersionPolicy = .keep
    ) throws -> IOSAppRenewalProfile {
        IOSAppRenewalProfile(
            mode: mode,
            buildStrategy: buildStrategy,
            versionPolicy: versionPolicy,
            sourceAppVersion: sourceAppVersion,
            displayName: persistedDisplayName,
            plan: try IOSAppRenewalPlan(
                containerURL: URL(fileURLWithPath: containerPath),
                scheme: scheme,
                configuration: configuration,
                developmentTeam: developmentTeam,
                bundleIdentifier: bundleIdentifier,
                productName: productName,
                deviceIdentifier: deviceIdentifier,
                derivedDataURL: URL(fileURLWithPath: derivedDataPath)
            )
        )
    }

    private var persistedDisplayName: String? {
        let value = appDisplayName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return value.isEmpty ? nil : value
    }
}
