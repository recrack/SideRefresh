import SideRefreshAppPresentation
import SwiftUI

struct SimpleWorkspaceAutomationEditableRow: View {
    let title: String
    let value: String
    let detail: String?
    let systemImage: String
    let tint: Color
    let control: SimpleWorkspaceControl
    let focus: FocusState<SimpleWorkspaceControl?>.Binding
    let accessibilityFocus:
        AccessibilityFocusState<
            SimpleWorkspaceAccessibilityFocus?
        >.Binding
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                Text(SideRefreshLocalization.string(title))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 12)
                HStack(spacing: 10) {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: systemImage)
                                .foregroundStyle(tint)
                            Text(SideRefreshLocalization.string(value))
                                .fontWeight(.medium)
                                .multilineTextAlignment(.trailing)
                        }
                        if let detail {
                            Text(SideRefreshLocalization.string(detail))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focused(focus, equals: control)
        .accessibilityFocused(
            accessibilityFocus,
            equals: .control(control)
        )
        .accessibilityLabel(SideRefreshLocalization.string(title))
        .accessibilityValue(accessibilityValue)
        .accessibilityHint("설정을 열어 변경합니다.")
        .accessibilityIdentifier(control.rawValue)
    }

    private var accessibilityValue: String {
        let localizedValue = SideRefreshLocalization.string(value)
        guard let detail else { return localizedValue }
        return "\(localizedValue). "
            + SideRefreshLocalization.string(detail)
    }
}
