import AppKit
import SwiftUI

@MainActor
final class SimpleSettingsWindowPresenter: NSObject, NSWindowDelegate {
    static let shared = SimpleSettingsWindowPresenter()
    static let frameName = "SideRefreshSimpleSettingsFrame"

    private var controller: NSHostingController<AnyView>?
    private var window: NSWindow?
    private var onClose: (() -> Void)?
    private var onSave: (() -> Void)?
    private var model: SideRefreshViewModel?
    private var session: SimpleSettingsSession?
    private var launchGeneration = 0

    func show(
        model: SideRefreshViewModel,
        launchAction: SimpleSettingsLaunchAction = .none,
        session suppliedSession: SimpleSettingsSession? = nil,
        onSave: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self.onClose = onClose ?? self.onClose
        self.onSave = onSave
        self.model = model
        let session = suppliedSession
            ?? session
            ?? SimpleSettingsSession()
        self.session = session
        session.settingsDidOpen()
        launchGeneration += 1
        let generation = launchGeneration
        let root = AnyView(
            SideRefreshLocalizedRoot {
                SimpleSettingsHost(
                    model: model,
                    launchRequest: SimpleSettingsLaunchRequest(
                        action: launchAction,
                        generation: generation
                    ),
                    session: session,
                    onSuccessfulSave: { [weak self] in
                        self?.completeSuccessfulSave()
                    }
                )
                .id(generation)
            }
        )
        let settingsWindow: NSWindow
        if let window, let controller {
            controller.rootView = root
            settingsWindow = window
        } else {
            let controller = NSHostingController(rootView: root)
            let created = makeWindow(controller)
            self.controller = controller
            window = created
            settingsWindow = created
        }
        AppWindowActivationCoordinator.shared.windowDidShow(settingsWindow)
        settingsWindow.makeKeyAndOrderFront(nil)
        settingsWindow.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func completeSuccessfulSave() {
        let savedModel = model
        let save = onSave
        window?.close()
        if let save {
            save()
        } else if let savedModel {
            SimpleWorkspaceWindowPresenter.shared.show(
                model: savedModel
            )
            savedModel.announceSettingsSaved()
        }
    }

    func windowWillClose(_ notification: Notification) {
        guard notification.object as? NSWindow === window else { return }
        let closingWindow = window
        if let model, let session {
            session.restoreOnSettingsCloseIfNeeded(model: model)
        }
        self.window = nil
        self.controller = nil
        self.model = nil
        self.session = nil
        self.onSave = nil
        if let closingWindow {
            AppWindowActivationCoordinator.shared.windowWillClose(
                closingWindow
            )
        }
        let close = onClose
        onClose = nil
        close?()
    }
}
