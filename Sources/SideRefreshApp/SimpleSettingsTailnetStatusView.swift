import SideRefreshAppPresentation
import SideRefreshCore
import SwiftUI

struct SimpleSettingsTailnetStatusView: View {
    let device: TailnetDevice

    var body: some View {
        let presentation = TailnetDevicePresentation.status(for: device)
        VStack(alignment: .leading, spacing: 4) {
            Label {
                Text(verbatim: presentation.title)
            } icon: {
                Image(systemName: statusImage)
            }
                .font(.callout)
                .foregroundStyle(statusColor)
            Text(verbatim: presentation.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let address = device.preferredIPAddress ?? device.dnsName {
                Text(verbatim: address)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
    }

    private var statusImage: String {
        switch device.isOnline {
        case .some(true):
            return "network"
        case .some(false):
            return "network.slash"
        case .none:
            return "questionmark.circle"
        }
    }

    private var statusColor: Color {
        device.isOnline == true
            ? SimpleWorkspacePalette.mint
            : .secondary
    }
}
