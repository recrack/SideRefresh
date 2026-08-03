import Foundation
import SideRefreshAppPresentation
import SwiftUI

struct SimpleWorkspaceTimingView: View {
    let presentation: RenewalPresentation
    let automaticRenewalMethod: RenewalAutomationMethod.Presentation
    let settingsAreAvailable: Bool
    let focus: FocusState<SimpleWorkspaceControl?>.Binding
    let accessibilityFocus:
        AccessibilityFocusState<
            SimpleWorkspaceAccessibilityFocus?
        >.Binding
    let onRoute: (AppPresentationRoute, SimpleWorkspaceControl) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                metric(
                    RenewalAutomationMethod.nextEligibilityTitle,
                    date: presentation.nextRenewalDate
                )
                Divider()
                    .padding(.vertical, 2)
                metric(
                    "현재 서명 만료",
                    date: presentation.signingExpirationDate
                )
            }
            Divider()
            SimpleWorkspaceAutomationMethodView(
                presentation: automaticRenewalMethod,
                settingsAreAvailable: settingsAreAvailable,
                focus: focus,
                accessibilityFocus: accessibilityFocus,
                onRoute: onRoute
            )
            .padding(.horizontal, 6)
        }
        .simpleWorkspaceCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(
            SimpleWorkspaceRegion.timing.rawValue
        )
    }

    private func metric(
        _ title: String,
        date: Date?
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(SideRefreshLocalization.string(title))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(SideRefreshLocalization.string(dateText(date)))
                .font(.callout.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(SideRefreshLocalization.string(title))
        .accessibilityValue(
            SideRefreshLocalization.string(dateText(date))
        )
    }

    private func dateText(_ date: Date?) -> String {
        guard let date else {
            return "아직 확인되지 않음"
        }
        return SideRefreshLocalization.date(
            date,
            dateStyle: .medium,
            timeStyle: .short
        )
    }
}
