import SideRefreshAppPresentation
import SwiftUI

struct SimpleSettingsSaveBar: View {
    @ObservedObject var model: SideRefreshViewModel
    let requestSave: () -> Void

    var body: some View {
        let presentation = SimpleSettingsSaveBarPresentation.resolve(
            hasSavedConfiguration: model.isConfigured,
            configurationIsDirty: model.configurationIsDirty,
            readiness: model.simpleSettingsSaveReadiness
        )
        HStack(spacing: 12) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(
                        SideRefreshLocalization.string(
                            presentation.title
                        )
                    )
                        .font(.callout.weight(.semibold))
                    Text(
                        SideRefreshLocalization.string(
                            presentation.detail
                        )
                    )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(
                    systemName: systemImage(for: presentation.status)
                )
                .foregroundStyle(
                    color(for: presentation.status)
                )
            }
            Spacer(minLength: 12)
            Button(action: requestSave) {
                Text(
                    SideRefreshLocalization.string(
                        presentation.actionTitle
                    )
                )
            }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("s", modifiers: .command)
                .disabled(!presentation.actionIsEnabled)
                .accessibilityIdentifier("simple.settings.save")
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 14)
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("simple.settings.save-bar")
    }

    private func systemImage(
        for status: SimpleSettingsSaveBarStatus
    ) -> String {
        switch status {
        case .incomplete: "circle.dashed"
        case .needsSave: "exclamationmark.circle.fill"
        case .saved: "checkmark.circle.fill"
        }
    }

    private func color(
        for status: SimpleSettingsSaveBarStatus
    ) -> Color {
        switch status {
        case .incomplete: .secondary
        case .needsSave: SimpleWorkspacePalette.amber
        case .saved: SimpleWorkspacePalette.mint
        }
    }
}
