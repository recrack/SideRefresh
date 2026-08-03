import Darwin
import Foundation

public enum RenewalEngineError: LocalizedError, Equatable {
    case provisioningExpirationMissing

    public var errorDescription: String? {
        switch self {
        case .provisioningExpirationMissing:
            return "설치는 완료됐지만 설치 앱의 서명 만료 영수증을 읽지 못했습니다. 갱신 성공으로 기록하지 않습니다."
        }
    }
}

public struct RenewalRunResult: Codable, Sendable {
    public let commandWasExecuted: Bool
    public let succeeded: Bool
    public let stateWasUpdated: Bool
    public let status: RenewalStatus
    public let processResult: ProcessResult?
    public let provisioningExpirationDate: Date?
    public let provisioningProfileIdentifier: String?
}

public struct RenewalEngine: Sendable {
    private let store: FileRenewalStore
    private let schedule: RenewalSchedule
    private let runner: BoundedProcessRunner

    public init(
        stateFileURL: URL,
        renewalInterval: RenewalInterval = .personalTeamDefault,
        runner: BoundedProcessRunner = BoundedProcessRunner()
    ) {
        store = FileRenewalStore(fileURL: stateFileURL)
        schedule = RenewalSchedule(interval: renewalInterval)
        self.runner = runner
    }

    public func status(
        for command: RenewalCommand? = nil,
        now: Date = Date()
    ) throws -> RenewalStatus {
        let receipt = try store.loadReceipt(for: command)
        return schedule.status(
            lastSuccessfulRenewal: receipt?.completedAt,
            provisioningExpirationDate:
                receipt?.provisioningExpirationDate,
            provisioningProfileIdentifier:
                receipt?.provisioningProfileIdentifier,
            now: now
        )
    }

    public func runIfDue(
        _ command: RenewalCommand,
        requiresProvisioningExpiration: Bool = false,
        progress: RenewalProgressHandler? = nil,
        now: Date = Date()
    ) throws -> RenewalRunResult {
        try run(
            command,
            now: now,
            requiresDueStatus: true,
            requiresProvisioningExpiration:
                requiresProvisioningExpiration,
            progress: progress
        )
    }

    public func runImmediately(
        _ command: RenewalCommand,
        requiresProvisioningExpiration: Bool = false,
        progress: RenewalProgressHandler? = nil,
        now: Date = Date()
    ) throws -> RenewalRunResult {
        try run(
            command,
            now: now,
            requiresDueStatus: false,
            requiresProvisioningExpiration:
                requiresProvisioningExpiration,
            progress: progress
        )
    }

    private func run(
        _ command: RenewalCommand,
        now: Date,
        requiresDueStatus: Bool,
        requiresProvisioningExpiration: Bool,
        progress: RenewalProgressHandler?
    ) throws -> RenewalRunResult {
        try withRenewalLock {
            let currentStatus = try status(for: command, now: now)
            guard !requiresDueStatus || currentStatus.isDue else {
                return RenewalRunResult(
                    commandWasExecuted: false,
                    succeeded: false,
                    stateWasUpdated: false,
                    status: currentStatus,
                    processResult: nil,
                    provisioningExpirationDate:
                        currentStatus.provisioningExpirationDate,
                    provisioningProfileIdentifier:
                        currentStatus.provisioningProfileIdentifier
                )
            }

            let decoder = RenewalProgressStreamDecoder()
            let processResult = try runner.run(
                command,
                onOutput: { chunk in
                    guard chunk.stream == .standardError else {
                        return
                    }
                    decoder.append(chunk.text).forEach {
                        progress?($0)
                    }
                }
            )
            decoder.finish().forEach {
                progress?($0)
            }
            guard processResult.exitCode == 0 else {
                progress?(
                    .progress(
                        RenewalProgressEvent(
                            phase: .completed,
                            state: .failed,
                            message:
                                "갱신이 종료 코드 \(processResult.exitCode)로 실패했습니다."
                        )
                    )
                )
                return RenewalRunResult(
                    commandWasExecuted: true,
                    succeeded: false,
                    stateWasUpdated: false,
                    status: currentStatus,
                    processResult: processResult,
                    provisioningExpirationDate: nil,
                    provisioningProfileIdentifier: nil
                )
            }

            let provisioningReceipt =
                Self.provisioningReceipt(
                    from: processResult.standardOutput
                )
            if requiresProvisioningExpiration,
               provisioningReceipt.expirationDate == nil
            {
                progress?(
                    .progress(
                        RenewalProgressEvent(
                            phase: .recordingReceipt,
                            state: .failed,
                            message:
                                RenewalEngineError.provisioningExpirationMissing
                                    .localizedDescription
                        )
                    )
                )
                throw RenewalEngineError
                    .provisioningExpirationMissing
            }
            progress?(
                .progress(
                    RenewalProgressEvent(
                        phase: .recordingReceipt,
                        state: .started,
                        message: "설치 성공과 서명 만료일을 기록합니다."
                    )
                )
            )
            try store.recordSuccess(
                at: now,
                for: command,
                provisioningExpirationDate:
                    provisioningReceipt.expirationDate,
                provisioningProfileIdentifier:
                    provisioningReceipt.profileIdentifier
            )
            progress?(
                .progress(
                    RenewalProgressEvent(
                        phase: .recordingReceipt,
                        state: .succeeded,
                        message: "갱신 영수증을 저장했습니다."
                    )
                )
            )
            progress?(
                .progress(
                    RenewalProgressEvent(
                        phase: .completed,
                        state: .succeeded,
                        message: "앱 빌드·서명·설치를 완료했습니다."
                    )
                )
            )
            return RenewalRunResult(
                commandWasExecuted: true,
                succeeded: true,
                stateWasUpdated: true,
                status: try status(for: command, now: now),
                processResult: processResult,
                provisioningExpirationDate:
                    provisioningReceipt.expirationDate,
                provisioningProfileIdentifier:
                    provisioningReceipt.profileIdentifier
            )
        }
    }

    private struct ProvisioningReceipt {
        let expirationDate: Date?
        let profileIdentifier: String?
    }

    private static func provisioningReceipt(
        from output: String
    ) -> ProvisioningReceipt {
        struct ReceiptOutput: Decodable {
            let provisioningExpirationDate: Date?
            let provisioningProfileIdentifier: String?
        }
        if let data = output.data(using: .utf8) {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            if let receipt = try? decoder.decode(
                ReceiptOutput.self,
                from: data
            ) {
                return ProvisioningReceipt(
                    expirationDate:
                        receipt.provisioningExpirationDate,
                    profileIdentifier:
                        receipt.provisioningProfileIdentifier
                )
            }
        }
        return ProvisioningReceipt(
            expirationDate: truncatedJSONDate(
                key: "provisioning_expiration_date",
                output: output
            ),
            profileIdentifier: truncatedJSONString(
                key: "provisioning_profile_identifier",
                output: output
            )
        )
    }

    private static func truncatedJSONDate(
        key: String,
        output: String
    ) -> Date? {
        guard let value = truncatedJSONString(
            key: key,
            output: output
        ) else {
            return nil
        }
        return ISO8601DateFormatter().date(from: value)
    }

    private static func truncatedJSONString(
        key: String,
        output: String
    ) -> String? {
        let quotedKey = "\"\(key)\""
        guard let keyRange = output.range(
            of: quotedKey,
            options: .backwards
        ), let colon = output[keyRange.upperBound...]
            .firstIndex(of: ":")
        else {
            return nil
        }
        let remainder = output[output.index(after: colon)...]
        guard let openingQuote = remainder.firstIndex(of: "\"") else {
            return nil
        }
        let valueStart = output.index(after: openingQuote)
        guard let closingQuote = output[valueStart...]
            .firstIndex(of: "\"")
        else {
            return nil
        }
        return String(output[valueStart..<closingQuote])
    }

    private func withRenewalLock<T>(_ operation: () throws -> T) throws -> T {
        let lockURL = store.fileURL.appendingPathExtension("lock")
        try FileManager.default.createDirectory(
            at: lockURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let descriptor = lockURL.path.withCString {
            Darwin.open(
                $0,
                O_CREAT | O_RDWR | O_CLOEXEC,
                mode_t(0o600)
            )
        }
        guard descriptor >= 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        defer {
            Darwin.lockf(descriptor, F_ULOCK, 0)
            Darwin.close(descriptor)
        }
        guard Darwin.lockf(descriptor, F_LOCK, 0) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        return try operation()
    }
}
