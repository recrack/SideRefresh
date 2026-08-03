import AppKit

@MainActor
final class AppWindowActivationCoordinator {
    static let shared = AppWindowActivationCoordinator()

    private var visibleWindowIdentifiers: Set<ObjectIdentifier> = []

    private init() {}

    func windowDidShow(_ window: NSWindow) {
        visibleWindowIdentifiers.insert(ObjectIdentifier(window))
        NSApp.setActivationPolicy(.regular)
    }

    func windowWillClose(_ window: NSWindow) {
        visibleWindowIdentifiers.remove(ObjectIdentifier(window))
        if visibleWindowIdentifiers.isEmpty {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
