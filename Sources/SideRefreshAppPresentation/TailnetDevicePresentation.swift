import Foundation
import SideRefreshCore

public struct TailnetDeviceStatusPresentation: Equatable, Sendable {
    public let title: String
    public let detail: String

    public init(title: String, detail: String) {
        self.title = title
        self.detail = detail
    }
}

public enum TailnetDevicePresentation {
    public static func pickerLabel(
        for device: TailnetDevice
    ) -> String {
        [
            displayName(for: device),
            device.preferredIPAddress
                ?? SideRefreshLocalization.string("주소 미확인"),
            identifierDetail(device.id),
        ].joined(separator: " · ")
    }

    public static func status(
        for device: TailnetDevice
    ) -> TailnetDeviceStatusPresentation {
        switch device.isOnline {
        case .some(true):
            return TailnetDeviceStatusPresentation(
                title: SideRefreshLocalization.string(
                    "Tailscale 주소 확인 완료"
                ),
                detail: SideRefreshLocalization.string(
                    "위의 ‘Xcode에서 iPhone 확인’을 눌러"
                        + " 설치 기기를 확인하세요."
                )
            )
        case .some(false):
            return TailnetDeviceStatusPresentation(
                title: SideRefreshLocalization.string(
                    "iPhone이 Tailscale에서 오프라인"
                ),
                detail: SideRefreshLocalization.string(
                    "iPhone에서 Tailscale을 열고 VPN을 켠 뒤"
                        + " 다시 확인하세요."
                )
            )
        case .none:
            return TailnetDeviceStatusPresentation(
                title: SideRefreshLocalization.string(
                    "Tailscale 상태를 확인할 수 없음"
                ),
                detail: SideRefreshLocalization.string(
                    "Mac과 iPhone의 로그인을 확인한 뒤"
                        + " 주소를 다시 확인하세요."
                )
            )
        }
    }

    private static func displayName(
        for device: TailnetDevice
    ) -> String {
        let hostName = device.hostName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if !hostName.isEmpty,
           hostName.caseInsensitiveCompare("localhost") != .orderedSame
        {
            return hostName
        }
        let dnsName = device.dnsName?
            .trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        if let firstLabel = dnsName?.split(separator: ".").first,
           !firstLabel.isEmpty
        {
            return String(firstLabel)
        }
        return SideRefreshLocalization.string("이름 없는 iPhone")
    }

    private static func identifierDetail(_ identifier: String?) -> String {
        guard let identifier,
              !identifier.isEmpty
        else {
            return SideRefreshLocalization.string("식별자 미확인")
        }
        guard identifier.count > 10 else {
            return SideRefreshLocalization.format(
                "식별자 %@",
                identifier
            )
        }
        return SideRefreshLocalization.format(
            "식별자 %@…%@",
            String(identifier.prefix(6)),
            String(identifier.suffix(4)).uppercased()
        )
    }
}
