import SideRefreshAppPresentation
import SwiftUI

struct SimpleSettingsValueRow: View {
    let title: String
    let value: String
    let detail: String?
    let action: String
    let identifier: String
    let isDisabled: Bool
    let perform: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(SideRefreshLocalization.string(title))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(verbatim: value)
                    .font(.headline)
                if let detail {
                    Text(verbatim: detail)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }
            Spacer()
            Button(action: perform) {
                Text(SideRefreshLocalization.string(action))
            }
                .disabled(isDisabled)
                .accessibilityIdentifier(identifier)
        }
    }
}
