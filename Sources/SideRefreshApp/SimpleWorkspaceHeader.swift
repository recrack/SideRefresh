import Foundation
import SideRefreshAppPresentation
import SwiftUI

struct SimpleWorkspaceHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage(SideRefreshLocalization.preferenceKey)
    private var languageRawValue =
        SideRefreshLanguagePreference.system.rawValue

    let relationship: RenewalRelationship?
    let evidence: LastVerifiedEvidence?

    private var language: SideRefreshLanguagePreference {
        SideRefreshLanguagePreference(rawValue: languageRawValue)
            ?? .system
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 24) {
                currentApp
                Spacer(minLength: 20)
                lastVerified
            }
            VStack(alignment: .leading, spacing: 12) {
                currentApp
                lastVerified
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var currentApp: some View {
        HStack(alignment: .top, spacing: 12) {
            ProjectAppIcon(
                iconURL: relationship?.appIconURL,
                fallbackSystemImage: "app.fill",
                size: 44
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(
                    relationship?.appName
                        ?? localized("내 앱")
                )
                    .font(.title2.weight(.semibold))
                    .lineLimit(
                        dynamicTypeSize.isAccessibilitySize ? nil : 1
                    )
                Text(verbatim: appDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(
                        dynamicTypeSize.isAccessibilitySize ? nil : 2
                    )
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(
            SimpleWorkspaceRegion.currentApp.rawValue
        )
    }

    private var lastVerified: some View {
        HStack(spacing: 8) {
            Image(
                systemName: evidence == nil
                    ? "clock.badge.questionmark"
                    : "checkmark.seal.fill"
            )
                .foregroundStyle(
                    evidence == nil
                        ? SimpleWorkspacePalette.amber
                        : SimpleWorkspacePalette.mint
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("마지막 검증")
                    .font(.caption.weight(.semibold))
                Text(verbatim: lastVerifiedDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(lastVerifiedAccessibilityLabel)
        .accessibilityIdentifier(
            SimpleWorkspaceRegion.evidence.rawValue
        )
        .help(
            localized(
                "이 기록은 현재 iPhone 연결 상태를 뜻하지 않습니다."
            )
        )
    }

    private var appDescription: String {
        guard let relationship else {
            return localized("갱신할 앱을 선택하세요.")
        }
        let bundleIdentifier = normalized(
            relationship.bundleIdentifier
        )
        let version = normalized(relationship.appVersion).map {
            SideRefreshLocalizedText.format(
                "버전 %@",
                .verbatim($0)
            ).resolved(language: language)
        }
        let values = [bundleIdentifier, version].compactMap { $0 }
        return values.isEmpty
            ? localized("앱 미설정")
            : values.joined(separator: "\n")
    }

    private var lastVerifiedDescription: String {
        guard let evidence else {
            return localized("기록 없음")
        }
        return SideRefreshLocalization.date(
            evidence.installedAt,
            dateStyle: .medium,
            timeStyle: .short,
            language: language
        )
    }

    private var lastVerifiedAccessibilityLabel: String {
        let historicalNote = localized(
            "이 기록은 현재 iPhone 연결 상태를 뜻하지 않습니다."
        )
        guard let evidence else {
            return [
                localized("마지막 검증"),
                localized("기록 없음"),
                historicalNote,
            ].joined(separator: ", ")
        }
        let installed = SideRefreshLocalization.date(
            evidence.installedAt,
            dateStyle: .medium,
            timeStyle: .short,
            language: language
        )
        let expiration = SideRefreshLocalization.date(
            evidence.expiresAt,
            dateStyle: .medium,
            timeStyle: .short,
            language: language
        )
        let summary = SideRefreshLocalizedText.format(
            "%@ 설치 확인 · %@ 서명 만료",
            .verbatim(installed),
            .verbatim(expiration)
        ).resolved(language: language)
        return [
            localized("마지막 검증"),
            summary,
            historicalNote,
        ].joined(separator: ", ")
    }

    private func localized(_ source: String) -> String {
        SideRefreshLocalization.string(
            source,
            language: language
        )
    }

    private func normalized(_ value: String?) -> String? {
        let value = value?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""
        return value.isEmpty ? nil : value
    }
}
