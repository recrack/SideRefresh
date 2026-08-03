import Foundation
import Security

public enum AppleDevelopmentIdentityReaderError:
    LocalizedError,
    Equatable
{
    case keychainQueryFailed(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .keychainQueryFailed(let status):
            return "Apple Development 인증서를 읽지 못했습니다. Keychain 오류 \(status)"
        }
    }
}

public struct AppleDevelopmentIdentityReader: Sendable {
    public init() {}

    public func readTeamIdentifiers() throws -> [String] {
        let query: [CFString: Any] = [
            kSecClass: kSecClassIdentity,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecReturnRef: true,
        ]
        var queryResult: CFTypeRef?
        let status = SecItemCopyMatching(
            query as CFDictionary,
            &queryResult
        )
        if status == errSecItemNotFound {
            return []
        }
        guard status == errSecSuccess else {
            throw AppleDevelopmentIdentityReaderError
                .keychainQueryFailed(status)
        }
        guard let identities = queryResult as? [SecIdentity] else {
            return []
        }

        return Array(
            Set(
                identities.compactMap(Self.teamIdentifier)
            )
        ).sorted()
    }

    private static func teamIdentifier(
        from identity: SecIdentity
    ) -> String? {
        var certificate: SecCertificate?
        guard SecIdentityCopyCertificate(
            identity,
            &certificate
        ) == errSecSuccess,
        let certificate,
        let commonName = commonName(of: certificate)
        else {
            return nil
        }
        return teamIdentifier(
            commonName: commonName,
            organizationalUnits: organizationalUnits(
                of: certificate
            )
        )
    }

    static func teamIdentifier(
        commonName: String,
        organizationalUnits: [String]
    ) -> String? {
        guard
            commonName.hasPrefix("Apple Development:")
                || commonName.hasPrefix("iPhone Developer:")
        else {
            return nil
        }
        return organizationalUnits.first(
            where: isValidTeamIdentifier
        )
    }

    private static func commonName(
        of certificate: SecCertificate
    ) -> String? {
        var value: CFString?
        guard SecCertificateCopyCommonName(
            certificate,
            &value
        ) == errSecSuccess else {
            return nil
        }
        return value as String?
    }

    private static func organizationalUnits(
        of certificate: SecCertificate
    ) -> [String] {
        guard let values = SecCertificateCopyValues(
            certificate,
            [kSecOIDOrganizationalUnitName] as CFArray,
            nil
        ) as? [CFString: Any],
        let property = values[
            kSecOIDOrganizationalUnitName
        ] as? [CFString: Any]
        else {
            return []
        }
        return organizationalUnits(
            from: property[kSecPropertyKeyValue]
        )
    }

    static func organizationalUnits(
        from value: Any?
    ) -> [String] {
        if let value = value as? String {
            return [value]
        }
        if let values = value as? [[CFString: Any]] {
            return values.compactMap {
                $0[kSecPropertyKeyValue] as? String
            }
        }
        return []
    }

    private static func isValidTeamIdentifier(
        _ value: String
    ) -> Bool {
        value.count == 10
            && value.rangeOfCharacter(
                from: CharacterSet.alphanumerics.inverted
            ) == nil
    }
}
