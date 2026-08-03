import Foundation

public enum IOSAppVersionPolicy: String, Codable, CaseIterable, Sendable {
    case keep
    case automatic
}

public struct IOSAppVersion: Encodable, Equatable, Sendable {
    public let marketingVersion: String
    public let buildVersion: String

    public init?(
        marketingVersion: String,
        buildVersion: String
    ) {
        guard VersionNumber(marketingVersion) != nil,
              VersionNumber(buildVersion) != nil
        else {
            return nil
        }
        self.marketingVersion = marketingVersion
        self.buildVersion = buildVersion
    }

    public func incremented() -> IOSAppVersion? {
        guard let marketing = VersionNumber(marketingVersion)?
            .incremented(),
              let build = VersionNumber(buildVersion)?.incremented()
        else {
            return nil
        }
        return IOSAppVersion(
            marketingVersion: marketing.description,
            buildVersion: build.description
        )
    }

    public static func next(
        source: IOSAppVersion,
        installed: IOSAppVersion?
    ) -> IOSAppVersion? {
        resolvedBase(
            source: source,
            installed: installed
        ).incremented()
    }

    public static func resolvedBase(
        source: IOSAppVersion,
        installed: IOSAppVersion?
    ) -> IOSAppVersion {
        guard let installed else {
            return source
        }
        let sourceMarketing = VersionNumber(source.marketingVersion)!
        let installedMarketing = VersionNumber(
            installed.marketingVersion
        )!
        let sourceBuild = VersionNumber(source.buildVersion)!
        let installedBuild = VersionNumber(installed.buildVersion)!
        return IOSAppVersion(
            marketingVersion: max(
                sourceMarketing,
                installedMarketing
            ).description,
            buildVersion: max(
                sourceBuild,
                installedBuild
            ).description
        )!
    }

    private struct VersionNumber: Comparable, CustomStringConvertible {
        let components: [UInt]

        init?(_ value: String) {
            guard !value.isEmpty,
                  value == value.trimmingCharacters(
                      in: .whitespacesAndNewlines
                  )
            else {
                return nil
            }
            let parts = value.split(
                separator: ".",
                omittingEmptySubsequences: false
            )
            guard (1...3).contains(parts.count) else {
                return nil
            }
            var parsed: [UInt] = []
            parsed.reserveCapacity(parts.count)
            for part in parts {
                guard !part.isEmpty,
                      part.allSatisfy(\.isNumber),
                      let component = UInt(part)
                else {
                    return nil
                }
                parsed.append(component)
            }
            guard parsed.last != UInt.max else {
                return nil
            }
            components = parsed
        }

        private init(components: [UInt]) {
            self.components = components
        }

        var description: String {
            components.map(String.init).joined(separator: ".")
        }

        func incremented() -> VersionNumber? {
            guard let last = components.last, last < UInt.max else {
                return nil
            }
            var next = components
            next[next.count - 1] = last + 1
            return VersionNumber(components: next)
        }

        static func < (
            lhs: VersionNumber,
            rhs: VersionNumber
        ) -> Bool {
            let count = max(lhs.components.count, rhs.components.count)
            for index in 0..<count {
                let lhsComponent = index < lhs.components.count
                    ? lhs.components[index]
                    : 0
                let rhsComponent = index < rhs.components.count
                    ? rhs.components[index]
                    : 0
                if lhsComponent != rhsComponent {
                    return lhsComponent < rhsComponent
                }
            }
            return false
        }
    }
}
