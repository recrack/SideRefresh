import SwiftUI

extension SimpleWorkspaceAutomationMethodView {
    var backgroundImage: String {
        switch presentation.background {
        case .enabled: "checkmark.circle.fill"
        case .notRegistered: "pause.circle.fill"
        case .approvalRequired: "exclamationmark.triangle.fill"
        case .helperMissing: "xmark.circle.fill"
        case .unknown: "questionmark.circle.fill"
        }
    }

    var backgroundTint: Color {
        presentation.background == .enabled
            ? SimpleWorkspacePalette.mint
            : SimpleWorkspacePalette.amber
    }
}
