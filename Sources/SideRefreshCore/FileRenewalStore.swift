import Foundation

public enum RenewalStoreError: Error, Equatable {
    case unsupportedSchemaVersion(Int)
}

public struct RenewalReceipt: Equatable, Sendable {
    public let completedAt: Date
    public let provisioningExpirationDate: Date?
    public let provisioningProfileIdentifier: String?

    public init(
        completedAt: Date,
        provisioningExpirationDate: Date?,
        provisioningProfileIdentifier: String? = nil
    ) {
        self.completedAt = completedAt
        self.provisioningExpirationDate = provisioningExpirationDate
        self.provisioningProfileIdentifier =
            provisioningProfileIdentifier
    }
}

public struct FileRenewalStore: Sendable {
    private struct State: Codable {
        let schemaVersion: Int
        let lastSuccessfulRenewal: Date
        let commandFingerprint: String?
        let provisioningExpirationDate: Date?
        let provisioningProfileIdentifier: String?
    }

    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL.standardizedFileURL
    }

    public func loadLastSuccessfulRenewal(
        for command: RenewalCommand? = nil
    ) throws -> Date? {
        try loadReceipt(for: command)?.completedAt
    }

    public func loadReceipt(
        for command: RenewalCommand? = nil
    ) throws -> RenewalReceipt? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        let state = try Self.decoder.decode(State.self, from: data)
        guard (1...4).contains(state.schemaVersion) else {
            throw RenewalStoreError.unsupportedSchemaVersion(
                state.schemaVersion
            )
        }
        if let command,
           state.commandFingerprint != command.fingerprint
        {
            return nil
        }
        return RenewalReceipt(
            completedAt: state.lastSuccessfulRenewal,
            provisioningExpirationDate:
                state.provisioningExpirationDate,
            provisioningProfileIdentifier:
                state.provisioningProfileIdentifier
        )
    }

    public func recordSuccess(
        at completedAt: Date,
        for command: RenewalCommand? = nil,
        provisioningExpirationDate: Date? = nil,
        provisioningProfileIdentifier: String? = nil
    ) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let state = State(
            schemaVersion: 4,
            lastSuccessfulRenewal: completedAt,
            commandFingerprint: command?.fingerprint,
            provisioningExpirationDate: provisioningExpirationDate,
            provisioningProfileIdentifier:
                provisioningProfileIdentifier
        )
        let data = try Self.encoder.encode(state)
        try data.write(to: fileURL, options: .atomic)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: fileURL.path
        )
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}
