import SideRefreshAppPresentation
import SwiftUI

extension SimpleWorkspaceAutomationMethodView {
    @ViewBuilder
    var backgroundRow: some View {
        if settingsAreAvailable {
            editableRow(
                "자동 갱신",
                value: presentation.backgroundTitle,
                detail: presentation.backgroundDetail,
                systemImage: backgroundImage,
                tint: backgroundTint,
                control: .automationSettings
            )
        } else {
            methodRow(
                "자동 갱신",
                identifier: "simple.automation.status",
                value: presentation.backgroundTitle,
                detail: presentation.backgroundDetail,
                systemImage: backgroundImage,
                tint: backgroundTint
            )
        }
    }

    @ViewBuilder
    var connectionRow: some View {
        if settingsAreAvailable {
            editableRow(
                "연결",
                value: presentation.connectionTitle,
                detail: presentation.connectionDetail,
                systemImage: "iphone.gen3",
                tint: SimpleWorkspacePalette.blue,
                control: .connectionSettings
            )
        } else {
            methodRow(
                "연결",
                identifier: "simple.automation.connection",
                value: presentation.connectionTitle,
                detail: presentation.connectionDetail,
                systemImage: "iphone.gen3",
                tint: SimpleWorkspacePalette.blue
            )
        }
    }

    func editableRow(
        _ title: String,
        value: String,
        detail: String?,
        systemImage: String,
        tint: Color,
        control: SimpleWorkspaceControl
    ) -> some View {
        SimpleWorkspaceAutomationEditableRow(
            title: title,
            value: value,
            detail: detail,
            systemImage: systemImage,
            tint: tint,
            control: control,
            focus: focus,
            accessibilityFocus: accessibilityFocus
        ) {
            onRoute(.destination(.settings), control)
        }
    }
}
