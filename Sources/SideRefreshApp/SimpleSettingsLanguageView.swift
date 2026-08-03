import Foundation
import SideRefreshAppPresentation
import SwiftUI

struct SimpleSettingsLanguageView: View {
    @ObservedObject var model: SideRefreshViewModel
    @AppStorage(SideRefreshLocalization.preferenceKey)
    private var languageRawValue =
        SideRefreshLanguagePreference.system.rawValue

    private var language: Binding<SideRefreshLanguagePreference> {
        Binding(
            get: {
                SideRefreshLanguagePreference(
                    rawValue: languageRawValue
                ) ?? .system
            },
            set: { newValue in
                SideRefreshLocalization.setLanguagePreference(
                    newValue
                )
                languageRawValue = newValue.rawValue
                SideRefreshWindowLanguageCoordinator
                    .refreshOpenWindowTitles()
                DispatchQueue.main.async {
                    model.languagePreferenceDidChange()
                }
            }
        )
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "globe")
                .font(.title3)
                .foregroundStyle(SimpleWorkspacePalette.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text("언어")
                    .font(.headline)
                Text("SideRefresh에서 사용할 언어를 선택하세요.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 16)

            Picker("언어", selection: language) {
                Text("시스템 설정 따르기")
                    .tag(SideRefreshLanguagePreference.system)
                Text(verbatim: "한국어")
                    .tag(SideRefreshLanguagePreference.korean)
                Text(verbatim: "English")
                    .tag(SideRefreshLanguagePreference.english)
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 190)
            .accessibilityIdentifier("simple.settings.language.picker")
        }
        .simpleWorkspaceCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("simple.settings.language")
    }
}
