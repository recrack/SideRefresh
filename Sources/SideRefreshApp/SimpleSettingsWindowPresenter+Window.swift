import AppKit
import SideRefreshAppPresentation
import SwiftUI

extension SimpleSettingsWindowPresenter {
    func makeWindow(
        _ controller: NSHostingController<AnyView>
    ) -> NSWindow {
        let initialSize = SimpleSettingsWindowSizePolicy.initialSize
        let window = NSWindow(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: initialSize.width,
                height: initialSize.height
            ),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = SideRefreshLocalization.string(
            "SideRefresh 설정"
        )
        window.identifier = NSUserInterfaceItemIdentifier(
            "SideRefreshSimpleSettings"
        )
        let minimumSize = SimpleSettingsWindowSizePolicy.minimumSize
        window.contentMinSize = NSSize(
            width: minimumSize.width,
            height: minimumSize.height
        )
        window.contentViewController = controller
        window.isReleasedWhenClosed = false
        window.tabbingMode = .disallowed
        window.collectionBehavior.insert(.moveToActiveSpace)
        window.delegate = self
        if window.setFrameUsingName(Self.frameName) {
            clampRestoredContentSize(window)
        } else {
            window.setContentSize(
                NSSize(
                    width: initialSize.width,
                    height: initialSize.height
                )
            )
            window.center()
        }
        window.setFrameAutosaveName(Self.frameName)
        return window
    }

    private func clampRestoredContentSize(_ window: NSWindow) {
        let restored = window.contentRect(
            forFrameRect: window.frame
        ).size
        let size = SimpleSettingsWindowSizePolicy.sizeAfterRestore(
            width: restored.width,
            height: restored.height
        )
        window.setContentSize(
            NSSize(width: size.width, height: size.height)
        )
    }
}
