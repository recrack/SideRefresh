import AppKit
import SideRefreshCore

extension SideRefreshViewModel {
    var availableTailscaleExecutableURLs: [URL] {
        TailscaleMacInstallation.availableExecutableURLs(
            preferredPath: tailscaleExecutablePath
        )
    }

    var availableTailscaleExecutablePath: String? {
        availableTailscaleExecutableURLs.first?.path
    }

    var tailscaleExecutableIsAvailable: Bool {
        availableTailscaleExecutablePath != nil
    }

    var tailscaleApplicationIsInstalled: Bool {
        TailscaleMacInstallation.isApplicationInstalled
    }

    func openTailscaleApplicationOrDownload() {
        if let applicationURL = TailscaleMacInstallation
            .applicationURLs.first,
           NSWorkspace.shared.open(applicationURL)
        {
            return
        }
        NSWorkspace.shared.open(TailscaleMacInstallation.downloadURL)
    }

    func openTailscaleDownloadPage() {
        NSWorkspace.shared.open(TailscaleMacInstallation.downloadURL)
    }
}
