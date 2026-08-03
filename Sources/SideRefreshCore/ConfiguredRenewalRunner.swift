import Foundation

public struct ConfiguredRenewalRunner: Sendable {
    private let readTailnetStatus:
        @Sendable (URL) throws -> TailnetSnapshot

    public init() {
        readTailnetStatus = {
            try TailscaleStatusReader().read(executableURL: $0)
        }
    }

    init(
        readTailnetStatus:
            @escaping @Sendable (URL) throws -> TailnetSnapshot
    ) {
        self.readTailnetStatus = readTailnetStatus
    }

    public func runIfDue(
        _ configuration: AgentConfiguration,
        progress: RenewalProgressHandler? = nil,
        now: Date = Date()
    ) throws -> RenewalRunResult {
        let engine = RenewalEngine(
            stateFileURL: configuration.stateFileURL,
            renewalInterval: configuration.renewalInterval
        )
        if try engine.status(
            for: configuration.command,
            now: now
        ).isDue,
           let target = configuration.tailnetTarget
        {
            try checkConnection(
                target: target,
                progress: progress
            )
        }
        return try engine.runIfDue(
            configuration.command,
            requiresProvisioningExpiration:
                Self.requiresProvisioningExpiration(
                    configuration.command
                ),
            progress: progress,
            now: now
        )
    }

    public func runImmediately(
        _ configuration: AgentConfiguration,
        progress: RenewalProgressHandler? = nil,
        now: Date = Date()
    ) throws -> RenewalRunResult {
        if let target = configuration.tailnetTarget {
            try checkConnection(
                target: target,
                progress: progress
            )
        } else {
            progress?(
                .progress(
                    RenewalProgressEvent(
                        phase: .checkingConnection,
                        state: .succeeded,
                        message: "Xcode/CoreDevice 연결 경로를 사용합니다."
                    )
                )
            )
        }
        return try RenewalEngine(
            stateFileURL: configuration.stateFileURL,
            renewalInterval: configuration.renewalInterval
        ).runImmediately(
            configuration.command,
            requiresProvisioningExpiration:
                Self.requiresProvisioningExpiration(
                    configuration.command
                ),
            progress: progress,
            now: now
        )
    }

    private func checkConnection(
        target: TailnetTarget,
        progress: RenewalProgressHandler?
    ) throws {
        progress?(
            .progress(
                RenewalProgressEvent(
                    phase: .checkingConnection,
                    state: .started,
                    message: "저장된 Tailscale iPhone 주소를 확인합니다."
                )
            )
        )
        do {
            let snapshot = try readTailnetStatus(
                URL(fileURLWithPath: target.tailscaleExecutable)
            )
            _ = try target.resolve(in: snapshot)
            progress?(
                .progress(
                    RenewalProgressEvent(
                        phase: .checkingConnection,
                        state: .succeeded,
                        message:
                            "Tailscale 주소 확인 완료"
                                + " · \(target.dnsName)"
                                + " · Xcode/CoreDevice 설치를 계속합니다."
                    )
                )
            )
        } catch {
            progress?(
                .progress(
                    RenewalProgressEvent(
                        phase: .checkingConnection,
                        state: .failed,
                        message: error.localizedDescription
                    )
                )
            )
            throw error
        }
    }

    static func requiresProvisioningExpiration(
        _ command: RenewalCommand
    ) -> Bool {
        guard command.executableURL.lastPathComponent
                == "SideRefreshIOSRenewal",
              let profile = try? IOSAppRenewalProfile(
                  arguments: command.arguments
              )
        else {
            return false
        }
        return profile.mode == .execute
    }
}
