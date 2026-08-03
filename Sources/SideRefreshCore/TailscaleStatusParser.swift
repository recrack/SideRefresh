import Foundation

public struct TailnetDevice: Codable, Equatable, Sendable {
    public let id: String?
    public let hostName: String
    public let dnsName: String?
    public let operatingSystem: String
    public let addresses: [String]
    public let preferredIPAddress: String?
    public let isOnline: Bool?
    public let isSelf: Bool

    public init(
        id: String?,
        hostName: String,
        dnsName: String?,
        operatingSystem: String,
        addresses: [String],
        preferredIPAddress: String?,
        isOnline: Bool?,
        isSelf: Bool
    ) {
        self.id = id
        self.hostName = hostName
        self.dnsName = dnsName
        self.operatingSystem = operatingSystem
        self.addresses = addresses
        self.preferredIPAddress = preferredIPAddress
        self.isOnline = isOnline
        self.isSelf = isSelf
    }
}

public struct TailnetSnapshot: Equatable, Sendable {
    public let devices: [TailnetDevice]

    public var iOSDevices: [TailnetDevice] {
        devices.filter {
            $0.operatingSystem.caseInsensitiveCompare("iOS") == .orderedSame
        }
    }
}

public enum TailscaleStatusParser {
    public static func parse(_ data: Data) throws -> TailnetSnapshot {
        let status = try JSONDecoder().decode(Status.self, from: data)
        var devices: [TailnetDevice] = []
        if let selfNode = status.selfNode {
            devices.append(device(from: selfNode, isSelf: true))
        }
        devices.append(
            contentsOf: status.peers.values.map {
                device(from: $0, isSelf: false)
            }
        )
        devices.sort {
            if $0.isSelf != $1.isSelf {
                return $0.isSelf
            }
            return $0.hostName.localizedCaseInsensitiveCompare($1.hostName)
                == .orderedAscending
        }
        return TailnetSnapshot(devices: devices)
    }

    private struct Status: Decodable {
        let selfNode: Node?
        let peers: [String: Node]

        enum CodingKeys: String, CodingKey {
            case selfNode = "Self"
            case peers = "Peer"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            selfNode = try container.decodeIfPresent(
                Node.self,
                forKey: .selfNode
            )
            peers = try container.decodeIfPresent(
                [String: Node].self,
                forKey: .peers
            ) ?? [:]
        }
    }

    private struct Node: Decodable {
        let id: String?
        let hostName: String
        let dnsName: String?
        let operatingSystem: String
        let addresses: [String]
        let isOnline: Bool?

        enum CodingKeys: String, CodingKey {
            case id = "ID"
            case hostName = "HostName"
            case dnsName = "DNSName"
            case operatingSystem = "OS"
            case addresses = "TailscaleIPs"
            case isOnline = "Online"
        }
    }

    private static func device(
        from node: Node,
        isSelf: Bool
    ) -> TailnetDevice {
        TailnetDevice(
            id: node.id,
            hostName: node.hostName,
            dnsName: node.dnsName,
            operatingSystem: node.operatingSystem,
            addresses: node.addresses,
            preferredIPAddress: node.addresses.first(where: isIPv4Address)
                ?? node.addresses.first,
            isOnline: node.isOnline,
            isSelf: isSelf
        )
    }

    private static func isIPv4Address(_ value: String) -> Bool {
        let components = value.split(
            separator: ".",
            omittingEmptySubsequences: false
        )
        return components.count == 4
            && components.allSatisfy {
                guard let octet = UInt16($0) else {
                    return false
                }
                return octet <= 255
            }
    }
}
