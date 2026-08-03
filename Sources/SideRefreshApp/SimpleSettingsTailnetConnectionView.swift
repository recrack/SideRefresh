import SwiftUI

struct SimpleSettingsTailnetConnectionView: View {
    @ObservedObject var model: SideRefreshViewModel
    @State private var hasCheckedInstallation = false
    @State private var executableIsAvailable = false
    @State private var applicationIsInstalled = false

    var body: some View {
        Group {
            if !hasCheckedInstallation {
                ProgressView("Tailscale 설치 상태 확인 중…")
            } else if executableIsAvailable {
                SimpleSettingsTailnetAvailableView(model: model)
            } else {
                SimpleSettingsTailnetMissingView(
                    applicationIsInstalled: applicationIsInstalled,
                    openTailscale:
                        model.openTailscaleApplicationOrDownload,
                    recheck: refreshAndDiscover
                )
            }
        }
        .padding(12)
        .background(
            SimpleWorkspacePalette.amber.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 10)
        )
        .onAppear(perform: refreshInstallation)
    }

    private func refreshInstallation() {
        executableIsAvailable =
            model.tailscaleExecutableIsAvailable
        applicationIsInstalled = executableIsAvailable
            || model.tailscaleApplicationIsInstalled
        hasCheckedInstallation = true
    }

    private func refreshAndDiscover() {
        refreshInstallation()
        if executableIsAvailable {
            model.discoverTailnetDevices()
        }
    }
}
