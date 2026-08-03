import AppKit
import SideRefreshAppPresentation
import SwiftUI

struct SimpleWorkspaceProgressAnnouncementModifier: ViewModifier {
    let progress: RenewalPresentationProgress?
    @State private var lastAnnouncedPhase: String?

    func body(content: Content) -> some View {
        content
            .onAppear {
                announceIfNeeded(progress)
            }
            .onChange(of: progress?.phase) { _ in
                announceIfNeeded(progress)
            }
    }

    private func announceIfNeeded(
        _ progress: RenewalPresentationProgress?
    ) {
        guard let progress else {
            lastAnnouncedPhase = nil
            return
        }
        let phaseKey = progress.phase.rawValue
        guard phaseKey != lastAnnouncedPhase,
              let application = NSApp
        else {
            return
        }
        lastAnnouncedPhase = phaseKey
        NSAccessibility.post(
            element: application,
            notification: .announcementRequested,
            userInfo: [
                .announcement: SideRefreshLocalization.format(
                    "갱신 진행: %@",
                    progress.message
                ),
                .priority:
                    NSAccessibilityPriorityLevel.medium.rawValue,
            ]
        )
    }
}
