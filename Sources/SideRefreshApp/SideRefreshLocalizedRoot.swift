import SideRefreshAppPresentation
import SwiftUI

struct SideRefreshLocalizedRoot<Content: View>: View {
    @AppStorage(SideRefreshLocalization.preferenceKey)
    private var languageRawValue =
        SideRefreshLanguagePreference.system.rawValue
    @Environment(\.locale) private var inheritedLocale

    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    private var language: SideRefreshLanguagePreference {
        SideRefreshLanguagePreference(rawValue: languageRawValue)
            ?? .system
    }

    var body: some View {
        content()
            .environment(
                \.locale,
                language.locale(fallingBackTo: inheritedLocale)
            )
    }
}
