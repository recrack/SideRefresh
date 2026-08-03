import AppKit
import SideRefreshAppPresentation
import SwiftUI

extension SimpleWorkspaceWindowPresenter {
    func makeWindow(
        controller: NSHostingController<AnyView>,
        title: String
    ) -> NSWindow {
        let initialSize = SimpleWorkspaceWindowSizePolicy.initialSize
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
        window.title = title
        window.identifier = NSUserInterfaceItemIdentifier(
            "SideRefreshSimpleWorkspace"
        )
        window.contentViewController = controller
        let minimumSize = SimpleWorkspaceWindowSizePolicy.minimumSize
        window.contentMinSize = NSSize(
            width: minimumSize.width,
            height: minimumSize.height
        )
        window.isReleasedWhenClosed = false
        window.tabbingMode = .disallowed
        window.collectionBehavior.insert(.moveToActiveSpace)
        window.delegate = self
        restoreFrame(of: window)
        window.setFrameAutosaveName(Self.frameName)
        return window
    }

    private func restoreFrame(of window: NSWindow) {
        guard window.setFrameUsingName(Self.frameName) else {
            window.center()
            return
        }
        let restored = window.contentRect(
            forFrameRect: window.frame
        ).size
        let size = SimpleWorkspaceWindowSizePolicy.sizeAfterRestore(
            width: restored.width,
            height: restored.height
        )
        window.setContentSize(
            NSSize(width: size.width, height: size.height)
        )
    }
}
