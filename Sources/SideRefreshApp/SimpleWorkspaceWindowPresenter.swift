import AppKit
import SideRefreshAppPresentation
import SwiftUI

@MainActor
final class SimpleWorkspaceWindowPresenter:
    NSObject,
    NSWindowDelegate
{
    static let shared = SimpleWorkspaceWindowPresenter()
    static let frameName = "SideRefreshSimpleWorkspaceFrame"

    private var controller: NSHostingController<AnyView>?
    private var window: NSWindow?

    func show(model: SideRefreshViewModel) {
        show(
            AnyView(
                SideRefreshLocalizedRoot {
                    SideRefreshSimpleWorkspaceHost(model: model)
                }
            ),
            title: SideRefreshLocalization.string("앱 갱신")
        )
    }

    #if DEBUG
    func show(fixture: SimpleWorkspaceFixture) {
        show(
            AnyView(
                SideRefreshLocalizedRoot {
                    SimpleWorkspaceFixtureHost(fixture: fixture)
                }
            ),
            title: SideRefreshLocalization.string(
                SimpleWorkspaceFixtureCapture.isPreview
                    ? "SideRefresh — 샘플 미리보기"
                    : "앱 갱신"
            )
        )
    }
    #endif

    private func show(_ rootView: AnyView, title: String) {
        let simpleWindow: NSWindow
        if let window, let controller {
            controller.rootView = rootView
            simpleWindow = window
        } else {
            let controller = NSHostingController(rootView: rootView)
            controller.sizingOptions = []
            let createdWindow = makeWindow(
                controller: controller,
                title: title
            )
            self.controller = controller
            window = createdWindow
            simpleWindow = createdWindow
        }
        simpleWindow.title = title
        AppWindowActivationCoordinator.shared.windowDidShow(simpleWindow)
        simpleWindow.makeKeyAndOrderFront(nil)
        simpleWindow.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        #if DEBUG
        SimpleWorkspaceFixtureCapture.captureIfRequested(
            window: simpleWindow
        )
        #endif
    }

    func windowWillClose(_ notification: Notification) {
        guard notification.object as? NSWindow === window else {
            return
        }
        let closingWindow = window
        window = nil
        controller = nil
        if let closingWindow {
            AppWindowActivationCoordinator.shared.windowWillClose(
                closingWindow
            )
        }
    }
}
