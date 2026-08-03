import SideRefreshAppPresentation
import SwiftUI

struct SimpleWorkspaceEndpoint: View {
    let title: String
    let name: String
    let detail: String?
    let showsCompletionCheck: Bool
    let systemImage: String

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: systemImage)
                .font(.system(size: 23, weight: .medium))
                .foregroundStyle(SimpleWorkspacePalette.blue)
                .frame(width: 38)
            VStack(alignment: .leading, spacing: 3) {
                Text(SideRefreshLocalization.string(title))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(verbatim: name)
                    .font(.headline)
                    .lineLimit(1)
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
            .frame(maxWidth: .infinity, alignment: .leading)
            if showsCompletionCheck {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(SimpleWorkspacePalette.mint)
                    .accessibilityHidden(true)
            }
        }
    }
}
