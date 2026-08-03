import AppKit
import Combine
import SideRefreshAppPresentation
import SideRefreshCore
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class RenewalLogWindowPresenter:
    NSObject,
    NSWindowDelegate
{
    static let shared = RenewalLogWindowPresenter()
    private static let frameAutosaveName =
        "SideRefreshRenewalLogWindowFrame"

    private var window: NSWindow?
    private var onClose: (() -> Void)?

    func show(
        model: SideRefreshViewModel,
        onClose: (() -> Void)? = nil
    ) {
        if let onClose {
            self.onClose = onClose
        }
        let logWindow: NSWindow
        if let window {
            logWindow = window
        } else {
            let controller = NSHostingController(
                rootView: SideRefreshLocalizedRoot {
                    RenewalLogView(model: model)
                }
            )
            let createdWindow = NSWindow(
                contentRect: NSRect(
                    x: 0,
                    y: 0,
                    width: 1_040,
                    height: 680
                ),
                styleMask: [
                    .titled,
                    .closable,
                    .miniaturizable,
                    .resizable,
                ],
                backing: .buffered,
                defer: false
            )
            createdWindow.title = SideRefreshLocalization.string(
                "SideRefresh 상세 로그"
            )
            createdWindow.identifier = NSUserInterfaceItemIdentifier(
                "SideRefreshRenewalLog"
            )
            createdWindow.contentViewController = controller
            createdWindow.contentMinSize = NSSize(
                width: 860,
                height: 520
            )
            createdWindow.isReleasedWhenClosed = false
            createdWindow.tabbingMode = .disallowed
            createdWindow.collectionBehavior.insert(
                .moveToActiveSpace
            )
            createdWindow.delegate = self
            let restoredFrame = createdWindow.setFrameUsingName(
                Self.frameAutosaveName
            )
            createdWindow.setFrameAutosaveName(
                Self.frameAutosaveName
            )
            if !restoredFrame {
                createdWindow.center()
            }
            window = createdWindow
            logWindow = createdWindow
        }

        AppWindowActivationCoordinator.shared.windowDidShow(
            logWindow
        )
        logWindow.collectionBehavior.insert(.moveToActiveSpace)
        logWindow.makeKeyAndOrderFront(nil)
        logWindow.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow,
              closingWindow == window
        else {
            return
        }
        window = nil
        let closeHandler = onClose
        onClose = nil
        AppWindowActivationCoordinator.shared.windowWillClose(
            closingWindow
        )
        closeHandler?()
    }
}

struct RenewalLogView: View {
    @ObservedObject var model: SideRefreshViewModel
    let isEmbedded: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var followsLatest = true
    @State private var wrapsLines = true
    @State private var findRequest = 0
    @State private var jumpToLatestRequest = 0
    @State private var showsExporter = false
    @State private var feedbackMessage: String?
    @State private var exportErrorMessage: String?

    init(
        model: SideRefreshViewModel,
        isEmbedded: Bool = false
    ) {
        self.model = model
        self.isEmbedded = isEmbedded
    }

    var body: some View {
        logLayout
        .frame(
            minWidth: isEmbedded ? 0 : 860,
            minHeight: isEmbedded ? 0 : 520
        )
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("simple.diagnostics")
        .fileExporter(
            isPresented: $showsExporter,
            document: RenewalLogFileDocument(
                text: model.renewalLogText
            ),
            contentType:
                RenewalLogFileDocument.logContentType,
            defaultFilename: exportFilename
        ) { result in
            switch result {
            case .success(let url):
                showFeedback(
                    "\(url.lastPathComponent) 파일로 저장했습니다."
                )
            case .failure(let error):
                exportErrorMessage = error.localizedDescription
            }
        }
        .alert(
            "로그를 저장하지 못했습니다",
            isPresented: Binding(
                get: { exportErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        exportErrorMessage = nil
                    }
                }
            )
        ) {
            Button("확인", role: .cancel) {
                exportErrorMessage = nil
            }
        } message: {
            Text(exportErrorMessage ?? "알 수 없는 오류")
        }
    }

    @ViewBuilder
    private var logLayout: some View {
        if isEmbedded {
            SimpleWorkspacePageShell(page: .diagnostics) {
                embeddedHeader
            } content: {
                logContent
            }
        } else {
            VStack(spacing: 0) {
                header
                Divider()
                logContent
            }
        }
    }

    private var logContent: some View {
        VStack(spacing: 0) {
            logWorkspace
            Divider()
            footer
        }
    }

    private var embeddedHeader: some View {
        SimpleWorkspacePageHeader(
            title: "진단 로그",
            subtitle: LocalizedStringKey(
                SideRefreshLocalization.string(
                    model.currentRenewalProgressMessage
                )
            )
        ) {
            headerStatus
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "terminal.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(
                    SideRefreshPalette.brandGradient,
                    in: RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("갱신 상세 로그")
                    .font(.title3.weight(.semibold))
                Text(model.currentRenewalProgressMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            headerStatus
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var headerStatus: some View {
        HStack(spacing: 8) {
            if model.isWorking {
                ProgressView()
                    .controlSize(.small)
                Text("실행 중")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SideRefreshPalette.cobalt)
            }

            Text(verbatim: localizedLineCount)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    Color.primary.opacity(0.055),
                    in: Capsule()
                )
        }
    }

    private var localizedLineCount: String {
        SideRefreshLocalization.format(
            "%ld줄",
            model.renewalLogLineCount
        )
    }

    private var logWorkspace: some View {
        HSplitView {
            if !model.orderedRenewalProgressEvents.isEmpty {
                progressSidebar
                    .frame(
                        minWidth: isEmbedded ? 170 : 210,
                        idealWidth: isEmbedded ? 200 : 245,
                        maxWidth: isEmbedded ? 250 : 310
                    )
            }

            VStack(spacing: 0) {
                toolbar
                Divider()
                ZStack {
                    RenewalLogTextView(
                        model: model,
                        followsLatest: $followsLatest,
                        wrapsLines: wrapsLines,
                        findRequest: findRequest,
                        jumpToLatestRequest:
                            jumpToLatestRequest
                    )

                    if model.renewalLogText.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "terminal")
                                .font(
                                    .system(
                                        size: 30,
                                        weight: .medium
                                    )
                                )
                                .foregroundStyle(.secondary)
                            Text("표시할 실행 로그가 없습니다")
                                .font(.headline)
                            Text(
                                "‘지금 갱신’을 실행하면 단계별 원문 출력이 여기에 표시됩니다."
                            )
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        }
                        .multilineTextAlignment(.center)
                        .padding()
                    }
                }
            }
            .frame(minWidth: isEmbedded ? 400 : 540)
        }
    }

    private var progressSidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("진행 단계", systemImage: "list.bullet")
                .font(.callout.weight(.semibold))

            ScrollView {
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(
                        model.orderedRenewalProgressEvents,
                        id: \.phase
                    ) { event in
                        HStack(alignment: .top, spacing: 8) {
                            Image(
                                systemName:
                                    progressSystemImage(event.state)
                            )
                            .foregroundStyle(
                                progressColor(event.state)
                            )
                            .frame(width: 16)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.message)
                                    .font(.caption.weight(.medium))
                                    .fixedSize(
                                        horizontal: false,
                                        vertical: true
                                    )
                                Text(
                                    progressStateTitle(event.state)
                                )
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
            }
        }
        .padding(14)
        .background(
            Color.primary.opacity(
                colorScheme == .dark ? 0.055 : 0.025
            )
        )
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            Button {
                followsLatest = false
                findRequest &+= 1
            } label: {
                Label("찾기", systemImage: "magnifyingglass")
            }
            .keyboardShortcut("f", modifiers: .command)
            .help("로그에서 찾기 (⌘F)")

            Toggle(
                "실시간 따라가기",
                isOn: $followsLatest
            )
            .toggleStyle(.checkbox)
            .help("새 출력이 들어올 때 마지막 줄로 이동")

            Button {
                followsLatest = true
                jumpToLatestRequest &+= 1
            } label: {
                Label(
                    "최신으로",
                    systemImage: "arrow.down.to.line"
                )
            }
            .help("마지막 로그로 이동하고 실시간 따라가기")

            Toggle("줄 바꿈", isOn: $wrapsLines)
                .toggleStyle(.checkbox)
                .help("긴 빌드 경로와 명령을 창 너비에 맞춰 표시")

            Spacer(minLength: 8)

            Button {
                model.copyRenewalLog()
                showFeedback(
                    "전체 로그를 클립보드에 복사했습니다."
                )
            } label: {
                Label("전체 복사", systemImage: "doc.on.doc")
            }
            .disabled(model.renewalLogText.isEmpty)
            .help("선택 영역이 아닌 전체 로그 복사")

            Button {
                showsExporter = true
            } label: {
                Label(
                    "내보내기…",
                    systemImage: "square.and.arrow.up"
                )
            }
            .disabled(model.renewalLogText.isEmpty)
            .help("현재 로그를 .log 파일로 저장")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            if let feedbackMessage {
                Label(
                    feedbackMessage,
                    systemImage: "checkmark.circle.fill"
                )
                .foregroundStyle(
                    SideRefreshPalette.success(for: colorScheme)
                )
            } else {
                Text(
                    "텍스트를 선택해 ⌘C로 복사할 수 있습니다. ⌘F는 macOS 찾기 막대를 엽니다."
                )
                .foregroundStyle(.secondary)
            }

            Spacer()

            if model.renewalLogText.hasPrefix(
                "[이전 로그 일부 생략]"
            ) {
                Label(
                    "30만 자 이전 출력 일부 생략",
                    systemImage: "exclamationmark.triangle"
                )
                .foregroundStyle(
                    SideRefreshPalette.warning(for: colorScheme)
                )
            }
        }
        .font(.caption)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var exportFilename: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return "SideRefresh-\(formatter.string(from: Date())).log"
    }

    private func showFeedback(_ message: String) {
        feedbackMessage = message
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if feedbackMessage == message {
                feedbackMessage = nil
            }
        }
    }

    private func progressSystemImage(
        _ state: RenewalProgressState
    ) -> String {
        switch state {
        case .started:
            return "circle.dotted"
        case .succeeded:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }

    private func progressStateTitle(
        _ state: RenewalProgressState
    ) -> String {
        switch state {
        case .started:
            return "진행 중"
        case .succeeded:
            return "완료"
        case .failed:
            return "실패"
        }
    }

    private func progressColor(
        _ state: RenewalProgressState
    ) -> Color {
        switch state {
        case .started:
            return SideRefreshPalette.cobalt
        case .succeeded:
            return SideRefreshPalette.success(for: colorScheme)
        case .failed:
            return .red
        }
    }
}

@MainActor
private struct RenewalLogTextView: NSViewRepresentable {
    let model: SideRefreshViewModel
    @Binding var followsLatest: Bool
    let wrapsLines: Bool
    let findRequest: Int
    let jumpToLatestRequest: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = ReadOnlyLogScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .textBackgroundColor
        scrollView.onUserScroll = {
            context.coordinator.stopFollowingLatest()
        }

        let textView = ReadOnlyLogTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.drawsBackground = false
        textView.font = NSFont.monospacedSystemFont(
            ofSize: 13,
            weight: .regular
        )
        textView.textColor = .labelColor
        textView.textContainerInset = NSSize(
            width: 12,
            height: 10
        )
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.setAccessibilityLabel("갱신 상세 로그")
        textView.onFindAction = {
            context.coordinator.stopFollowingLatest()
        }
        textView.frame = NSRect(
            origin: .zero,
            size: scrollView.contentSize
        )

        scrollView.documentView = textView
        context.coordinator.attach(
            scrollView: scrollView,
            textView: textView
        )
        context.coordinator.update(
            wrapsLines: wrapsLines,
            followsLatest: followsLatest,
            findRequest: findRequest,
            jumpToLatestRequest: jumpToLatestRequest
        )
        return scrollView
    }

    func updateNSView(
        _ scrollView: NSScrollView,
        context: Context
    ) {
        context.coordinator.parent = self
        context.coordinator.update(
            wrapsLines: wrapsLines,
            followsLatest: followsLatest,
            findRequest: findRequest,
            jumpToLatestRequest: jumpToLatestRequest
        )
    }

    @MainActor
    final class Coordinator: NSObject {
        var parent: RenewalLogTextView
        private weak var scrollView: NSScrollView?
        private weak var textView: ReadOnlyLogTextView?
        private var lastWrapsLines: Bool?
        private var lastFollowsLatest = false
        private var lastFindRequest = 0
        private var lastJumpToLatestRequest = 0
        private var mutationSubscription: AnyCancellable?

        init(parent: RenewalLogTextView) {
            self.parent = parent
            super.init()
            mutationSubscription =
                parent.model.renewalLogMutations.sink {
                    [weak self] mutation in
                    self?.receive(mutation)
                }
        }

        func attach(
            scrollView: NSScrollView,
            textView: ReadOnlyLogTextView
        ) {
            self.scrollView = scrollView
            self.textView = textView
            replaceText(
                parent.model.renewalLogText,
                in: textView
            )
        }

        func update(
            wrapsLines: Bool,
            followsLatest: Bool,
            findRequest: Int,
            jumpToLatestRequest: Int
        ) {
            guard let scrollView,
                  let textView
            else {
                return
            }

            if lastWrapsLines != wrapsLines {
                configureLineWrapping(
                    wrapsLines,
                    scrollView: scrollView,
                    textView: textView
                )
                lastWrapsLines = wrapsLines
            }

            let followWasEnabled =
                followsLatest && !lastFollowsLatest
            if followWasEnabled {
                scrollToLatest(in: textView)
            }
            lastFollowsLatest = followsLatest

            if jumpToLatestRequest
                != lastJumpToLatestRequest
            {
                scrollToLatest(in: textView)
                lastJumpToLatestRequest =
                    jumpToLatestRequest
            }

            if findRequest != lastFindRequest {
                showFindBar(in: textView)
                lastFindRequest = findRequest
            }
        }

        func stopFollowingLatest() {
            guard parent.followsLatest else {
                return
            }
            parent.followsLatest = false
        }

        private func receive(_ mutation: RenewalLogMutation) {
            guard let textView else {
                return
            }
            switch mutation {
            case .append(let text):
                appendText(text, in: textView)
            case .reset(let text):
                replaceText(text, in: textView)
            }
            if parent.followsLatest {
                scrollToLatest(in: textView)
            }
        }

        private func appendText(
            _ text: String,
            in textView: NSTextView
        ) {
            guard !text.isEmpty else {
                return
            }
            textView.textStorage?.append(
                NSAttributedString(
                    string: text,
                    attributes: logTextAttributes
                )
            )
        }

        private func replaceText(
            _ text: String,
            in textView: NSTextView
        ) {
            textView.textStorage?.setAttributedString(
                NSAttributedString(
                    string: text,
                    attributes: logTextAttributes
                )
            )
        }

        private var logTextAttributes:
            [NSAttributedString.Key: Any]
        {
            let attributes: [NSAttributedString.Key: Any] = [
                .font:
                    NSFont.monospacedSystemFont(
                        ofSize: 13,
                        weight: .regular
                    ),
                .foregroundColor: NSColor.labelColor,
            ]
            return attributes
        }

        private func configureLineWrapping(
            _ wrapsLines: Bool,
            scrollView: NSScrollView,
            textView: NSTextView
        ) {
            scrollView.hasHorizontalScroller = !wrapsLines
            textView.isHorizontallyResizable = !wrapsLines
            textView.isVerticallyResizable = true
            textView.autoresizingMask =
                wrapsLines ? [.width] : []
            textView.textContainer?.widthTracksTextView =
                wrapsLines
            textView.textContainer?.size = NSSize(
                width:
                    wrapsLines
                    ? scrollView.contentSize.width
                    : .greatestFiniteMagnitude,
                height: .greatestFiniteMagnitude
            )
            textView.minSize = NSSize(
                width: 0,
                height: scrollView.contentSize.height
            )
            textView.maxSize = NSSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
            if wrapsLines {
                textView.setFrameSize(
                    NSSize(
                        width: scrollView.contentSize.width,
                        height: max(
                            textView.frame.height,
                            scrollView.contentSize.height
                        )
                    )
                )
                scrollView.contentView.scroll(to: .zero)
                scrollView.reflectScrolledClipView(
                    scrollView.contentView
                )
            }
        }

        private func scrollToLatest(in textView: NSTextView) {
            let end = NSRange(
                location: (textView.string as NSString).length,
                length: 0
            )
            textView.scrollRangeToVisible(end)
        }

        private func showFindBar(in textView: NSTextView) {
            textView.window?.makeFirstResponder(textView)
            let menuItem = NSMenuItem()
            menuItem.tag =
                NSTextFinder.Action.showFindInterface.rawValue
            textView.performTextFinderAction(menuItem)
        }
    }
}

private final class ReadOnlyLogScrollView: NSScrollView {
    var onUserScroll: (() -> Void)?

    override func scrollWheel(with event: NSEvent) {
        onUserScroll?()
        super.scrollWheel(with: event)
    }
}

private final class ReadOnlyLogTextView: NSTextView {
    var onFindAction: (() -> Void)?

    override func performTextFinderAction(_ sender: Any?) {
        onFindAction?()
        super.performTextFinderAction(sender)
    }
}

private struct RenewalLogFileDocument: FileDocument {
    static let logContentType =
        UTType(
            filenameExtension: "log",
            conformingTo: .plainText
        ) ?? .plainText

    static var readableContentTypes: [UTType] {
        [logContentType, .plainText]
    }

    let text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data =
            configuration.file.regularFileContents
        else {
            text = ""
            return
        }
        text = String(data: data, encoding: .utf8) ?? ""
    }

    func fileWrapper(
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        FileWrapper(
            regularFileWithContents: Data(text.utf8)
        )
    }
}
