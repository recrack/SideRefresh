import SideRefreshAppPresentation
import SwiftUI

extension View {
    @ViewBuilder
    func simpleSettingsPageStyle(
        isEmbedded: Bool = false
    ) -> some View {
        let size = SimpleSettingsWindowSizePolicy.initialSize
        if isEmbedded {
            padding(22)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(SimpleWorkspacePalette.canvas)
                .tint(SimpleWorkspacePalette.blue)
        } else {
            padding(22)
                .frame(minWidth: size.width, minHeight: size.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(SimpleWorkspacePalette.canvas)
                .tint(SimpleWorkspacePalette.blue)
        }
    }
}
