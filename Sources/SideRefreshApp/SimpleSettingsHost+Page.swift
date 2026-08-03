import SwiftUI

extension SimpleSettingsHost {
    @ViewBuilder
    var settingsPage: some View {
        switch page {
        case .overview:
            SimpleSettingsView(
                model: model,
                launchRequest: launchRequest,
                chooseApp: chooseApp,
                findIPhone: findIPhone,
                requestSave: requestSave,
                performAutomationAction: performAutomationAction,
                openDestination: openDestination,
                isEmbedded: isEmbedded
            )
        case .appSelection:
            ProjectPickerView(
                model: model,
                onSelection: {
                    completeAppSelection(.confirmed)
                },
                onClose: {
                    completeAppSelection(.cancelled)
                },
                isEmbedded: isEmbedded
            )
        case .iPhoneSelection:
            SimpleSettingsIPhonePickerPage(
                model: model,
                onClose: closeSelection,
                isEmbedded: isEmbedded
            )
        }
    }

    func closeSelection() {
        page = .overview
    }
}
