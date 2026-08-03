#if DEBUG
import AppKit
import SideRefreshAppPresentation

@MainActor
enum SimpleWorkspaceFixtureCapture {
    private static let iconKey =
        "SIDEREFRESH_UI_FIXTURE_APP_ICON"
    private static let outputKey =
        "SIDEREFRESH_UI_FIXTURE_OUTPUT"
    private static let previewKey =
        "SIDEREFRESH_UI_FIXTURE_PREVIEW"
    private static var preparedIcon: (url: URL, image: NSImage)?

    static var isPreview: Bool {
        SimpleWorkspaceFixturePresentationPolicy
            .showsPreviewIdentity(
                previewRequested:
                    ProcessInfo.processInfo.environment[previewKey] == "1",
                capturesOutput: capturesOutput
            )
    }

    static var capturesOutput: Bool {
        outputURL != nil
    }

    static var isRequested: Bool {
        capturesOutput || isPreview
    }

    static func prepareIfRequested() -> Bool {
        guard isRequested else {
            return true
        }
        guard let path = ProcessInfo.processInfo.environment[iconKey],
              !path.isEmpty else {
            report(CaptureError.missingIcon)
            return false
        }
        let url = URL(fileURLWithPath: path).standardizedFileURL
        guard let image = NSImage(contentsOf: url) else {
            report(CaptureError.invalidIcon)
            return false
        }
        preparedIcon = (url, image)
        return true
    }

    static func preparedIcon(for url: URL?) -> NSImage? {
        guard let url, let preparedIcon,
              url.standardizedFileURL == preparedIcon.url else {
            return nil
        }
        return preparedIcon.image
    }

    static func captureIfRequested(window: NSWindow) {
        guard let outputURL else {
            return
        }
        let size = SimpleWorkspaceWindowSizePolicy.initialSize
        window.setContentSize(
            NSSize(width: size.width, height: size.height)
        )
        window.appearance = NSAppearance(named: .darkAqua)
        window.center()
        DispatchQueue.main.async {
            do {
                try capture(window: window, to: outputURL)
            } catch {
                report(error)
            }
            NSApp.terminate(nil)
        }
    }

    private static var outputURL: URL? {
        guard let path = ProcessInfo.processInfo.environment[
            outputKey
        ], !path.isEmpty else {
            return nil
        }
        return URL(fileURLWithPath: path).standardizedFileURL
    }
}
#endif
