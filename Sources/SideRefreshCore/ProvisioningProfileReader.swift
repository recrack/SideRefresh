import Foundation
import Security

public struct ProvisioningProfileMetadata: Equatable, Sendable {
    public let identifier: String
    public let name: String
    public let creationDate: Date?
    public let expirationDate: Date
    public let applicationIdentifier: String?
    public let teamIdentifiers: [String]
    public let teamName: String?
    public let developerCertificateNames: [String]
    public let appIdentifierName: String?
    public let provisionedDevices: [String]
    public let platforms: [String]
    public let timeToLiveDays: Int?
    public let isLocalProvision: Bool?
    public let entitlementKeys: [String]

    public init(
        identifier: String,
        name: String,
        creationDate: Date?,
        expirationDate: Date,
        applicationIdentifier: String?,
        teamIdentifiers: [String] = [],
        teamName: String? = nil,
        developerCertificateNames: [String] = [],
        appIdentifierName: String? = nil,
        provisionedDevices: [String] = [],
        platforms: [String] = [],
        timeToLiveDays: Int? = nil,
        isLocalProvision: Bool? = nil,
        entitlementKeys: [String] = []
    ) {
        self.identifier = identifier
        self.name = name
        self.creationDate = creationDate
        self.expirationDate = expirationDate
        self.applicationIdentifier = applicationIdentifier
        self.teamIdentifiers = teamIdentifiers
        self.teamName = teamName
        self.developerCertificateNames = developerCertificateNames
        self.appIdentifierName = appIdentifierName
        self.provisionedDevices = provisionedDevices
        self.platforms = platforms
        self.timeToLiveDays = timeToLiveDays
        self.isLocalProvision = isLocalProvision
        self.entitlementKeys = entitlementKeys
    }
}

public enum ProvisioningProfileReaderError:
    LocalizedError,
    Equatable
{
    case profileMissing(String)
    case decodeFailed
    case expirationMissing
    case securityCommandFailed(Int32, String)

    public var errorDescription: String? {
        switch self {
        case .profileMissing(let path):
            return "빌드된 앱의 프로비저닝 프로파일을 찾을 수 없습니다: \(path)"
        case .decodeFailed:
            return "앱의 프로비저닝 프로파일을 읽을 수 없습니다."
        case .expirationMissing:
            return "앱의 프로비저닝 프로파일에 만료일이 없습니다."
        case .securityCommandFailed(let exitCode, let message):
            let detail = message.isEmpty
                ? "종료 코드 \(exitCode)"
                : message
            return "앱의 프로비저닝 프로파일을 해석하지 못했습니다: \(detail)"
        }
    }
}

public struct ProvisioningProfileReader: Sendable {
    private let securityExecutableURL: URL
    private let runner: BoundedProcessRunner

    public init(
        securityExecutableURL: URL = URL(
            fileURLWithPath: "/usr/bin/security"
        ),
        runner: BoundedProcessRunner = BoundedProcessRunner(
            executionTimeout: 30
        )
    ) {
        self.securityExecutableURL = securityExecutableURL
        self.runner = runner
    }

    public func read(
        appBundleURL: URL
    ) throws -> ProvisioningProfileMetadata {
        let profileURL = appBundleURL.appendingPathComponent(
            "embedded.mobileprovision"
        )
        return try read(profileURL: profileURL)
    }

    public func read(
        profileURL: URL
    ) throws -> ProvisioningProfileMetadata {
        guard FileManager.default.fileExists(atPath: profileURL.path) else {
            throw ProvisioningProfileReaderError.profileMissing(
                profileURL.path
            )
        }
        let result = try runner.run(
            RenewalCommand(
                executableURL: securityExecutableURL,
                arguments: [
                    "cms",
                    "-D",
                    "-i",
                    profileURL.path,
                ]
            )
        )
        guard result.exitCode == 0 else {
            throw ProvisioningProfileReaderError.securityCommandFailed(
                result.exitCode,
                result.standardError.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            )
        }
        return try Self.parsePayload(Data(result.standardOutput.utf8))
    }

    public static func parsePayload(
        _ data: Data
    ) throws -> ProvisioningProfileMetadata {
        guard let payload = try PropertyListSerialization.propertyList(
            from: data,
            format: nil
        ) as? [String: Any]
        else {
            throw ProvisioningProfileReaderError.decodeFailed
        }
        guard let expirationDate = payload["ExpirationDate"] as? Date else {
            throw ProvisioningProfileReaderError.expirationMissing
        }
        let entitlements = payload["Entitlements"] as? [String: Any]
        let certificateNames = (
            payload["DeveloperCertificates"] as? [Data] ?? []
        ).compactMap(Self.certificateCommonName)
        return ProvisioningProfileMetadata(
            identifier: payload["UUID"] as? String ?? "",
            name: payload["Name"] as? String ?? "",
            creationDate: payload["CreationDate"] as? Date,
            expirationDate: expirationDate,
            applicationIdentifier:
                entitlements?["application-identifier"] as? String,
            teamIdentifiers:
                payload["TeamIdentifier"] as? [String] ?? [],
            teamName: payload["TeamName"] as? String,
            developerCertificateNames: certificateNames,
            appIdentifierName: payload["AppIDName"] as? String,
            provisionedDevices:
                payload["ProvisionedDevices"] as? [String] ?? [],
            platforms: payload["Platform"] as? [String] ?? [],
            timeToLiveDays: payload["TimeToLive"] as? Int,
            isLocalProvision: payload["LocalProvision"] as? Bool,
            entitlementKeys: entitlements?.keys.sorted() ?? []
        )
    }

    private static func certificateCommonName(
        _ data: Data
    ) -> String? {
        guard let certificate = SecCertificateCreateWithData(
            nil,
            data as CFData
        ) else {
            return nil
        }
        var commonName: CFString?
        guard SecCertificateCopyCommonName(
            certificate,
            &commonName
        ) == errSecSuccess else {
            return nil
        }
        return commonName as String?
    }
}
