import SideRefreshAppPresentation
import SwiftUI

struct SimpleWorkspaceActivityView: View {
    let presentation: RenewalPresentation

    @ViewBuilder
    var body: some View {
        if let progress = presentation.progress {
            activity(
                title: "갱신 진행 중",
                detail: progress.message,
                systemImage: "arrow.triangle.2.circlepath",
                identifier: SimpleWorkspaceRegion.progress.rawValue,
                color: SimpleWorkspacePalette.blue
            )
        } else if let result = presentation.recentResult {
            activity(
                title: resultTitle(result.outcome),
                detail: result.summary,
                systemImage: resultSystemImage(result.outcome),
                identifier:
                    SimpleWorkspaceRegion.recentResult.rawValue,
                color: resultColor(result.outcome)
            )
        }
    }

    private func activity(
        title: String,
        detail: String,
        systemImage: String,
        identifier: String,
        color: Color
    ) -> some View {
        HStack(spacing: 13) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 3) {
                Text(SideRefreshLocalization.string(title))
                    .font(.callout.weight(.semibold))
                Text(verbatim: detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .simpleWorkspaceCard()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }

    private func resultTitle(
        _ outcome: RenewalRecentOutcome
    ) -> String {
        switch outcome {
        case .verified:
            return "최근 갱신이 검증됐습니다"
        case .failed:
            return "최근 갱신을 완료하지 못했습니다"
        }
    }

    private func resultSystemImage(
        _ outcome: RenewalRecentOutcome
    ) -> String {
        switch outcome {
        case .verified:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    private func resultColor(
        _ outcome: RenewalRecentOutcome
    ) -> Color {
        switch outcome {
        case .verified:
            return SimpleWorkspacePalette.mint
        case .failed:
            return SimpleWorkspacePalette.amber
        }
    }
}
