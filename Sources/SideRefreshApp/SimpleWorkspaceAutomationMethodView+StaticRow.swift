import SideRefreshAppPresentation
import SwiftUI

extension SimpleWorkspaceAutomationMethodView {
    func methodRow(
        _ title: String,
        identifier: String,
        value: String,
        detail: String?,
        systemImage: String,
        tint: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(SideRefreshLocalization.string(title))
                .foregroundStyle(.secondary)
                .accessibilityIdentifier(identifier + ".label")
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: systemImage)
                        .foregroundStyle(tint)
                        .accessibilityHidden(true)
                    Text(SideRefreshLocalization.string(value))
                        .fontWeight(.medium)
                        .multilineTextAlignment(.trailing)
                        .accessibilityIdentifier(identifier + ".value")
                }
                if let detail {
                    Text(SideRefreshLocalization.string(detail))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
    }
}
