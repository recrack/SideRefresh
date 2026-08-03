#if DEBUG
import SideRefreshAppPresentation
import SwiftUI

extension SimpleWorkspaceFixtureSettingsView {
    func fixtureCard<Content: View>(
        title: LocalizedStringKey,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(SimpleWorkspacePalette.blue)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .simpleWorkspaceCard()
    }

    func fixtureRow(
        _ title: LocalizedStringKey,
        value: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(verbatim: value)
                .font(.callout.weight(.medium))
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }

    var appName: String {
        normalized(relationship?.appName)
            ?? localized("앱 미설정")
    }

    var bundleIdentifier: String {
        normalized(relationship?.bundleIdentifier)
            ?? localized("미확인")
    }

    var appVersion: String {
        normalized(relationship?.appVersion)
            ?? localized("미확인")
    }

    var iPhoneName: String {
        normalized(relationship?.iPhoneName)
            ?? localized("iPhone 미선택")
    }

    func normalized(_ value: String?) -> String? {
        let value = value?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""
        return value.isEmpty ? nil : value
    }

    func localized(_ source: String) -> String {
        SideRefreshLocalization.string(source)
    }
}
#endif
