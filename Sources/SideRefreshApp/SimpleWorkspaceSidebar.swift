import SideRefreshAppPresentation
import SwiftUI

struct SimpleWorkspaceSidebar: View {
    @AppStorage(SideRefreshLocalization.preferenceKey)
    private var languageRawValue =
        SideRefreshLanguagePreference.system.rawValue

    let selectedPage: SimpleWorkspacePage
    let focus: FocusState<SimpleWorkspaceControl?>.Binding
    let accessibilityFocus:
        AccessibilityFocusState<
            SimpleWorkspaceAccessibilityFocus?
        >.Binding
    let onSelectPage: (SimpleWorkspacePage) -> Void

    private var language: SideRefreshLanguagePreference {
        SideRefreshLanguagePreference(rawValue: languageRawValue)
            ?? .system
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SimpleWorkspaceBrandHeader()
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 22)

            homeRow

            Divider()
                .padding(.vertical, 10)

            destinationRow(
                .settings,
                page: .settings,
                title: "설정",
                systemImage: "gearshape"
            )
            destinationRow(
                .help,
                page: .help,
                title: "도움말",
                systemImage: "questionmark.circle"
            )
            destinationRow(
                .diagnostics,
                page: .diagnostics,
                title: "진단 로그",
                systemImage: "waveform.path.ecg"
            )

            Spacer(minLength: 16)
        }
        .padding(12)
        .frame(width: 188)
        .background(Color(nsColor: .controlBackgroundColor))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(
            SimpleWorkspaceRegion.navigation.rawValue
        )
    }

    private var homeRow: some View {
        Button {
            onSelectPage(.home)
        } label: {
            Label("내 앱", systemImage: "app")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .font(.callout.weight(
            selectedPage == .home ? .semibold : .regular
        ))
        .background(selectionBackground(for: .home))
        .accessibilityAddTraits(
            selectedPage == .home ? .isSelected : []
        )
        .accessibilityLabel(
            SideRefreshLocalization.string(
                "내 앱",
                language: language
            )
        )
        .accessibilityValue(
            SideRefreshLocalization.string(
                "내 앱",
                language: language
            )
        )
        .accessibilityIdentifier(
            SimpleWorkspaceAccessibility.sidebarHome
        )
    }

    private func destinationRow(
        _ control: SimpleWorkspaceControl,
        page: SimpleWorkspacePage,
        title: String,
        systemImage: String
    ) -> some View {
        Button {
            onSelectPage(page)
        } label: {
            Label(
                SideRefreshLocalization.string(
                    title,
                    language: language
                ),
                systemImage: systemImage
            )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .font(.callout.weight(
            selectedPage == page ? .semibold : .regular
        ))
        .background(selectionBackground(for: page))
        .focused(focus, equals: control)
        .accessibilityFocused(
            accessibilityFocus,
            equals: .control(control)
        )
        .accessibilityLabel(
            SideRefreshLocalization.string(
                title,
                language: language
            )
        )
        .accessibilityValue(
            SideRefreshLocalization.string(
                title,
                language: language
            )
        )
        .accessibilityAddTraits(
            selectedPage == page ? .isSelected : []
        )
        .accessibilityIdentifier(control.rawValue)
    }

    private func selectionBackground(
        for page: SimpleWorkspacePage
    ) -> some View {
        RoundedRectangle(
            cornerRadius: 8,
            style: .continuous
        )
        .fill(
            selectedPage == page
                ? SimpleWorkspacePalette.blue.opacity(0.14)
                : .clear
        )
    }
}
