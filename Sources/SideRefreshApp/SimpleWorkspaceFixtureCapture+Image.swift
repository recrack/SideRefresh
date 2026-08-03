#if DEBUG
import AppKit

extension SimpleWorkspaceFixtureCapture {
    static func capture(
        window: NSWindow,
        to outputURL: URL
    ) throws {
        guard let view = window.contentView else {
            throw CaptureError.unavailable
        }
        view.layoutSubtreeIfNeeded()
        view.displayIfNeeded()
        let bounds = view.bounds
        let scale: CGFloat = 2
        guard let image = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(bounds.width * scale),
            pixelsHigh: Int(bounds.height * scale),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw CaptureError.unavailable
        }
        image.size = bounds.size
        view.cacheDisplay(in: bounds, to: image)
        guard let data = image.representation(
            using: .png,
            properties: [:]
        ) else {
            throw CaptureError.encodingFailed
        }
        try data.write(to: outputURL, options: .atomic)
    }

    static func report(_ error: Error) {
        let message = "SideRefresh fixture capture failed: \(error)\n"
        FileHandle.standardError.write(Data(message.utf8))
    }

    enum CaptureError: Error {
        case unavailable
        case encodingFailed
        case missingIcon
        case invalidIcon
    }
}
#endif
