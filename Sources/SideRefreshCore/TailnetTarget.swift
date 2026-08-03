import Foundation

public enum TailnetTargetError: LocalizedError, Equatable {
    case deviceNotFound(String)
    case deviceOffline(String)
    case addressUnavailable(String)

    public var errorDescription: String? {
        switch self {
        case let .deviceNotFound(name):
            return "Tailnet에서 \(name) 기기를 찾을 수 없습니다."
        case let .deviceOffline(name):
            return "\(name) 기기가 Tailnet에서 오프라인입니다."
        case let .addressUnavailable(name):
            return "\(name) 기기의 현재 Tailscale IP를 찾을 수 없습니다."
        }
    }
}

public struct TailnetTarget: Codable, Equatable, Sendable {
    public let tailscaleExecutable: String
    public let nodeID: String
    public let dnsName: String

    public init(
        tailscaleExecutable: String,
        nodeID: String,
        dnsName: String
    ) {
        self.tailscaleExecutable = tailscaleExecutable
        self.nodeID = nodeID
        self.dnsName = dnsName
    }

    public func matchingDevice(
        in snapshot: TailnetSnapshot
    ) -> TailnetDevice? {
        snapshot.devices.first(where: { $0.id == nodeID })
            ?? snapshot.devices.first(where: {
                $0.dnsName?.caseInsensitiveCompare(dnsName) == .orderedSame
            })
    }

    public func resolve(in snapshot: TailnetSnapshot) throws -> TailnetDevice {
        guard let device = matchingDevice(in: snapshot) else {
            throw TailnetTargetError.deviceNotFound(dnsName)
        }
        guard device.isOnline == true else {
            throw TailnetTargetError.deviceOffline(dnsName)
        }
        guard device.preferredIPAddress != nil else {
            throw TailnetTargetError.addressUnavailable(dnsName)
        }
        return device
    }

    enum CodingKeys: String, CodingKey {
        case tailscaleExecutable = "tailscale_executable"
        case nodeID = "node_id"
        case dnsName = "dns_name"
    }
}
