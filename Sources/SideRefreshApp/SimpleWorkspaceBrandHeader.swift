import SideRefreshAppPresentation
import SwiftUI

struct SimpleWorkspaceBrandHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage(SideRefreshLocalization.preferenceKey)
    private var languageRawValue =
        SideRefreshLanguagePreference.system.rawValue

    private var language: SideRefreshLanguagePreference {
        SideRefreshLanguagePreference(rawValue: languageRawValue)
            ?? .system
    }

    private var tagline: String {
        SideRefreshLocalization.string(
            "Keep agent-built iOS apps alive on your iPhone",
            language: language
        )
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    SideRefreshMark(size: 32)
                    brandText
                }
            } else {
                HStack(spacing: 10) {
                    SideRefreshMark(size: 32)
                    brandText
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("SideRefresh. \(tagline)")
        .accessibilityIdentifier(SimpleWorkspaceRegion.brand.rawValue)
    }

    private var brandText: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("SideRefresh")
                .font(.headline.weight(.semibold))
            Text(verbatim: tagline)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(
                    dynamicTypeSize.isAccessibilitySize ? nil : 3
                )
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
    }
}
