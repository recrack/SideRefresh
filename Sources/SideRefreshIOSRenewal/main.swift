import Darwin
import Foundation
import SideRefreshCore

enum IOSRenewalCLIError: LocalizedError {
    case usage(String)

    var errorDescription: String? {
        switch self {
        case .usage(let message):
            return message
        }
    }
}

struct IOSRenewalOutput: Encodable {
    let mode: IOSAppRenewalMode
    let buildStrategy: IOSAppBuildStrategy
    let versionPolicy: IOSAppVersionPolicy
    let sourceAppVersion: IOSAppVersion?
    let resolvedAppVersion: IOSAppVersion?
    let appBundle: String
    let renewalEvidence: IOSAppRenewalEvidence
    let buildCommand: RenewalCommand
    let installCommand: RenewalCommand
    let buildResult: ProcessResult?
    let installResult: ProcessResult?
    let provisioningExpirationDate: Date?
    let provisioningProfileIdentifier: String?
    let systemChangesPerformed: Bool
}

func parseOptions(_ arguments: [String]) throws -> IOSAppRenewalProfile {
    do {
        return try IOSAppRenewalProfile(arguments: arguments)
    } catch {
        throw IOSRenewalCLIError.usage(error.localizedDescription)
    }
}

func writeOutput(
    profile: IOSAppRenewalProfile,
    renewalEvidence: IOSAppRenewalEvidence,
    buildCommand: RenewalCommand,
    appBundleURL: URL,
    installCommand: RenewalCommand,
    resolvedAppVersion: IOSAppVersion?,
    buildResult: ProcessResult? = nil,
    installResult: ProcessResult? = nil,
    provisioningExpirationDate: Date? = nil,
    provisioningProfileIdentifier: String? = nil,
    systemChangesPerformed: Bool
) throws {
    try SideRefreshJSONOutput.write(
        IOSRenewalOutput(
            mode: profile.mode,
            buildStrategy: profile.buildStrategy,
            versionPolicy: profile.versionPolicy,
            sourceAppVersion: profile.sourceAppVersion,
            resolvedAppVersion: resolvedAppVersion,
            appBundle: appBundleURL.path,
            renewalEvidence: renewalEvidence,
            buildCommand: buildCommand,
            installCommand: installCommand,
            buildResult: buildResult,
            installResult: installResult,
            provisioningExpirationDate: provisioningExpirationDate,
            provisioningProfileIdentifier:
                provisioningProfileIdentifier,
            systemChangesPerformed: systemChangesPerformed
        )
    )
}

func report(
    _ phase: RenewalProgressPhase,
    _ state: RenewalProgressState,
    _ message: String
) {
    RenewalProgressWire.write(
        RenewalProgressEvent(
            phase: phase,
            state: state,
            message: message
        )
    )
}

func run(_ profile: IOSAppRenewalProfile) throws -> Int32 {
    let plan = profile.plan
    let renewalEvidence = IOSAppRenewalEvidence()
    let resolvedAppVersion = try resolvedAppVersion(
        for: profile
    )
    let buildCommand = plan.buildCommand(
        for: profile.buildStrategy,
        renewalEvidence: renewalEvidence,
        appVersionOverride: resolvedAppVersion
    )
    let buildSettingOverrides = plan.buildSettingOverrides(
        renewalEvidence: renewalEvidence,
        appVersionOverride: resolvedAppVersion
    )
    let appBundleURL = try XcodeBuildSettingsReader()
        .readAppBundleURL(
            plan: plan,
            destination: profile.mode == .execute
                ? .selectedDevice
                : .genericIOS,
            buildSettingOverrides: buildSettingOverrides
        )
    let installCommand = plan.installCommand(
        appBundleURL: appBundleURL
    )
    guard profile.mode == .execute else {
        try writeOutput(
            profile: profile,
            renewalEvidence: renewalEvidence,
            buildCommand: buildCommand,
            appBundleURL: appBundleURL,
            installCommand: installCommand,
            resolvedAppVersion: resolvedAppVersion,
            systemChangesPerformed: false
        )
        return 0
    }

    let workflowDeadline = DispatchTime.now().uptimeNanoseconds
        + UInt64(27 * 60 * 1_000_000_000)
    report(
        .cleaningBuild,
        .started,
        "이전 앱 결과를 안전하게 확인합니다."
    )
    do {
        let cleanupResult = try plan.removeExistingAppBundle(
            at: appBundleURL
        )
        let cleanupMessage = switch cleanupResult {
        case .absent:
            "정리할 이전 앱 결과가 없습니다."
        case .removed:
            profile.buildStrategy == .incremental
                ? "이전 앱 결과만 정리하고 증분 빌드 캐시는 유지했습니다."
                : "이전 앱 결과를 정리해 전체 다시 빌드를 준비했습니다."
        case .skippedOutsideDerivedData:
            "DerivedData 밖의 기존 앱은 삭제하지 않고 Xcode가 갱신하도록 둡니다."
        }
        report(
            .cleaningBuild,
            .succeeded,
            cleanupMessage
        )
    } catch {
        report(.cleaningBuild, .failed, error.localizedDescription)
        throw error
    }

    report(
        .building,
        .started,
        "\(plan.scheme) · \(plan.configuration) · \(buildStrategyLabel(profile.buildStrategy))를 시작합니다."
            + versionBuildMessage(resolvedAppVersion)
    )
    let buildResult: ProcessResult
    do {
        buildResult = try run(
            buildCommand,
            before: workflowDeadline
        )
    } catch {
        report(.building, .failed, error.localizedDescription)
        throw error
    }
    guard buildResult.exitCode == 0 else {
        report(
            .building,
            .failed,
            "Xcode 빌드 실패 · 종료 코드 \(buildResult.exitCode)"
        )
        try writeOutput(
            profile: profile,
            renewalEvidence: renewalEvidence,
            buildCommand: buildCommand,
            appBundleURL: appBundleURL,
            installCommand: installCommand,
            resolvedAppVersion: resolvedAppVersion,
            buildResult: buildResult,
            systemChangesPerformed: true
        )
        return buildResult.exitCode
    }
    report(.building, .succeeded, "Xcode 빌드가 완료됐습니다.")

    report(
        .validatingApp,
        .started,
        "빌드된 앱의 Bundle ID를 확인합니다."
    )
    do {
        try plan.validateBuiltAppBundle(at: appBundleURL)
        report(
            .validatingApp,
            .succeeded,
            "Bundle ID 일치 · \(plan.bundleIdentifier)"
        )
    } catch {
        report(.validatingApp, .failed, error.localizedDescription)
        throw error
    }

    report(
        .readingProfile,
        .started,
        "Apple Development 서명과 만료일을 읽습니다."
    )
    let provisioningProfile: ProvisioningProfileMetadata
    do {
        provisioningProfile = try ProvisioningProfileReader().read(
            appBundleURL: appBundleURL
        )
        report(
            .readingProfile,
            .succeeded,
            "프로파일 만료 · \(provisioningProfile.expirationDate.formatted(date: .abbreviated, time: .shortened))"
        )
    } catch {
        report(.readingProfile, .failed, error.localizedDescription)
        throw error
    }

    report(
        .installing,
        .started,
        "빌드된 앱을 선택한 iPhone에 설치합니다."
    )
    let installResult: ProcessResult
    do {
        installResult = try run(
            installCommand,
            before: workflowDeadline
        )
    } catch {
        report(.installing, .failed, error.localizedDescription)
        throw error
    }
    if installResult.exitCode == 0 {
        report(.installing, .succeeded, "iPhone 설치가 완료됐습니다.")
    } else {
        report(
            .installing,
            .failed,
            "iPhone 설치 실패 · 종료 코드 \(installResult.exitCode)"
        )
    }
    try writeOutput(
        profile: profile,
        renewalEvidence: renewalEvidence,
        buildCommand: buildCommand,
        appBundleURL: appBundleURL,
        installCommand: installCommand,
        resolvedAppVersion: resolvedAppVersion,
        buildResult: buildResult,
        installResult: installResult,
        provisioningExpirationDate:
            provisioningProfile.expirationDate,
        provisioningProfileIdentifier:
            provisioningProfile.identifier,
        systemChangesPerformed: true
    )
    return installResult.exitCode
}

func resolvedAppVersion(
    for profile: IOSAppRenewalProfile
) throws -> IOSAppVersion? {
    guard profile.versionPolicy == .automatic else {
        return nil
    }
    let source: IOSAppVersion?
    if profile.mode == .execute {
        let currentProjectVersion = try XcodeBuildSettingsReader().read(
            plan: profile.plan
        )
        if let savedSource = profile.sourceAppVersion {
            source = IOSAppVersion.resolvedBase(
                source: currentProjectVersion,
                installed: savedSource
            )
        } else {
            source = currentProjectVersion
        }
    } else if let savedSource = profile.sourceAppVersion {
        source = savedSource
    } else {
        source = try XcodeBuildSettingsReader().read(
            plan: profile.plan,
            destination: .genericIOS
        )
    }
    guard let source else {
        throw IOSRenewalCLIError.usage(
            "자동 버전업을 사용하려면 프로젝트의 현재 앱 버전과 빌드 번호를 먼저 확인해야 합니다."
        )
    }
    let installed: IOSAppVersion?
    if profile.mode == .execute,
       let installedApp = try InstalledAppReader().read(
           deviceIdentifier: profile.plan.deviceIdentifier,
           bundleIdentifier: profile.plan.bundleIdentifier
       )
    {
        guard let version = IOSAppVersion(
            marketingVersion: installedApp.version,
            buildVersion: installedApp.bundleVersion
        ) else {
            throw IOSRenewalCLIError.usage(
                "iPhone에 설치된 앱 버전 \(installedApp.version) (\(installedApp.bundleVersion))을 안전하게 올릴 수 없습니다."
            )
        }
        installed = version
    } else {
        installed = nil
    }
    guard let next = IOSAppVersion.next(
        source: source,
        installed: installed
    ) else {
        throw IOSRenewalCLIError.usage(
            "앱 버전 숫자가 최대값이라 자동으로 올릴 수 없습니다."
        )
    }
    return next
}

func versionBuildMessage(
    _ version: IOSAppVersion?
) -> String {
    guard let version else {
        return " · 앱 버전 유지"
    }
    return " · \(version.marketingVersion) (\(version.buildVersion))"
}

func buildStrategyLabel(
    _ strategy: IOSAppBuildStrategy
) -> String {
    switch strategy {
    case .incremental:
        return "스마트 증분 빌드"
    case .cleanRebuild:
        return "전체 다시 빌드"
    }
}

func run(
    _ command: RenewalCommand,
    before deadline: UInt64
) throws -> ProcessResult {
    let now = DispatchTime.now().uptimeNanoseconds
    guard now < deadline else {
        throw IOSRenewalCLIError.usage(
            "the 27-minute build and install budget was exhausted"
        )
    }
    let remainingSeconds = TimeInterval(deadline - now) / 1_000_000_000
    let hasOuterContainment =
        ProcessInfo.processInfo.environment[
            BoundedProcessRunner.containmentEnvironmentKey
        ] == BoundedProcessRunner.containmentEnvironmentValue
        && Darwin.getpgrp() == Darwin.getpid()
    return try BoundedProcessRunner(
        executionTimeout: max(1, remainingSeconds - 1),
        terminationGracePeriod: 1,
        processGroupMode: hasOuterContainment ? .inherited : .isolated
    ).run(
        command,
        onOutput: { chunk in
            SideRefreshJSONOutput.writeError(chunk.text)
        }
    )
}

do {
    exit(try run(parseOptions(Array(CommandLine.arguments.dropFirst()))))
} catch {
    SideRefreshJSONOutput.writeError(
        "SideRefresh iOS refresh helper: \(error.localizedDescription)\n"
    )
    exit(2)
}
