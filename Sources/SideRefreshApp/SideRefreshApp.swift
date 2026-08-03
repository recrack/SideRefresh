import AppKit
import Combine
import Darwin
import ImageIO
import SwiftUI
import SideRefreshCore
import SideRefreshAppPresentation

enum SideRefreshPalette {
    static let ink = Color(
        red: 0.025,
        green: 0.055,
        blue: 0.18
    )
    static let navy = Color(
        red: 0.045,
        green: 0.11,
        blue: 0.34
    )
    static let cobalt = Color(
        red: 0.12,
        green: 0.40,
        blue: 0.98
    )
    static let cyan = Color(
        red: 0.20,
        green: 0.78,
        blue: 1.0
    )
    static let mint = Color(
        red: 0.30,
        green: 0.93,
        blue: 0.78
    )
    static let amber = Color(
        red: 0.96,
        green: 0.57,
        blue: 0.16
    )

    static let brandGradient = LinearGradient(
        colors: [navy, cobalt],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func success(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? mint
            : Color(red: 0.025, green: 0.46, blue: 0.37)
    }

    static func warning(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? amber
            : Color(red: 0.76, green: 0.31, blue: 0.025)
    }
}

private struct SideRefreshPrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .foregroundStyle(
                isEnabled
                    ? Color.white
                    : Color.primary.opacity(
                        colorScheme == .dark ? 0.76 : 0.66
                    )
            )
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(
                    cornerRadius: 8,
                    style: .continuous
                )
                .fill(
                    isEnabled
                        ? AnyShapeStyle(SideRefreshPalette.brandGradient)
                        : AnyShapeStyle(
                            Color.primary.opacity(
                                colorScheme == .dark ? 0.13 : 0.075
                            )
                        )
                )
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: 8,
                    style: .continuous
                )
                .strokeBorder(
                    isEnabled
                        ? SideRefreshPalette.cyan.opacity(0.32)
                        : Color.primary.opacity(0.12)
                )
            }
            .shadow(
                color: isEnabled
                    ? SideRefreshPalette.cobalt.opacity(0.22)
                    : .clear,
                radius: 8,
                y: 3
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(
                .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}

private struct SideRefreshSecondaryButtonStyle: ButtonStyle {
    enum Tone {
        case brand
        case neutral
    }

    @Environment(\.colorScheme) private var colorScheme
    let tone: Tone

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.medium))
            .foregroundStyle(foregroundColor)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background {
                RoundedRectangle(
                    cornerRadius: 8,
                    style: .continuous
                )
                .fill(backgroundColor)
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: 8,
                    style: .continuous
                )
                .strokeBorder(borderColor)
            }
            .opacity(configuration.isPressed ? 0.78 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(
                .easeOut(duration: 0.1),
                value: configuration.isPressed
            )
    }

    private var foregroundColor: Color {
        switch tone {
        case .brand:
            return colorScheme == .dark
                ? SideRefreshPalette.cyan
                : SideRefreshPalette.cobalt
        case .neutral:
            return Color.primary.opacity(
                colorScheme == .dark ? 0.88 : 0.80
            )
        }
    }

    private var backgroundColor: Color {
        switch tone {
        case .brand:
            return SideRefreshPalette.cobalt.opacity(
                colorScheme == .dark ? 0.18 : 0.09
            )
        case .neutral:
            return Color.primary.opacity(
                colorScheme == .dark ? 0.11 : 0.055
            )
        }
    }

    private var borderColor: Color {
        switch tone {
        case .brand:
            return SideRefreshPalette.cobalt.opacity(
                colorScheme == .dark ? 0.52 : 0.30
            )
        case .neutral:
            return Color.primary.opacity(
                colorScheme == .dark ? 0.22 : 0.13
            )
        }
    }
}

@main
@MainActor
struct SideRefreshApp: App {
    @NSApplicationDelegateAdaptor(SideRefreshApplicationDelegate.self)
    private var applicationDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) {}
        }
    }
}

@MainActor
private final class SideRefreshApplicationDelegate:
    NSObject,
    NSApplicationDelegate
{
    private lazy var model = SideRefreshViewModel()
    private let popover = NSPopover()
    private var menuHeightSubscription: AnyCancellable?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {
        SideRefreshApplicationArtwork.prepare()
        #if DEBUG
        switch SimpleWorkspaceFixtureLaunch.request {
        case let .fixture(fixture):
            guard SimpleWorkspaceFixtureCapture.prepareIfRequested() else {
                exit(EX_DATAERR)
            }
            SimpleWorkspaceWindowPresenter.shared.show(fixture: fixture)
            return
        case let .invalid(value):
            let message = "Invalid SideRefresh fixture: \(value)\n"
            FileHandle.standardError.write(Data(message.utf8))
            exit(EX_USAGE)
        case .normal:
            break
        }
        #endif
        preparePopover()
        observeMenuHeightChanges()
        installStatusItem()
        prewarmPopoverWindow()
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            WorkspaceWindowRouter.show(
                WorkspaceLaunchPolicy.normalLaunchWorkspace,
                model: model
            )
        }
    }

    private func preparePopover() {
        let model = self.model
        let hostingController = NSHostingController(
            rootView: SideRefreshLocalizedRoot {
                SideRefreshMenu(model: model)
            }
        )
        hostingController.view.frame = NSRect(
            x: 0,
            y: 0,
            width: 320,
            height: 360
        )
        hostingController.view.layoutSubtreeIfNeeded()

        let fittingSize = hostingController.view.fittingSize
        popover.behavior = .transient
        popover.animates = false
        popover.contentViewController = hostingController
        popover.contentSize = NSSize(
            width: 320,
            height: fittingSize.height
        )
    }

    private func observeMenuHeightChanges() {
        menuHeightSubscription = Publishers.CombineLatest(
            model.$renewalRunPresentationState.map {
                $0 != .idle
            },
            model.$renewalLogText.map {
                !$0.isEmpty
            }
        )
        .map { $0 || $1 }
        .removeDuplicates()
        .dropFirst()
        .sink { [weak self] _ in
            Task { @MainActor [weak self] in
                await Task.yield()
                self?.updatePopoverSize()
            }
        }
    }

    private func updatePopoverSize() {
        guard let contentView = popover.contentViewController?.view else {
            return
        }
        contentView.layoutSubtreeIfNeeded()
        popover.contentSize = NSSize(
            width: 320,
            height: contentView.fittingSize.height
        )
    }

    private func prewarmPopoverWindow() {
        guard let button = statusItem?.button else {
            return
        }
        popover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
        popover.performClose(nil)
    }

    private func installStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )
        guard let button = statusItem.button else {
            NSStatusBar.system.removeStatusItem(statusItem)
            return
        }
        button.image = SideRefreshMenuBarArtwork.image
        button.imagePosition = .imageOnly
        button.target = self
        button.action = #selector(togglePopover(_:))
        button.setAccessibilityLabel("SideRefresh")
        statusItem.autosaveName = "SideRefresh.MenuBarItem"
        self.statusItem = statusItem
    }

    @objc
    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
            return
        }
        model.refreshAgentStatus()
        popover.show(
            relativeTo: sender.bounds,
            of: sender,
            preferredEdge: .minY
        )
        popover.contentViewController?.view.window?.makeKey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }
}

@MainActor
private enum SideRefreshApplicationArtwork {
    static let image: NSImage = {
        let source = NSApplication.shared.applicationIconImage
        let renderedSize = NSSize(width: 68, height: 68)
        let image = NSImage(size: renderedSize)
        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        source?.draw(
            in: NSRect(origin: .zero, size: renderedSize),
            from: .zero,
            operation: .copy,
            fraction: 1
        )
        image.unlockFocus()
        image.size = NSSize(width: 34, height: 34)
        return image
    }()

    static func prepare() {
        _ = image
    }
}

@MainActor
private enum SideRefreshMenuBarArtwork {
    static let image: NSImage = {
        let image = Bundle.main.url(
            forResource: "SideRefresh-MenuBar",
            withExtension: "svg"
        ).flatMap(NSImage.init(contentsOf:))
            ?? NSImage(
                systemSymbolName: "arrow.triangle.2.circlepath",
                accessibilityDescription: "SideRefresh"
            )
            ?? NSImage(size: NSSize(width: 18, height: 18))
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        return image
    }()
}

struct SideRefreshMenu: View {
    @ObservedObject var model: SideRefreshViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var confirmsRunNow = false
    @State private var confirmsSave = false
    @State private var confirmsRegistration = false

    var body: some View {
        let presentation = model.renewalPresentation
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 11) {
                SideRefreshMark(size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(
                        presentation.relationship?.appName
                            ?? model.targetDisplayName
                    )
                        .font(.headline)
                        .lineLimit(1)
                    Text(presentation.condition.sideRefreshTitle)
                        .font(.caption)
                        .foregroundStyle(
                            presentation.condition == .healthy
                                ? SideRefreshPalette.success(
                                    for: colorScheme
                                )
                                : .secondary
                        )
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 7) {
                MenuStatusRow(
                    title: "갱신 상태",
                    value: presentation.sideRefreshScheduleSummary,
                    systemImage: "calendar.badge.clock"
                )
                MenuStatusRow(
                    title: "자동 갱신",
                    value: model.agentSummary,
                    systemImage: "bolt.horizontal.circle"
                )
            }

            Divider()

            HStack(spacing: 8) {
                Button {
                    model.testCurrentSetup()
                } label: {
                    Label("설정 테스트", systemImage: "checkmark.shield")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(
                    SideRefreshSecondaryButtonStyle(tone: .brand)
                )
                .disabled(!model.canTestCurrentSetup)
                .help("빌드·서명·iPhone 설치 없이 현재 설정 형식만 확인")

                if let action = presentation.nextAction {
                    Button {
                        performMenuAction(presentation)
                    } label: {
                        Label(
                            model.isWorking
                                ? "갱신 중…"
                                : action.sideRefreshTitle,
                            systemImage: "arrow.clockwise"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SideRefreshPrimaryButtonStyle())
                    .disabled(
                        action == .renewNow
                            ? !model.canRenewImmediately
                            : model.isWorking
                                || AppPresentationCoordinator.route(
                                    for: presentation
                                ) == nil
                    )
                } else {
                    Button {
                        confirmsRunNow = true
                    } label: {
                        Label(
                            model.isWorking ? "갱신 중…" : "지금 갱신",
                            systemImage: "arrow.clockwise"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(
                        SideRefreshSecondaryButtonStyle(tone: .brand)
                    )
                    .disabled(!model.canRenewImmediately)
                }
            }
            .controlSize(.large)

            if model.hasRenewalRunDetails {
                Button {
                    RenewalLogWindowPresenter.shared.show(
                        model: model
                    )
                } label: {
                    Label(
                        "상세 로그 열기",
                        systemImage: "terminal"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(
                    SideRefreshSecondaryButtonStyle(tone: .neutral)
                )
            }

            HStack(spacing: 8) {
                Button {
                    WorkspaceWindowRouter.show(
                        WorkspaceLaunchPolicy.menuBarWorkspace,
                        model: model
                    )
                } label: {
                    Label("SideRefresh 열기", systemImage: "macwindow")
                }
                .buttonStyle(
                    SideRefreshSecondaryButtonStyle(tone: .brand)
                )

                Button {
                    NSApp.terminate(nil)
                } label: {
                    Label("종료", systemImage: "power")
                }
                .buttonStyle(
                    SideRefreshSecondaryButtonStyle(tone: .neutral)
                )
            }
        }
        .padding(16)
        .frame(width: 320)
        .tint(SideRefreshPalette.cobalt)
        .alert(
            model.immediateRenewalConfirmationTitle,
            isPresented: $confirmsRunNow
        ) {
            Button("취소", role: .cancel) {}
            Button("빌드 및 설치") {
                model.renewImmediately()
            }
        } message: {
            Text(model.immediateRenewalConfirmationMessage)
        }
        .alert(
            "변경사항을 저장할까요?",
            isPresented: $confirmsSave
        ) {
            Button("취소", role: .cancel) {}
            Button("저장") {
                model.saveConfiguration(
                    allowingActiveAgentExecution: true
                )
            }
        } message: {
            Text(model.activeConfigurationSaveMessage)
        }
        .alert(
            "자동 갱신을 켤까요?",
            isPresented: $confirmsRegistration
        ) {
            Button("취소", role: .cancel) {}
            Button("자동 갱신 켜기") {
                model.registerAgent()
            }
        } message: {
            Text(model.registrationConfirmationMessage)
        }
    }

    private func performMenuAction(
        _ presentation: RenewalPresentation
    ) {
        guard let route = AppPresentationCoordinator.route(
            for: presentation
        ) else {
            return
        }
        SideRefreshAppRouteExecutor.perform(
            route,
            model: model,
            handlers: SideRefreshAppRouteHandlers(
                confirmSave: { confirmsSave = true },
                confirmAutomaticRenewal: {
                    confirmsRegistration = true
                },
                confirmInstall: { confirmsRunNow = true },
                openDestination: openMenuDestination
            )
        )
    }

    private func openMenuDestination(
        _ destination: RenewalDestination
    ) {
        switch SimpleSettingsDestinationPolicy.surface(
            for: destination
        ) {
        case .diagnostics:
            RenewalLogWindowPresenter.shared.show(model: model)
        case .simpleSettings:
            SimpleSettingsWindowPresenter.shared.show(
                model: model,
                launchAction:
                    destination == .setup
                    ? .setupAction(for: model)
                    : .none
            )
        case .legacySettings:
            SettingsWindowPresenter.shared.show(
                model: model,
                destination: destination
            )
        }
    }
}

@MainActor
final class SettingsWindowPresenter:
    NSObject,
    NSWindowDelegate
{
    static let shared = SettingsWindowPresenter()
    private static let frameAutosaveName =
        "SideRefreshSettingsWindowFrame"

    private var window: NSWindow?
    private var onClose: (() -> Void)?

    func show(
        model: SideRefreshViewModel,
        destination: RenewalDestination? = nil,
        onClose: (() -> Void)? = nil
    ) {
        if let onClose {
            self.onClose = onClose
        }
        if let destination {
            prepare(destination, model: model)
        }
        let settingsWindow: NSWindow
        if let window {
            settingsWindow = window
        } else {
            let controller = NSHostingController(
                rootView: SideRefreshLocalizedRoot {
                    SideRefreshSettings(model: model)
                }
            )
            let createdWindow = NSWindow(
                contentRect: NSRect(
                    x: 0,
                    y: 0,
                    width: 980,
                    height: 760
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
            createdWindow.title = "SideRefresh"
            createdWindow.identifier = NSUserInterfaceItemIdentifier(
                "SideRefreshSettings"
            )
            createdWindow.contentViewController = controller
            createdWindow.contentMinSize = NSSize(
                width: 820,
                height: 620
            )
            createdWindow.isReleasedWhenClosed = false
            createdWindow.tabbingMode = .disallowed
            createdWindow.collectionBehavior.insert(.moveToActiveSpace)
            createdWindow.delegate = self
            let restoredFrame = createdWindow.setFrameUsingName(
                Self.frameAutosaveName
            )
            createdWindow.setFrameAutosaveName(Self.frameAutosaveName)
            if !restoredFrame {
                createdWindow.center()
            }
            window = createdWindow
            settingsWindow = createdWindow
        }

        AppWindowActivationCoordinator.shared.windowDidShow(
            settingsWindow
        )
        settingsWindow.collectionBehavior.insert(.moveToActiveSpace)
        settingsWindow.makeKeyAndOrderFront(nil)
        settingsWindow.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.async {
            settingsWindow.makeKeyAndOrderFront(nil)
        }
    }

    private func prepare(
        _ destination: RenewalDestination,
        model: SideRefreshViewModel
    ) {
        let section: SideRefreshWorkspaceSection
        switch destination {
        case .setup:
            switch model.missingTargetRequiredField?.setupArea {
            case .app:
                section = .app
            case .iphone:
                section = .iphone
            case .automation, nil:
                section = .automation
            }
        case .advancedSettings:
            section = .automation
        case .settings, .diagnostics, .help:
            section = .overview
        }
        UserDefaults.standard.set(
            section.rawValue,
            forKey: "side-refresh.selectedWorkspaceSection"
        )
    }

    func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow,
              closingWindow === window
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

private struct MenuStatusRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(SideRefreshLocalization.string(title))
                .foregroundStyle(.secondary)
            Spacer()
            Text(SideRefreshLocalization.string(value))
                .lineLimit(1)
        }
        .font(.caption)
    }
}

private enum SideRefreshWorkspaceSection:
    String,
    CaseIterable,
    Identifiable
{
    case overview
    case app
    case iphone
    case automation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview:
            return "갱신 현황"
        case .app:
            return "갱신할 앱"
        case .iphone:
            return "iPhone"
        case .automation:
            return "자동 갱신"
        }
    }

    var subtitle: String {
        switch self {
        case .overview:
            return "갱신 대상, 자동 실행 상태, 다음 갱신 시각을 확인합니다."
        case .app:
            return "Mac에서 빌드해 계속 사용할 iOS 앱을 선택합니다."
        case .iphone:
            return "선택한 앱을 다시 설치할 iPhone과 연결 방법을 관리합니다."
        case .automation:
            return "갱신 주기와 Mac의 백그라운드 실행을 관리합니다."
        }
    }

    var systemImage: String {
        switch self {
        case .overview:
            return "clock.arrow.circlepath"
        case .app:
            return "app.badge.checkmark"
        case .iphone:
            return "iphone.gen3"
        case .automation:
            return "bolt.horizontal.circle"
        }
    }
}

private struct WorkspaceStatusRow: View {
    let title: String
    let value: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(SideRefreshPalette.cobalt)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.medium))
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Button("열기", action: action)
                .buttonStyle(.borderless)
                .accessibilityLabel("\(title) 열기")
        }
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }
}

private struct DeploymentEndpointCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let step: String
    let title: String
    let detail: String
    let systemImage: String
    let isComplete: Bool
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(step)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(
                        systemName: isComplete
                            ? "checkmark.circle.fill"
                            : "circle.dotted"
                    )
                    .foregroundStyle(
                        isComplete
                            ? SideRefreshPalette.success(for: colorScheme)
                            : SideRefreshPalette.cobalt
                    )
                }

                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(SideRefreshPalette.cobalt)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Label(actionTitle, systemImage: "chevron.right")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SideRefreshPalette.cobalt)
            }
            .frame(maxWidth: .infinity, minHeight: 146, alignment: .leading)
            .padding(14)
            .background(
                Color.primary.opacity(
                    colorScheme == .dark ? 0.075 : 0.035
                ),
                in: RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isComplete
                            ? SideRefreshPalette.success(
                                for: colorScheme
                            ).opacity(0.24)
                            : SideRefreshPalette.cobalt.opacity(0.18)
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(step), \(title), \(detail), \(actionTitle)")
    }
}

struct SideRefreshSettings: View {
    @ObservedObject var model: SideRefreshViewModel
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("side-refresh.selectedWorkspaceSection")
    private var selectedSectionRawValue =
        SideRefreshWorkspaceSection.overview.rawValue
    @State private var confirmsRegistration = false
    @State private var confirmsUnregistration = false
    @State private var confirmsSavingActiveAgent = false
    @State private var confirmsRunNow = false
    @State private var showsProjectPicker = false
    @State private var showsPersonalTeamGuide = false
    @State private var showsBuildDetails = false
    @State private var showsManualUDID = false

    var body: some View {
        NavigationSplitView {
            List(
                SideRefreshWorkspaceSection.allCases,
                selection: selectedSection
            ) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(
                min: 190,
                ideal: 210,
                max: 250
            )
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    workspaceHeader
                    workspaceContent
                    footer
                }
                .padding(24)
                .frame(maxWidth: 820)
                .frame(maxWidth: .infinity)
            }
            .background(workspaceBackground)
        }
        .navigationSplitViewStyle(.balanced)
        .tint(SideRefreshPalette.cobalt)
        .frame(
            minWidth: 820,
            idealWidth: 980,
            minHeight: 620,
            idealHeight: 760
        )
        .sheet(isPresented: $showsProjectPicker) {
            ProjectPickerView(model: model)
        }
        .sheet(isPresented: $showsPersonalTeamGuide) {
            PersonalTeamSetupGuideSheet(model: model)
        }
        .alert(
            "자동 갱신을 켤까요?",
            isPresented: $confirmsRegistration
        ) {
            Button("취소", role: .cancel) {}
            Button("자동 갱신 켜기") {
                model.registerAgent()
            }
        } message: {
            Text(model.registrationConfirmationMessage)
        }
        .alert(
            "자동 갱신을 끌까요?",
            isPresented: $confirmsUnregistration
        ) {
            Button("취소", role: .cancel) {}
            Button("자동 갱신 끄기") {
                model.unregisterAgent()
            }
        } message: {
            Text(
                "백그라운드 확인만 중지합니다. 저장한 앱 설정과 마지막 갱신 기록은 그대로 남습니다."
            )
        }
        .alert(
            "실행 중인 자동 갱신 설정을 바꿀까요?",
            isPresented: $confirmsSavingActiveAgent
        ) {
            Button("취소", role: .cancel) {}
            Button("저장") {
                model.saveConfiguration(
                    allowingActiveAgentExecution: true
                )
            }
        } message: {
            Text(model.activeConfigurationSaveMessage)
        }
        .alert(
            model.immediateRenewalConfirmationTitle,
            isPresented: $confirmsRunNow
        ) {
            Button("취소", role: .cancel) {}
            Button("빌드 및 설치") {
                model.renewImmediately()
            }
        } message: {
            Text(model.immediateRenewalConfirmationMessage)
        }
        .alert(
            "오류",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.dismissError() } }
            )
        ) {
            Button("확인", role: .cancel) {
                model.dismissError()
            }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var selectedSection: Binding<SideRefreshWorkspaceSection> {
        Binding(
            get: {
                SideRefreshWorkspaceSection(
                    rawValue: selectedSectionRawValue
                ) ?? .overview
            },
            set: { selectedSectionRawValue = $0.rawValue }
        )
    }

    private var activeSection: SideRefreshWorkspaceSection {
        SideRefreshWorkspaceSection(
            rawValue: selectedSectionRawValue
        ) ?? .overview
    }

    @ViewBuilder
    private var workspaceContent: some View {
        switch activeSection {
        case .overview:
            overviewStatusCard
            readinessCard
            if model.hasRenewalRunDetails {
                renewalRunProgressCard
            }
            renewalEvidenceCard
        case .app:
            if model.hasGuidedTarget {
                targetCard
            } else {
                guidedTargetMigrationCard
            }
        case .iphone:
            if model.hasGuidedTarget {
                iphoneCard
                connectionCard
            } else {
                guidedTargetMigrationCard
            }
        case .automation:
            if model.hasGuidedTarget {
                automationCard
                renewalCard
            } else {
                legacyConfigurationSummaryCard
                automationCard
                guidedTargetMigrationCard
            }
        }
    }

    @ViewBuilder
    private var workspaceHeader: some View {
        if activeSection == .overview {
            settingsHeader
        } else {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: activeSection.systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        SideRefreshPalette.brandGradient,
                        in: RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                    )
                    .shadow(
                        color: SideRefreshPalette.cobalt.opacity(0.22),
                        radius: 9,
                        y: 4
                    )
                VStack(alignment: .leading, spacing: 3) {
                    Text(activeSection.title)
                        .font(.system(size: 24, weight: .semibold))
                    Text(activeSection.subtitle)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                workspaceActions
            }
        }
    }

    private var settingsHeader: some View {
        HStack(spacing: 14) {
            SideRefreshMark(size: 48)
            VStack(alignment: .leading, spacing: 3) {
                Text("SideRefresh")
                    .font(.system(size: 24, weight: .semibold))
                Text("개인용 iOS 앱 자동 갱신 도구")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            workspaceActions
        }
    }

    private var workspaceActions: some View {
        HStack(spacing: 8) {
            if model.hasGuidedTarget {
                Button {
                    openProjectPicker()
                } label: {
                    Label("설치할 앱 선택", systemImage: "folder")
                }
                .keyboardShortcut("o", modifiers: .command)
                .help("Mac에서 빌드해 설치할 iOS 앱 선택 (⌘O)")
            }

            Button {
                model.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .keyboardShortcut("r", modifiers: .command)
            .help("상태 새로고침 (⌘R)")
            .accessibilityLabel("상태 새로고침")

            primaryWorkspaceAction
        }
        .controlSize(.regular)
    }

    @ViewBuilder
    private var primaryWorkspaceAction: some View {
        if let missingField = model.missingTargetRequiredField {
            Button(primarySetupActionTitle(for: missingField)) {
                continueSetup(for: missingField)
            }
            .buttonStyle(.borderedProminent)
            .disabled(primarySetupActionIsDisabled(for: missingField))
        } else {
            Button("설정 저장") {
                requestSave()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut("s", modifiers: .command)
            .help("현재 앱과 자동 갱신 설정 저장 (⌘S)")
        }
    }

    private func primarySetupActionTitle(
        for field: RenewalTargetRequiredField
    ) -> String {
        switch field {
        case .container:
            return "갱신할 앱 선택"
        case .scheme,
             .productName,
             .bundleIdentifier,
             .developmentTeam:
            return "앱 정보 확인"
        case .deviceIdentifier:
            return activeSection == .iphone
                ? (
                    model.isDiscoveringCoreDevices
                        ? "iPhone 찾는 중…"
                        : "Xcode에서 iPhone 찾기"
                )
                : "다음: iPhone 선택"
        case .derivedData:
            return "다음: 자동 갱신"
        }
    }

    private func primarySetupActionIsDisabled(
        for field: RenewalTargetRequiredField
    ) -> Bool {
        guard activeSection == .iphone,
              model.isDiscoveringCoreDevices
        else {
            return false
        }
        if case .deviceIdentifier = field {
            return true
        }
        return false
    }

    private func continueSetup(
        for field: RenewalTargetRequiredField
    ) {
        switch field {
        case .container:
            openProjectPicker()
        case .scheme,
             .productName,
             .bundleIdentifier,
             .developmentTeam:
            select(.app)
            showsBuildDetails = true
        case .deviceIdentifier:
            if activeSection == .iphone {
                model.discoverCoreDevices()
            } else {
                select(.iphone)
            }
        case .derivedData:
            select(.automation)
        }
    }

    private var workspaceBackground: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            LinearGradient(
                colors: [
                    SideRefreshPalette.cobalt.opacity(
                        colorScheme == .dark ? 0.12 : 0.055
                    ),
                    .clear,
                    SideRefreshPalette.mint.opacity(
                        colorScheme == .dark ? 0.045 : 0.025
                    ),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var readinessCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        readinessAccent.opacity(0.18)
                    )
                Image(systemName: readinessSystemImage)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(readinessAccent)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(dashboardAutomationTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text(dashboardAutomationDetail)
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                if dashboardAutomationIsOperational,
                   let date =
                    model.renewalPresentation.nextRenewalDate
                {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("다음 갱신")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.58))
                        Text(
                            SideRefreshLocalization.date(
                                date,
                                dateStyle: .medium,
                                timeStyle: .short
                            )
                        )
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.white.opacity(0.94))
                    }
                }

                dashboardAutomationAction
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    SideRefreshPalette.ink,
                    SideRefreshPalette.navy,
                    SideRefreshPalette.cobalt.opacity(0.90),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(SideRefreshPalette.cyan.opacity(0.24))
        }
        .shadow(
            color: SideRefreshPalette.cobalt.opacity(
                colorScheme == .dark ? 0.16 : 0.20
            ),
            radius: 18,
            y: 8
        )
    }

    private var readinessAccent: Color {
        switch model.renewalPresentation.condition {
        case .healthy:
            return SideRefreshPalette.mint
        case .targetChangesUnsaved, .backgroundApprovalRequired,
             .expired, .connectionFailure, .buildOrSigningFailure,
             .installationFailure, .installationEvidenceMissing,
             .permissionRequired, .checkFailed:
            return SideRefreshPalette.amber
        default:
            return SideRefreshPalette.cyan
        }
    }

    private var readinessSystemImage: String {
        switch model.renewalPresentation.condition {
        case .targetChangesUnsaved:
            return "square.and.pencil"
        case .healthy:
            return "checkmark.seal.fill"
        case .running:
            return "arrow.triangle.2.circlepath"
        case .expired, .connectionFailure, .buildOrSigningFailure,
             .installationFailure, .installationEvidenceMissing,
             .permissionRequired, .checkFailed,
             .backgroundApprovalRequired:
            return "exclamationmark.triangle.fill"
        default:
            return "arrow.triangle.2.circlepath"
        }
    }

    private var dashboardAutomationIsOperational: Bool {
        model.renewalPresentation.condition == .healthy
    }

    private var warningTextColor: Color {
        SideRefreshPalette.warning(for: colorScheme)
    }

    private var dashboardAutomationTitle: String {
        model.renewalPresentation.condition.sideRefreshTitle
    }

    private var dashboardAutomationDetail: String {
        model.renewalPresentation.condition.sideRefreshDetail
    }

    @ViewBuilder
    private var dashboardAutomationAction: some View {
        if let action = model.renewalPresentation.nextAction {
            Button(action.sideRefreshTitle) {
                performDashboardAction(
                    model.renewalPresentation
                )
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.18))
            .foregroundStyle(.white)
            .disabled(
                AppPresentationCoordinator.route(
                    for: model.renewalPresentation
                ) == nil
            )
        } else {
            Button("자동 갱신 관리…") {
                select(.automation)
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .foregroundStyle(.white)
        }
    }

    private func performDashboardAction(
        _ presentation: RenewalPresentation
    ) {
        guard let route = AppPresentationCoordinator.route(
            for: presentation
        ) else {
            return
        }
        SideRefreshAppRouteExecutor.perform(
            route,
            model: model,
            handlers: SideRefreshAppRouteHandlers(
                confirmSave: requestSave,
                confirmAutomaticRenewal: {
                    confirmsRegistration = true
                },
                confirmInstall: { confirmsRunNow = true },
                openDestination: openDashboardDestination
            )
        )
    }

    private func openDashboardDestination(
        _ destination: RenewalDestination
    ) {
        switch destination {
        case .setup:
            openNextSetupStep()
        case .advancedSettings:
            select(.automation)
        case .diagnostics:
            RenewalLogWindowPresenter.shared.show(model: model)
        case .settings, .help:
            select(.overview)
        }
    }

    private var overviewStatusCard: some View {
        SettingsCard(
            title: "갱신 대상",
            subtitle: "Mac의 앱을 빌드·서명해 선택한 iPhone에 다시 설치합니다.",
            systemImage: "arrow.right"
        ) {
            HStack(alignment: .center, spacing: 14) {
                DeploymentEndpointCard(
                    step: "Mac의 앱",
                    title: sourceAppTitle,
                    detail: sourceAppDetail,
                    systemImage: "laptopcomputer",
                    isComplete: sourceAppIsSelected,
                    actionTitle: sourceAppActionTitle,
                    action: openSourceAppSetup
                )

                VStack(spacing: 5) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(SideRefreshPalette.cobalt)
                    Text("빌드 · 서명\n· 설치")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                DeploymentEndpointCard(
                    step: "설치할 iPhone",
                    title: destinationIPhoneTitle,
                    detail: destinationIPhoneDetail,
                    systemImage: "iphone.gen3",
                    isComplete: destinationIPhoneIsSelected,
                    actionTitle:
                        !model.hasGuidedTarget
                            ? "명령 확인"
                            : destinationIPhoneIsSelected
                            ? "다른 iPhone 선택"
                            : "iPhone 선택",
                    action: openDestinationSetup
                )
            }

            Label(
                deploymentPairSummary,
                systemImage:
                    sourceAppIsSelected && destinationIPhoneIsSelected
                        ? "checkmark.circle.fill"
                        : "info.circle"
            )
            .font(.callout.weight(.medium))
            .foregroundStyle(
                sourceAppIsSelected && destinationIPhoneIsSelected
                    ? SideRefreshPalette.success(for: colorScheme)
                    : .secondary
            )

            HStack {
                Button {
                    model.testCurrentSetup()
                } label: {
                    Label(
                        "설정 테스트",
                        systemImage: "checkmark.shield"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(!model.canTestCurrentSetup)
                .help("빌드·서명·iPhone 설치 없이 현재 설정 형식만 확인")

                Button {
                    confirmsRunNow = true
                } label: {
                    Label(
                        model.isWorking ? "갱신 중…" : "지금 갱신",
                        systemImage: "arrow.clockwise"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(!model.canRenewImmediately)

                if model.configurationIsDirty {
                    Text("저장하지 않은 변경사항")
                        .font(.caption)
                        .foregroundStyle(warningTextColor)
                }
            }

            if model.isDiscoveringPersonalTeam {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(
                        "이 Mac의 유효한 Personal Team을 확인하는 중입니다…"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } else if let missingField =
                model.missingTargetRequiredField
            {
                VStack(alignment: .leading, spacing: 8) {
                    Label(
                        missingField.guidance,
                        systemImage:
                            "exclamationmark.triangle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(warningTextColor)

                    if case .developmentTeam = missingField {
                        HStack(spacing: 8) {
                            Button("이 Mac에서 Team 찾기") {
                                select(.app)
                                model.rediscoverPersonalTeam()
                            }
                            .disabled(
                                model.isDiscoveringPersonalTeam
                            )

                            Button("Personal Team 준비 가이드") {
                                showsPersonalTeamGuide = true
                            }
                        }
                    }
                }
            }
        }
    }

    private var renewalEvidenceCard: some View {
        SettingsCard(
            title: "갱신 일정과 iPhone 설치 상태",
            subtitle: "내부 타이머와 실제 설치 확인을 구분해 보여줍니다.",
            systemImage: "calendar.badge.checkmark"
        ) {
            Grid(
                alignment: .leading,
                horizontalSpacing: 12,
                verticalSpacing: 12
            ) {
                GridRow {
                    renewalMetric(
                        title: "갱신 주기",
                        value: renewalIntervalText,
                        systemImage: "repeat"
                    )
                    renewalMetric(
                        title:
                            showsInstallationEvidence
                            ? "마지막 설치 성공"
                            : "마지막 명령 성공",
                        value: formattedStatusDate(
                            model.configurationIsDirty
                                ? nil
                                : model.lastSuccessfulRenewal,
                            empty:
                                model.configurationIsDirty
                                ? "변경 저장 후 확인"
                                : "기록 없음"
                        ),
                        systemImage: "checkmark.circle"
                    )
                }
                GridRow {
                    renewalMetric(
                        title:
                            dashboardAutomationIsOperational
                            ? "다음 자동 갱신"
                            : "다음 갱신 가능 시각",
                        value: formattedStatusDate(
                            model.configurationIsDirty
                                ? nil
                                : model.nextRenewalDate,
                            empty:
                                model.configurationIsDirty
                                ? "변경 저장 후 계산"
                                : dashboardAutomationIsOperational
                                ? "지금 갱신 필요"
                                : "자동 갱신을 켜면 실행"
                        ),
                        systemImage: "calendar"
                    )
                    renewalMetric(
                        title:
                            showsInstallationEvidence
                            ? "확인된 서명 만료"
                            : "서명 만료",
                        value:
                            showsInstallationEvidence
                            ? formattedStatusDate(
                                model.configurationIsDirty
                                    ? nil
                                    : model.provisioningExpirationDate,
                                empty:
                                    model.configurationIsDirty
                                    ? "변경 저장 후 확인"
                                    : "갱신 후 확인"
                            )
                            : "실제 갱신 후 확인",
                        systemImage: "signature"
                    )
                }
            }

            Divider()

            if model.configurationIsDirty {
                Label(
                    "아래 관계의 대상이 변경되어 이전 대상의 설치·만료 기록은 숨겼습니다. 저장하면 현재 대상 기준으로 다시 계산합니다.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(warningTextColor)
            }

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("선택한 iPhone의 실제 개발자 앱")
                        .font(.callout.weight(.medium))
                    Text(model.installedAppSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let checkedAt = model.installedAppCheckedAt {
                        Text(
                            "iPhone 직접 조회 · "
                                + formattedStatusDate(checkedAt)
                        )
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    }
                    if let app = model.installedDeviceApp {
                        Text(
                            "\(app.name) · \(app.version) (\(app.bundleVersion))"
                        )
                        .font(.caption.weight(.medium))
                    }
                }
                Spacer()
                Button(
                    SideRefreshLocalization.string(
                        model.isInspectingInstalledApp
                            ? "확인 중…"
                            : "iPhone에서 모두 확인"
                    )
                ) {
                    model.inspectInstalledApp()
                }
                .disabled(
                    !destinationIPhoneIsSelected
                        || !sourceAppIsSelected
                        || model.isInspectingInstalledApp
                )
            }

            DisclosureGroup {
            if !model.installedDeveloperApps.isEmpty {
                VStack(spacing: 0) {
                    ForEach(
                        model.installedDeveloperApps,
                        id: \.bundleIdentifier
                    ) { app in
                        HStack(spacing: 10) {
                            Image(systemName: "app.fill")
                                .foregroundStyle(
                                    app.bundleIdentifier
                                        == model.target.bundleIdentifier
                                        ? SideRefreshPalette.cobalt
                                        : .secondary
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(app.name)
                                        .font(.callout.weight(.medium))
                                    if app.bundleIdentifier
                                        == model.target.bundleIdentifier
                                    {
                                        Text("갱신 대상")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(
                                                SideRefreshPalette.cobalt
                                            )
                                    }
                                }
                                Text(app.bundleIdentifier)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                                HStack(spacing: 6) {
                                    if app.builtByDeveloper {
                                        Text("Developer App")
                                    }
                                    if app.appClip == true {
                                        Text("App Clip")
                                    }
                                    Text(
                                        app.removable == true
                                            ? "삭제 가능"
                                            : "삭제 제한"
                                    )
                                }
                                .font(.caption2)
                                .foregroundStyle(.tertiary)

                                if let url = app.url {
                                    Text(url)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .textSelection(.enabled)
                                }
                            }
                            Spacer()
                            Text(
                                "\(app.version) (\(app.bundleVersion))"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)

                        if app.bundleIdentifier
                            != model.installedDeveloperApps.last?
                                .bundleIdentifier
                        {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 10)
                .background(
                    Color.primary.opacity(0.035),
                    in: RoundedRectangle(
                        cornerRadius: 9,
                        style: .continuous
                    )
                )
            }

            VStack(alignment: .leading, spacing: 5) {
                Label(
                    model.installedProvisioningProfileMatchesReceipt
                        ? "설치 영수증 UUID와 같은 프로파일 있음"
                        : "Apple Development 프로파일",
                    systemImage:
                        model.installedProvisioningProfileMatchesReceipt
                        ? "link.badge.plus"
                        : "person.badge.key.fill"
                )
                .font(.callout.weight(.medium))
                Text(model.deviceProfileSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let profile = model.installedProvisioningProfile {
                    if !model.installedProvisioningProfileMatchesReceipt {
                        Label(
                            "후보 정보 · 현재 설치 앱과 UUID가 일치한다고 확인되지 않음",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange)
                    }

                    Grid(
                        alignment: .leading,
                        horizontalSpacing: 10,
                        verticalSpacing: 4
                    ) {
                        exactTargetRow(
                            "프로파일",
                            value: profile.name
                        )
                        exactTargetRow(
                            "App ID 이름",
                            value: profile.appIdentifierName ?? ""
                        )
                        exactTargetRow(
                            "App ID",
                            value:
                                profile.applicationIdentifier ?? ""
                        )
                        exactTargetRow(
                            "UUID",
                            value: profile.identifier
                        )
                        exactTargetRow(
                            "Team 이름",
                            value: profile.teamName ?? ""
                        )
                        exactTargetRow(
                            "Team ID",
                            value:
                                profile.teamIdentifiers.first ?? ""
                        )
                        exactTargetRow(
                            "발급일",
                            value: formattedStatusDate(
                                profile.creationDate
                            )
                        )
                        exactTargetRow(
                            "만료일",
                            value: formattedStatusDate(
                                profile.expirationDate
                            )
                        )
                        exactTargetRow(
                            "남은 기간",
                            value: remainingValidityText(
                                until: profile.expirationDate
                            )
                        )
                        exactTargetRow(
                            "유효 기간",
                            value: profile.timeToLiveDays.map {
                                "\($0)일"
                            } ?? ""
                        )
                        exactTargetRow(
                            "플랫폼",
                            value: profile.platforms.joined(
                                separator: ", "
                            )
                        )
                        exactTargetRow(
                            "대상 UDID",
                            value:
                                profile.provisionedDevices.contains(
                                    normalizedDeviceIdentifier
                                )
                                ? "현재 iPhone 포함"
                                : "현재 iPhone 미확인"
                        )
                        exactTargetRow(
                            "등록 기기",
                            value:
                                "\(profile.provisionedDevices.count)대"
                        )
                        exactTargetRow(
                            "프로파일 종류",
                            value:
                                profile.isLocalProvision == true
                                ? "Xcode 로컬 개발"
                                : "개발 프로비저닝"
                        )
                        exactTargetRow(
                            "인증서",
                            value:
                                profile.developerCertificateNames
                                    .joined(separator: ", ")
                        )
                    }

                    DisclosureGroup(
                        "Entitlements \(profile.entitlementKeys.count)개"
                    ) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(
                                profile.entitlementKeys,
                                id: \.self
                            ) { key in
                                Text(key)
                                    .font(.caption.monospaced())
                                    .textSelection(.enabled)
                            }
                        }
                        .padding(.top, 6)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.primary.opacity(0.035),
                in: RoundedRectangle(
                    cornerRadius: 9,
                    style: .continuous
                )
            )

            Text(
                "앱 목록은 Xcode 기기 도구로 iPhone에서 직접 읽습니다. 프로파일 조회 도구가 있으면 iPhone이 보유한 Apple Development 프로파일을 SideRefresh 설치 영수증 UUID와 대조합니다. 이는 현재 앱과 프로파일을 직접 연결하는 증거가 아닙니다. 도구가 없을 때는 SideRefresh가 설치한 앱 번들의 서명 만료 영수증만 표시합니다."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            } label: {
                Label(
                    "고급 iPhone 진단 보기",
                    systemImage: "list.bullet.rectangle"
                )
                .font(.callout.weight(.medium))
            }
        }
    }

    private var renewalRunProgressCard: some View {
        SettingsCard(
            title: renewalRunCardTitle,
            subtitle: model.currentRenewalProgressMessage,
            systemImage: renewalRunCardSystemImage
        ) {
            if model.isWorking {
                ProgressView()
                    .progressViewStyle(.linear)
            }

            VStack(spacing: 0) {
                ForEach(
                    model.orderedRenewalProgressEvents,
                    id: \.phase
                ) { event in
                    HStack(alignment: .top, spacing: 10) {
                        Image(
                            systemName:
                                progressSystemImage(event.state)
                        )
                        .foregroundStyle(
                            progressColor(event.state)
                        )
                        .frame(width: 18)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(progressPhaseTitle(event.phase))
                                .font(.callout.weight(.medium))
                            Text(event.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        Spacer()
                        Text(progressStateTitle(event.state))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(
                                progressColor(event.state)
                            )
                    }
                    .padding(.vertical, 7)

                    if event.phase
                        != model.orderedRenewalProgressEvents.last?
                            .phase
                    {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 10)
            .background(
                Color.primary.opacity(0.035),
                in: RoundedRectangle(
                    cornerRadius: 9,
                    style: .continuous
                )
            )

            HStack {
                Label(
                    "상세 로그 · \(model.renewalLogLineCount)줄",
                    systemImage: "terminal"
                )
                .font(.callout.weight(.medium))
                Spacer()
                Button("전체 복사") {
                    model.copyRenewalLog()
                }
                .disabled(model.renewalLogText.isEmpty)
                Button("상세 로그 열기") {
                    RenewalLogWindowPresenter.shared.show(
                        model: model
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.renewalLogText.isEmpty)
                Button("지우기") {
                    model.clearRenewalLog()
                }
                .disabled(model.isWorking)
            }

            Text(model.renewalLogPreviewText)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(
                    colorScheme == .dark
                        ? Color.white.opacity(0.88)
                        : SideRefreshPalette.ink
                )
                .textSelection(.enabled)
                .lineLimit(8)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding(10)
                .background(
                    Color.black.opacity(
                        colorScheme == .dark ? 0.28 : 0.055
                    ),
                    in: RoundedRectangle(
                        cornerRadius: 9,
                        style: .continuous
                    )
                )
        }
    }

    private var renewalRunCardTitle: String {
        switch model.renewalRunPresentationState {
        case .idle:
            return "갱신 실행 로그"
        case .running:
            return "앱 갱신 진행 중"
        case .succeeded:
            return "앱 갱신 성공"
        case .failed:
            return "앱 갱신 실패"
        }
    }

    private var renewalRunCardSystemImage: String {
        switch model.renewalRunPresentationState {
        case .idle:
            return "terminal"
        case .running:
            return "arrow.triangle.2.circlepath"
        case .succeeded:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.octagon.fill"
        }
    }

    private func progressPhaseTitle(
        _ phase: RenewalProgressPhase
    ) -> String {
        switch phase {
        case .preparing:
            return "설정 준비"
        case .checkingConnection:
            return "iPhone 연결 확인"
        case .cleaningBuild:
            return "이전 빌드 정리"
        case .building:
            return "Xcode 빌드·서명"
        case .validatingApp:
            return "앱 식별자 검증"
        case .readingProfile:
            return "서명 만료 확인"
        case .installing:
            return "iPhone 설치"
        case .recordingReceipt:
            return "갱신 영수증 저장"
        case .completed:
            return "완료"
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

    private var showsInstallationEvidence: Bool {
        model.hasGuidedTarget && model.renewalMode == .execute
    }

    private func renewalMetric(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: systemImage)
                .foregroundStyle(SideRefreshPalette.cobalt)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.callout.weight(.medium))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            Color.primary.opacity(0.035),
            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
        )
    }

    private func formattedStatusDate(
        _ date: Date?,
        empty: String = "기록 없음"
    ) -> String {
        guard let date else {
            return empty
        }
        return SideRefreshLocalization.date(
            date,
            dateStyle: .medium,
            timeStyle: .short
        )
    }

    private func remainingValidityText(
        until expirationDate: Date
    ) -> String {
        let remaining = expirationDate.timeIntervalSinceNow
        guard remaining > 0 else {
            return "만료됨"
        }
        let hours = Int(remaining / (60 * 60))
        let days = hours / 24
        let remainingHours = hours % 24
        return days > 0
            ? "\(days)일 \(remainingHours)시간"
            : "\(remainingHours)시간"
    }

    private var sourceAppIsSelected: Bool {
        guard model.hasGuidedTarget else {
            return false
        }
        return sourceContainerIsSelected && appBuildDetailsAreComplete
    }

    private var sourceAppChoiceIsSelected: Bool {
        sourceContainerIsSelected
            && !model.target.productName.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
    }

    private var sourceContainerIsSelected: Bool {
        !model.target.containerPath.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
    }

    private var sourceAppTitle: String {
        guard model.hasGuidedTarget else {
            return model.targetDisplayName
        }
        if sourceAppChoiceIsSelected {
            return model.target.displayName
        }
        return sourceContainerIsSelected
            ? "앱 정보 확인 필요"
            : "설치할 앱 선택"
    }

    private var sourceAppDetail: String {
        guard model.hasGuidedTarget else {
            let executable = model.executablePath.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            return executable.isEmpty
                ? "실행 파일을 확인하세요."
                : executable
        }
        guard sourceContainerIsSelected else {
            return "Mac의 .xcworkspace 또는 .xcodeproj에서 선택하세요."
        }
        guard sourceAppChoiceIsSelected else {
            return "\(model.target.projectName) · 빌드할 앱 정보를 확인하세요."
        }
        return model.target.projectName
    }

    private var sourceAppActionTitle: String {
        guard model.hasGuidedTarget else {
            return "명령 확인"
        }
        if sourceAppIsSelected {
            return "다른 앱 선택"
        }
        return sourceContainerIsSelected
            ? "빌드 정보 확인"
            : "앱 선택"
    }

    private func openSourceAppSetup() {
        guard model.hasGuidedTarget else {
            select(.app)
            return
        }
        if sourceContainerIsSelected, !sourceAppIsSelected {
            select(.app)
            showsBuildDetails = true
        } else {
            openProjectPicker()
        }
    }

    private var destinationIPhoneIsSelected: Bool {
        model.hasGuidedTarget
            && !normalizedDeviceIdentifier.isEmpty
            && !normalizedDeviceIdentifier.hasPrefix("REPLACE_")
    }

    private var normalizedDeviceIdentifier: String {
        model.target.deviceIdentifier.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var selectedCoreDevice: CoreDevice? {
        model.pairedCoreDevices.first {
            $0.udid == normalizedDeviceIdentifier
        }
    }

    private var destinationIPhoneTitle: String {
        guard model.hasGuidedTarget else {
            return "명령에서 결정됨"
        }
        if let selectedCoreDevice {
            return selectedCoreDevice.name
        }
        if let rememberedName = model.selectedCoreDeviceDisplayName {
            return rememberedName
        }
        return destinationIPhoneIsSelected
            ? "저장된 iPhone"
            : "설치할 iPhone 선택"
    }

    private var destinationIPhoneDetail: String {
        guard model.hasGuidedTarget else {
            return "고급 명령 내용을 직접 확인하세요."
        }
        if let selectedCoreDevice {
            var details: [String] = []
            if let name = selectedCoreDevice.marketingName {
                details.append(name)
            }
            let deviceDescription = details.joined(separator: " · ")
            return deviceDescription.isEmpty
                ? "Xcode에서 확인된 iPhone"
                : deviceDescription
        }
        return normalizedDeviceIdentifier.isEmpty
            ? "앱을 받을 실제 iPhone 한 대를 선택하세요."
            : "저장된 설치 대상"
    }

    private var deploymentPairSummary: String {
        guard model.hasGuidedTarget else {
            return "직접 만든 명령이 앱과 작업 대상을 결정합니다. 명령 내용을 확인하세요."
        }
        guard sourceAppIsSelected, destinationIPhoneIsSelected else {
            return "앱과 iPhone을 선택하면 자동 갱신 대상이 완성됩니다."
        }
        return "\(sourceAppTitle) → \(destinationIPhoneTitle) · 이 앱을 이 iPhone에 다시 설치합니다."
    }

    private func openDestinationSetup() {
        select(model.hasGuidedTarget ? .iphone : .app)
    }

    private func openNextSetupStep() {
        guard model.hasGuidedTarget else {
            select(.app)
            return
        }
        guard let missingField = model.missingTargetRequiredField else {
            select(.automation)
            return
        }
        switch missingField.setupArea {
        case .app:
            select(.app)
        case .iphone:
            select(.iphone)
        case .automation:
            select(.automation)
        }
    }

    private var guidedTargetRequiredCard: some View {
        SettingsCard(
            title: "자동 갱신할 앱을 먼저 설정하세요",
            subtitle: "현재는 직접 만든 명령이 저장되어 있어 설치할 앱과 iPhone을 알 수 없습니다.",
            systemImage: "iphone.slash"
        ) {
            HStack {
                Text("앱 화면에서 ‘iOS 앱 자동 갱신으로 전환’을 누른 뒤 프로젝트를 선택하세요.")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("앱 설정 열기") {
                    select(.app)
                }
            }
        }
    }

    private var guidedTargetMigrationCard: some View {
        SettingsCard(
            title: "iOS 앱 자동 갱신 설정",
            subtitle: "설치할 앱과 iPhone을 선택하는 일반 설정으로 전환하세요.",
            systemImage: "app.badge.checkmark"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(
                    "현재 저장된 고급 설정은 전환 내용을 저장하기 전까지 그대로 유지됩니다."
                )
                .foregroundStyle(.secondary)

                Button("설치할 앱 선택") {
                    if model.useGuidedTargetEditor() {
                        showsProjectPicker = true
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var legacyConfigurationSummaryCard: some View {
        SettingsCard(
            title: "기존 고급 설정",
            subtitle: "편집은 숨겨져 있지만 현재 저장된 실행 대상은 확인하고 자동 실행을 끌 수 있습니다.",
            systemImage: "terminal"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                LabeledContent("실행 파일") {
                    Text(model.executablePath)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
                DisclosureGroup("실행 인자 보기") {
                    Text(
                        model.argumentsText.isEmpty
                            ? "인자 없음"
                            : model.argumentsText
                    )
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)
                }
            }
        }
    }

    private func select(_ section: SideRefreshWorkspaceSection) {
        selectedSectionRawValue = section.rawValue
    }

    private func openProjectPicker() {
        select(.app)
        guard model.hasGuidedTarget else {
            return
        }
        showsProjectPicker = true
    }

    private var targetCard: some View {
        SettingsCard(
            title: "Mac에서 설치할 앱",
            subtitle: "Mac에 있는 Xcode 파일에서 빌드할 iOS 앱을 선택합니다.",
            systemImage: "app.badge.checkmark"
        ) {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(sourceAppTitle)
                            .font(.headline)
                            .lineLimit(1)
                        Text(model.target.projectName)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Text(
                            model.target.containerPath.isEmpty
                                ? "Mac의 .xcworkspace 또는 .xcodeproj를 선택하세요."
                                : model.target.containerPath
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                    }
                    Spacer()
                    Button(
                        sourceAppIsSelected
                            ? "다른 앱 선택…"
                            : "앱 선택…"
                    ) {
                        showsProjectPicker = true
                    }
                }
                .padding(12)
                .background(
                    Color.primary.opacity(0.035),
                    in: RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                )

                Label(
                    "선택한 앱을 이 Mac에서 빌드한 뒤, 다음 화면에서 고른 iPhone에 설치합니다.",
                    systemImage: "arrow.right"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("정확한 빌드 대상")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Grid(
                        alignment: .leading,
                        horizontalSpacing: 12,
                        verticalSpacing: 7
                    ) {
                        exactTargetRow(
                            "Scheme",
                            value: model.target.scheme
                        )
                        exactTargetRow(
                            "빌드 결과 파일",
                            value: "\(model.target.productName).app"
                        )
                        exactTargetRow(
                            "Bundle ID",
                            value: model.target.bundleIdentifier
                        )
                        exactTargetRow(
                            "Team ID",
                            value: model.target.developmentTeam
                        )
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Color.primary.opacity(0.035),
                    in: RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                )

                personalTeamDiscoveryPanel

                DisclosureGroup(
                    isExpanded: $showsBuildDetails
                ) {
                    Grid(
                        alignment: .leading,
                        horizontalSpacing: 14,
                        verticalSpacing: 10
                    ) {
                        targetField(
                            "앱 구성 (Scheme)",
                            placeholder: "MyApp",
                            text: $model.target.scheme,
                            explanation:
                                "Xcode의 Scheme 이름입니다. 선택한 앱에 연결된 Scheme도 하나일 때만 자동으로 채웁니다."
                        )
                        targetField(
                            "빌드 결과 파일 이름",
                            placeholder: "MyApp",
                            text: $model.target.productName,
                            explanation:
                                "빌드 후 만들어지는 .app 파일의 이름입니다."
                        )
                        targetField(
                            "앱 식별자",
                            placeholder: "com.example.myapp",
                            text: $model.target.bundleIdentifier,
                            explanation:
                                "Xcode의 Bundle Identifier입니다. 다른 앱을 잘못 교체하지 않도록 확인합니다."
                        )
                        targetField(
                            "Apple 팀 ID",
                            placeholder: "ABCDE12345",
                            text: $model.target.developmentTeam,
                            explanation:
                                "Xcode > Signing & Capabilities에 표시되는 Personal Team의 10자리 식별자입니다."
                        )
                    }
                    .padding(.top, 8)
                } label: {
                    HStack {
                        Text("빌드 및 서명 정보 수정")
                        Spacer()
                        Text(
                            appBuildDetailsAreComplete
                                ? "입력 완료"
                                : "확인 필요"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            appBuildDetailsAreComplete
                                ? SideRefreshPalette.success(
                                    for: colorScheme
                                )
                                : warningTextColor
                        )
                    }
                }
            }
        }
    }

    private var appBuildDetailsAreComplete: Bool {
        [
            model.target.scheme,
            model.target.productName,
            model.target.bundleIdentifier,
            model.target.developmentTeam,
        ].allSatisfy {
            !$0.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
        }
    }

    private var personalTeamDiscoveryPanel: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(SideRefreshPalette.cobalt)
                    .frame(width: 34, height: 34)
                    .background(
                        SideRefreshPalette.cobalt.opacity(0.10),
                        in: RoundedRectangle(
                            cornerRadius: 9,
                            style: .continuous
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple 팀 준비")
                        .font(.callout.weight(.semibold))
                    Text(personalTeamReadinessSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    if personalTeamIsReady {
                        Button {
                            model.rediscoverPersonalTeam()
                        } label: {
                            Label(
                                model.isDiscoveringPersonalTeam
                                    ? "다시 찾는 중…"
                                    : "Team 다시 찾기",
                                systemImage: "key"
                            )
                        }
                        .buttonStyle(.bordered)
                        .disabled(model.isDiscoveringPersonalTeam)
                    } else {
                        Button {
                            model.rediscoverPersonalTeam()
                        } label: {
                            Label(
                                model.isDiscoveringPersonalTeam
                                    ? "Team 찾는 중…"
                                    : "이 Mac에서 Team 찾기",
                                systemImage: "key"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.isDiscoveringPersonalTeam)
                    }

                    Button("준비 가이드") {
                        showsPersonalTeamGuide = true
                    }
                    .help("Personal Team 준비 가이드")
                }
            }

            if model.isDiscoveringPersonalTeam {
                HStack(spacing: 7) {
                    ProgressView()
                        .controlSize(.small)
                    Text(
                        "로컬 프로파일과 Apple Development 인증서를 읽는 중입니다."
                    )
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            } else if let selection = model.personalTeamSelection {
                personalTeamSelectionView(selection)
            }

            Text(
                "Keychain의 Apple Development 인증서 후보는 이 버튼을 누를 때만 읽습니다. 로컬 프로파일은 예제 복구 중에도 확인할 수 있으며, 어떤 정보도 변경하지 않습니다."
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            personalTeamIsReady
                ? Color.primary.opacity(0.035)
                : SideRefreshPalette.cobalt.opacity(
                    colorScheme == .dark ? 0.12 : 0.065
                ),
            in: RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
            .strokeBorder(
                personalTeamIsReady
                    ? Color.primary.opacity(0.08)
                    : SideRefreshPalette.cobalt.opacity(0.24)
            )
        }
    }

    private var personalTeamIsReady: Bool {
        let teamIdentifier = model.target.developmentTeam
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        return teamIdentifier.count == 10
            && teamIdentifier.rangeOfCharacter(
                from: CharacterSet.alphanumerics.inverted
            ) == nil
    }

    private var personalTeamReadinessSummary: String {
        let teamIdentifier = model.target.developmentTeam
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        guard personalTeamIsReady else {
            return "무료 Personal Team의 10자리 Team ID를 찾거나 준비 방법을 확인하세요."
        }
        return "사용할 Team ID · \(teamIdentifier)"
    }

    @ViewBuilder
    private func personalTeamSelectionView(
        _ selection: PersonalTeamSelection
    ) -> some View {
        switch selection {
        case .selected(let candidate):
            Label(
                "\(candidate.identifier) · \(personalTeamEvidenceText(candidate.source))",
                systemImage:
                    personalTeamEvidenceIsReady(candidate.source)
                    ? "checkmark.circle.fill"
                    : "exclamationmark.circle"
            )
            .font(.caption)
            .foregroundStyle(
                personalTeamEvidenceIsReady(candidate.source)
                    ? SideRefreshPalette.success(for: colorScheme)
                    : warningTextColor
            )
            .textSelection(.enabled)
        case .confirmationRequired(let candidate):
            VStack(alignment: .leading, spacing: 7) {
                Label(
                    "\(candidate.identifier) · \(personalTeamEvidenceText(candidate.source))",
                    systemImage: "exclamationmark.circle"
                )
                .font(.caption)
                .foregroundStyle(warningTextColor)
                .textSelection(.enabled)

                Text(
                    "인증서만으로는 Personal Team인지 확인할 수 없습니다. Xcode에서 같은 Team ID인지 확인한 뒤 적용하세요."
                )
                .font(.caption2)
                .foregroundStyle(.secondary)

                Button("확인하고 이 Team 사용") {
                    model.usePersonalTeamCandidate(candidate)
                }
            }
        case .notFound:
            Label(
                "Personal Team이 없거나 Xcode가 아직 서명 정보를 만들지 않았습니다. 준비 가이드를 따라 설정한 뒤 다시 찾으세요.",
                systemImage: "questionmark.circle"
            )
            .font(.caption)
            .foregroundStyle(warningTextColor)
        case .ambiguous(let candidates):
            VStack(alignment: .leading, spacing: 7) {
                Label(
                    "서명 팀을 여러 개 찾았습니다. Xcode에서 사용할 Team과 같은 항목을 선택하세요.",
                    systemImage: "person.2.fill"
                )
                .font(.caption)
                .foregroundStyle(warningTextColor)

                Menu("Team ID 선택…") {
                    ForEach(candidates) { candidate in
                        Button {
                            model.usePersonalTeamCandidate(candidate)
                        } label: {
                            Text(
                                "\(candidate.identifier) · \(personalTeamEvidenceText(candidate.source))"
                            )
                        }
                    }
                }
            }
        }
    }

    private func personalTeamEvidenceText(
        _ source: PersonalTeamCandidateSource
    ) -> String {
        switch source {
        case .xcodeProject:
            return "선택한 Xcode 앱 Target"
        case .activeLocalProvision:
            return "사용 가능한 Personal Team 프로파일"
        case .expiredLocalProvision:
            return "만료된 Personal Team 기록 · Xcode 준비 필요"
        case .appleDevelopmentIdentity:
            return "Apple Development 인증서 · Personal Team 여부 확인 필요"
        }
    }

    private func personalTeamEvidenceIsReady(
        _ source: PersonalTeamCandidateSource
    ) -> Bool {
        switch source {
        case .xcodeProject,
             .activeLocalProvision:
            return true
        case .expiredLocalProvision,
             .appleDevelopmentIdentity:
            return false
        }
    }

    private var iphoneCard: some View {
        SettingsCard(
            title: "2. 설치 대상 iPhone",
            subtitle: "앞에서 선택한 Mac 앱을 받을 iPhone 한 대를 선택합니다. iPhone 안의 앱을 고르는 화면이 아닙니다.",
            systemImage: "iphone.gen3"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Xcode가 알고 있는 iPhone")
                            .font(.callout.weight(.medium))
                        Text(model.coreDeviceDisplaySummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(
                        model.isDiscoveringCoreDevices
                            ? "찾는 중…"
                            : "Xcode에서 찾기"
                    ) {
                        model.discoverCoreDevices()
                    }
                    .disabled(model.isDiscoveringCoreDevices)
                }

                if !model.pairedCoreDevices.isEmpty {
                    Picker(
                        "설치할 iPhone",
                        selection: Binding(
                            get: {
                                model.target.deviceIdentifier
                            },
                            set: {
                                model.selectCoreDevice(udid: $0)
                            }
                        )
                    ) {
                        let currentUDID =
                            model.target.deviceIdentifier
                        if currentUDID.isEmpty {
                            Text("iPhone을 선택하세요")
                                .tag("")
                        } else if !model.pairedCoreDevices.contains(
                            where: { $0.udid == currentUDID }
                        ) {
                            Text("현재 직접 입력한 UDID 유지")
                                .tag(currentUDID)
                        }
                        ForEach(model.pairedCoreDevices) { device in
                            Text(coreDevicePickerLabel(device))
                                .tag(device.udid)
                        }
                    }
                }

                if destinationIPhoneIsSelected {
                    Label(
                        "\(destinationIPhoneTitle)에 \(sourceAppTitle) 앱을 설치합니다.",
                        systemImage: "checkmark.circle.fill"
                    )
                    .font(.callout.weight(.medium))
                    .foregroundStyle(
                        SideRefreshPalette.success(for: colorScheme)
                    )
                } else {
                    Label(
                        "설치할 iPhone을 선택해야 합니다.",
                        systemImage: "exclamationmark.circle"
                    )
                    .font(.callout.weight(.medium))
                    .foregroundStyle(warningTextColor)
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text("정확한 설치 대상")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Grid(
                        alignment: .leading,
                        horizontalSpacing: 10,
                        verticalSpacing: 5
                    ) {
                        exactTargetRow(
                            "이름",
                            value: destinationIPhoneTitle
                        )
                        exactTargetRow(
                            "모델",
                            value:
                                selectedCoreDevice?.marketingName
                                    ?? ""
                        )
                        exactTargetRow(
                            "iOS",
                            value:
                                selectedCoreDevice?
                                    .operatingSystemVersion ?? ""
                        )
                        exactTargetRow(
                            "페어링",
                            value:
                                selectedCoreDevice?.pairingState
                                    ?? "저장된 대상"
                        )
                        exactTargetRow(
                            "UDID",
                            value:
                                destinationIPhoneIsSelected
                                ? normalizedDeviceIdentifier
                                : ""
                        )
                    }
                }
                .padding(10)
                .background(
                    Color.primary.opacity(0.035),
                    in: RoundedRectangle(
                        cornerRadius: 9,
                        style: .continuous
                    )
                )

                Text(
                    "버튼을 누를 때만 Xcode가 이미 알고 있는 기기 목록을 읽습니다. 페어링하거나 기기 설정을 변경하지 않습니다."
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                DisclosureGroup(
                    "UDID 직접 변경 · 자동 검색이 안 될 때",
                    isExpanded: $showsManualUDID
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField(
                            "iPhone 기기 식별자(UDID)",
                            text: $model.target.deviceIdentifier
                        )
                        .textFieldStyle(.roundedBorder)

                        HStack(alignment: .firstTextBaseline) {
                            Text(
                                "Xcode > Window > Devices and Simulators에 표시되는 Identifier를 입력합니다."
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            Spacer()
                            Button("Xcode 열기") {
                                model.openXcode()
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    private var connectionCard: some View {
        SettingsCard(
            title: "Xcode 연결과 원격 주소",
            subtitle: "실제 갱신 대상은 Xcode/CoreDevice가 결정합니다."
                + " 원격 주소는 필요할 때만 준비합니다.",
            systemImage: "network"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Picker("원격 주소 준비", selection: $model.connectionRoute) {
                    ForEach(DeviceConnectionRoute.allCases) { route in
                        Text(route.title).tag(route)
                    }
                }
                .pickerStyle(.segmented)

                connectionRouteEditor

                if model.connectionRoute != .automatic {
                    HStack {
                        if let address = model.currentConnectionAddress {
                            Label(address, systemImage: "network")
                                .font(.callout.monospaced())
                                .textSelection(.enabled)
                        } else {
                            Text("현재 연결 주소 없음")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("주소 복사") {
                            model.copyCurrentConnectionAddress()
                        }
                        .disabled(model.currentConnectionAddress == nil)
                    }

                    Text(
                        "Xcode가 이 주소의 iPhone을 아직 찾지 못한다면 Xcode > Window > Devices and Simulators에서 ‘Connect via IP Address’를 한 번 실행하세요."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func coreDevicePickerLabel(_ device: CoreDevice) -> String {
        var details = [device.name]
        if let marketingName = device.marketingName,
           marketingName != device.name
        {
            details.append(marketingName)
        }
        if let version = device.operatingSystemVersion {
            details.append("iOS \(version)")
        }
        details.append("…\(device.udid.suffix(6))")
        return details.joined(separator: " · ")
    }

    @ViewBuilder
    private var connectionRouteEditor: some View {
        switch model.connectionRoute {
        case .automatic:
            VStack(alignment: .leading, spacing: 5) {
                Label(
                    "추가 원격 주소를 사용하지 않습니다.",
                    systemImage: "iphone.gen3"
                )
                Text(
                    "USB 또는 Xcode가 사용할 수 있는 네트워크 경로를"
                        + " 자동으로 사용합니다."
                        + " 현재 전송 경로는 구분하지 않습니다."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

        case .tailnet:
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text(model.tailnetSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(
                        model.isDiscoveringTailnet
                            ? "찾는 중…"
                            : "Tailscale 주소 찾기"
                    ) {
                        model.discoverTailnetDevices()
                    }
                    .disabled(model.isDiscoveringTailnet)
                }

                if !selectableTailnetDevices.isEmpty {
                    Picker(
                        "Tailscale의 iPhone 주소",
                        selection: $model.selectedTailnetNodeID
                    ) {
                        Text("iPhone을 선택하세요")
                            .tag("")
                        ForEach(
                            selectableTailnetDevices,
                            id: \.id
                        ) { device in
                            Text(
                                TailnetDevicePresentation.pickerLabel(
                                    for: device
                                )
                            )
                            .tag(device.id ?? "")
                        }
                    }
                }

                Text(
                    "버튼을 누를 때만 Tailscale의 기기 목록과 주소를 읽습니다."
                        + " Tailscale 온라인은 Xcode 연결이나"
                        + " 실제 갱신 성공을 뜻하지 않습니다."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

        case .custom:
            VStack(alignment: .leading, spacing: 7) {
                TextField(
                    "iPhone IP 주소 또는 DNS 이름",
                    text: $model.customDeviceAddress
                )
                .textFieldStyle(.roundedBorder)
                Text(
                    "이 주소는 Xcode 연결을 준비하는 정보입니다."
                        + " 실제 설치 대상은 위 UDID로 결정되며"
                        + " Xcode에서 IP 연결이 먼저 필요합니다."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var selectableTailnetDevices: [TailnetDevice] {
        var seenIdentifiers = Set<String>()
        return model.tailnetDevices.filter { device in
            guard let identifier = device.id,
                  !identifier.isEmpty
            else {
                return false
            }
            return seenIdentifiers.insert(identifier).inserted
        }
    }

    private var renewalCard: some View {
        SettingsCard(
            title: "갱신 방식과 주기",
            subtitle: "\(sourceAppTitle) → \(destinationIPhoneTitle) 설치를 언제 실행할지 설정합니다.",
            systemImage: "arrow.triangle.2.circlepath"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                if model.renewalMode == .dryRun {
                    HStack(alignment: .center, spacing: 12) {
                        Label(
                            "현재 설정은 앱을 설치하지 않는 안전 확인 상태입니다. 자동 갱신을 쓰려면 실제 갱신으로 전환하세요.",
                            systemImage: "checkmark.shield"
                        )
                        .font(.caption)
                        .foregroundStyle(warningTextColor)

                        Spacer()

                        Button("실제 갱신 사용") {
                            model.renewalMode = .execute
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    Label(
                        renewalModeExplanation,
                        systemImage: "iphone.and.arrow.forward"
                    )
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.66))
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(
                            "갱신 빌드 방식",
                            systemImage: "hammer"
                        )
                        .font(.callout.weight(.medium))
                        Spacer()
                        Text("현재 로컬 소스 기준")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Picker(
                        "갱신 빌드 방식",
                        selection: $model.buildStrategy
                    ) {
                        Text("스마트 증분 · 권장")
                            .tag(IOSAppBuildStrategy.incremental)
                        Text("전체 다시 빌드")
                            .tag(IOSAppBuildStrategy.cleanRebuild)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)

                    Label(
                        buildStrategyExplanation,
                        systemImage:
                            model.buildStrategy == .incremental
                            ? "bolt.fill"
                            : "arrow.clockwise"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        model.buildStrategy == .incremental
                            ? Color.primary.opacity(0.66)
                            : warningTextColor
                    )
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(
                            "앱 버전 처리",
                            systemImage: "number.circle"
                        )
                        .font(.callout.weight(.medium))
                        Spacer()
                        Text("선택한 앱의 현재 버전 기준")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Picker(
                        "앱 버전 처리",
                        selection: $model.versionPolicy
                    ) {
                        Text("버전 그대로 유지")
                            .tag(IOSAppVersionPolicy.keep)
                        Text("자동으로 다음 버전")
                            .tag(IOSAppVersionPolicy.automatic)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)

                    Label(
                        model.versionPreviewText,
                        systemImage:
                            model.hasDetectedVersionPreview
                            ? "arrow.right.circle"
                            : "info.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.66))

                    Text(
                        model.versionPolicy == .automatic
                            ? "갱신 직전 iPhone에 설치된 버전을 확인하고 마지막 숫자를 올립니다. 설치된 앱이 없으면 프로젝트 버전에서 시작합니다."
                            : "프로젝트의 앱 버전과 빌드 번호를 바꾸지 않고 다시 빌드·설치합니다."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                HStack {
                    Text("갱신 간격")
                    Spacer()
                    Stepper(
                        renewalIntervalText,
                        value: $model.renewEveryHours,
                        in: RenewalInterval.supportedHours,
                        step: 1
                    )
                }

                Text(
                    "무료 Personal Team 앱이 7일 만료되기 전에 다시 설치되도록 144시간(6일)을 권장합니다."
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack {
                    Button("예제 설정 불러오기") {
                        model.loadBundledSample()
                    }
                    .help("실제 iPhone을 변경하지 않는 SideRefresh 예제 설정")

                    if model.configurationIsDirty {
                        Text("저장하지 않은 변경사항")
                            .font(.caption)
                            .foregroundStyle(warningTextColor)
                    }
                }

                DisclosureGroup("고급 설정 · 문제 해결용") {
                    Grid(
                        alignment: .leading,
                        horizontalSpacing: 14,
                        verticalSpacing: 10
                    ) {
                        GridRow {
                            Text("갱신 도구")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .frame(width: 96, alignment: .trailing)
                            Text(model.executablePath)
                                .font(.callout.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .textSelection(.enabled)
                        }
                        targetField(
                            "임시 빌드 폴더",
                            placeholder: "/absolute/path/DerivedData",
                            text: $model.target.derivedDataPath,
                            explanation:
                                "Xcode가 자동 갱신용 빌드 파일을 저장하는 폴더입니다. 보통 바꿀 필요가 없습니다."
                        )
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    private var renewalModeExplanation: String {
        switch model.renewalMode {
        case .dryRun:
            return "설정 형식만 확인합니다. Xcode 빌드, 서명, iPhone 설치는 모두 실행하지 않습니다."
        case .execute:
            return "앱을 빌드한 뒤 선택한 iPhone의 기존 앱을 새 빌드로 교체합니다."
        }
    }

    private var renewalIntervalText: String {
        let hours = model.renewEveryHours
        guard hours.isMultiple(of: 24) else {
            return "\(hours)시간"
        }
        return "\(hours)시간 (\(hours / 24)일)"
    }

    private var buildStrategyExplanation: String {
        switch model.buildStrategy {
        case .incremental:
            return "Xcode가 바뀌지 않은 중간 결과를 재사용할 수 있도록 캐시를 유지합니다. 빌드·서명·설치는 실행하며, 평소 자동 갱신에는 이 방식을 권장합니다."
        case .cleanRebuild:
            return "Xcode clean 후 현재 로컬 소스를 전부 다시 만듭니다. 캐시나 의존성 문제를 해결할 때만 사용하세요."
        }
    }

    #if DEBUG
    private var customCommandCard: some View {
        SettingsCard(
            title: "직접 만든 실행 명령",
            subtitle: "이 설정은 SideRefresh의 기본 iOS 앱 갱신 형식이 아닙니다. 명령의 동작을 알고 있을 때만 사용하세요.",
            systemImage: "terminal"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                TextField(
                    "실행 파일 절대 경로",
                    text: $model.executablePath
                )
                .textFieldStyle(.roundedBorder)
                TextEditor(text: $model.argumentsText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 120)
                    .overlay {
                        RoundedRectangle(cornerRadius: 7)
                            .strokeBorder(.primary.opacity(0.12))
                    }
                HStack {
                    Button("명령 저장") {
                        requestSave()
                    }
                    .buttonStyle(.borderedProminent)
                    Button("iOS 앱 자동 갱신으로 전환") {
                        model.useGuidedTargetEditor()
                    }
                }
            }
        }
    }
    #endif

    private var automationCard: some View {
        SettingsCard(
            title: "자동 갱신 상태",
            subtitle: "SideRefresh 창을 닫아도 macOS가 정해진 때에 잠깐 실행해 갱신 여부를 확인합니다.",
            systemImage: "bolt.horizontal.circle"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(model.agentSummary, systemImage: "circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(
                            model.automationConfigurationNeedsSave
                                ? warningTextColor
                                : model.backgroundAutomationIsEnabled
                                ? SideRefreshPalette.success(
                                    for: colorScheme
                                )
                                : model.backgroundAutomationRequiresApproval
                                ? warningTextColor
                                : .secondary
                        )
                    Spacer()

                    if model.automationConfigurationNeedsSave {
                        if model.backgroundAutomationIsEnabled
                            || model.backgroundAutomationRequiresApproval
                        {
                            Button("자동 갱신 끄기") {
                                confirmsUnregistration = true
                            }
                        }
                        Button("변경사항 저장") {
                            requestSave()
                        }
                        .buttonStyle(.borderedProminent)
                    } else if model.backgroundAutomationIsEnabled {
                        Button("자동 갱신 끄기") {
                            confirmsUnregistration = true
                        }
                    } else if model.backgroundAutomationRequiresApproval {
                        Button("자동 갱신 끄기") {
                            confirmsUnregistration = true
                        }
                        Button("백그라운드 실행 허용…") {
                            model.openLoginItemSettings()
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("자동 갱신 켜기") {
                            confirmsRegistration = true
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!model.canRegisterAgent)
                    }
                }

                if !model.backgroundAutomationIsEnabled
                    && !model.backgroundAutomationRequiresApproval
                    && !model.canRegisterAgent
                {
                    if model.hasGuidedTarget
                        && model.renewalMode == .dryRun
                    {
                        Label(
                            "아래에서 ‘실제 갱신 사용’을 선택한 뒤 설정을 저장하세요.",
                            systemImage: "arrow.down"
                        )
                        .font(.caption)
                        .foregroundStyle(warningTextColor)
                    } else if model.automationConfigurationNeedsSave {
                        Button("변경사항 저장") {
                            requestSave()
                        }
                    } else {
                        Button("자동 갱신 설정 계속") {
                            openNextSetupStep()
                        }
                    }
                }

                Text(
                    "Mac이 잠자기 중 놓친 일정은 깨어난 뒤 실행됩니다. "
                        + "iPhone에 연결할 수 없으면 성공으로 기록하지 않고 다음 일정에 다시 시도합니다."
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                if model.backgroundAutomationRequiresApproval {
                    Label(
                        "이 버튼은 계정 로그인이 아니라 macOS의 로그인 항목 및 확장 프로그램 설정을 엽니다. SideRefresh의 백그라운드 실행을 허용해 주세요.",
                        systemImage: "gearshape"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } else if model.backgroundAutomationIsEnabled {
                    Label(
                        "자동 갱신이 켜져 있어 SideRefresh 앱을 항상 열어 둘 필요가 없습니다.",
                        systemImage: "checkmark.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("SideRefresh · 개인용 iOS 앱 자동 갱신 도우미")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
            if !model.configurationIsDirty,
               let last = model.lastSuccessfulRenewal
            {
                Text(
                    "마지막 성공 "
                        + SideRefreshLocalization.date(
                            last,
                            dateStyle: .medium,
                            timeStyle: .short
                        )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 2)
    }

    private func requestSave() {
        if let missingField = model.missingTargetRequiredField {
            continueSetup(for: missingField)
            return
        }
        if model.saveRequiresActiveAgentConfirmation {
            confirmsSavingActiveAgent = true
        } else {
            model.saveConfiguration()
        }
    }

    @ViewBuilder
    private func targetField(
        _ title: String,
        placeholder: String,
        text: Binding<String>,
        explanation: String? = nil
    ) -> some View {
        GridRow {
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .trailing)
            VStack(alignment: .leading, spacing: 3) {
                TextField(placeholder, text: text)
                    .textFieldStyle(.roundedBorder)
                if let explanation {
                    Text(explanation)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    @ViewBuilder
    private func exactTargetRow(
        _ title: String,
        value: String
    ) -> some View {
        GridRow {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .trailing)
            let trimmedValue = value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            Text(trimmedValue.isEmpty ? "미입력" : trimmedValue)
                .font(.caption.monospaced())
                .foregroundStyle(
                    trimmedValue.isEmpty
                        ? warningTextColor
                        : .primary
                )
                .textSelection(.enabled)
        }
    }
}

private struct PersonalTeamSetupGuideSheet: View {
    @ObservedObject var model: SideRefreshViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "key.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(SideRefreshPalette.cobalt)
                    .frame(width: 44, height: 44)
                    .background(
                        SideRefreshPalette.cobalt.opacity(0.11),
                        in: RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                    )
                VStack(alignment: .leading, spacing: 3) {
                    Text("Personal Team 준비 가이드")
                        .font(.title2.weight(.semibold))
                    Text(
                        "무료 Apple Account를 Xcode에 연결하고 첫 iPhone 서명을 준비합니다."
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Button("닫기") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(22)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Label(
                        "Apple Developer Program 유료 등록은 필요하지 않습니다. 무료 계정을 Xcode에 추가하면 Xcode가 Personal Team을 표시합니다.",
                        systemImage: "checkmark.seal.fill"
                    )
                    .font(.callout.weight(.medium))
                    .foregroundStyle(
                        SideRefreshPalette.success(for: colorScheme)
                    )
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        SideRefreshPalette.success(
                            for: colorScheme
                        ).opacity(0.08),
                        in: RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                    )

                    PersonalTeamGuideStep(
                        number: 1,
                        title: "Xcode에 Apple Account 추가",
                        detail:
                            "Xcode → Settings → Accounts에서 + 버튼을 눌러 Apple Account로 로그인합니다. 로그인과 2단계 인증은 Xcode에서 직접 진행합니다."
                    )
                    PersonalTeamGuideStep(
                        number: 2,
                        title: "앱 Target에 Personal Team 지정",
                        detail:
                            "프로젝트에서 iOS 앱 Target을 선택하고 Signing & Capabilities를 엽니다. Automatically manage signing을 켠 뒤 ‘이름 (Personal Team)’을 선택합니다."
                    )
                    PersonalTeamGuideStep(
                        number: 3,
                        title: "Bundle ID와 모든 Target 확인",
                        detail:
                            "Bundle Identifier가 고유한지 확인합니다. 앱 확장이나 위젯이 있다면 관련 Target에도 같은 Team을 지정합니다."
                    )
                    PersonalTeamGuideStep(
                        number: 4,
                        title: "실제 iPhone에서 한 번 실행",
                        detail:
                            "iPhone을 잠금 해제하고 Mac 신뢰와 Developer Mode를 승인합니다. Xcode 실행 대상을 iPhone으로 고른 뒤 Product → Run을 한 번 실행해 프로파일을 만듭니다."
                    )
                    PersonalTeamGuideStep(
                        number: 5,
                        title: "SideRefresh에서 다시 찾기",
                        detail:
                            "SideRefresh로 돌아와 ‘이 Mac에서 Team 찾기’를 누릅니다. 찾은 10자리 Team ID를 확인하고 설정을 저장합니다."
                    )

                    VStack(alignment: .leading, spacing: 7) {
                        Text("자동화하지 않는 항목")
                            .font(.callout.weight(.semibold))
                        Text(
                            "SideRefresh는 Apple Account 로그인, 2단계 인증, 약관 동의, 인증서 생성·삭제, iPhone 신뢰 및 Developer Mode 승인을 대신하지 않습니다."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    HStack {
                        if let accountGuideURL = URL(
                            string:
                                "https://developer.apple.com/help/account/basics/about-your-developer-account"
                        ) {
                            Link(
                                "Apple Personal Team 문서",
                                destination: accountGuideURL
                            )
                        }
                        if let signingGuideURL = URL(
                            string:
                                "https://help.apple.com/xcode/mac/current/en.lproj/dev23aab79b4.html"
                        ) {
                            Link(
                                "Apple 서명 설정 문서",
                                destination: signingGuideURL
                            )
                        }
                    }
                    .font(.caption)
                }
                .padding(22)
            }

            Divider()

            HStack {
                Button("Xcode 열기") {
                    model.openXcode()
                }
                Spacer()
                Button("Team ID 다시 찾기") {
                    model.rediscoverPersonalTeam()
                    dismiss()
                }
                .buttonStyle(SideRefreshPrimaryButtonStyle())
            }
            .padding(18)
        }
        .frame(width: 650, height: 700)
    }
}

private struct PersonalTeamGuideStep: View {
    let number: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(
                    SideRefreshPalette.brandGradient,
                    in: Circle()
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
        }
    }
}

private extension XcodeContainerKind {
    var sideRefreshLocalizedLabel: String {
        SideRefreshLocalization.string(localizedLabel)
    }
}

private extension XcodeContainerCandidate {
    var sideRefreshApplicationNameSummary: String {
        guard let firstName = sideRefreshApplicationNames.first else {
            return SideRefreshLocalization.string(
                "설치 가능한 앱 미확인"
            )
        }
        guard sideRefreshApplicationNames.count > 1 else {
            return firstName
        }
        return SideRefreshLocalization.format(
            "%@ 외 %ld개",
            firstName,
            sideRefreshApplicationNames.count - 1
        )
    }

    var sideRefreshApplicationNamesText: String {
        sideRefreshApplicationNames.isEmpty
            ? SideRefreshLocalization.string("설치 가능한 앱 미확인")
            : sideRefreshApplicationNames.joined(separator: ", ")
    }

    var sideRefreshApplicationTargetNamesText: String {
        applicationTargetNames.isEmpty
            ? SideRefreshLocalization.string("Xcode 대상 미확인")
            : applicationTargetNames.joined(separator: ", ")
    }

    var sideRefreshApplicationBundleIdentifiersText: String {
        applicationBundleIdentifiers.isEmpty
            ? SideRefreshLocalization.string("앱 식별자 미확인")
            : applicationBundleIdentifiers.joined(separator: ", ")
    }

    private var sideRefreshApplicationNames: [String] {
        applicationDisplayNames.isEmpty
            ? applicationTargetNames
            : applicationDisplayNames
    }
}

struct ProjectPickerView: View {
    @ObservedObject var model: SideRefreshViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var pendingContainerPath: String?
    @State private var isChoosingProject = false
    @State private var projectChoosingTask: Task<Void, Never>?
    let onSelection: (() -> Void)?
    let onClose: (() -> Void)?
    let isEmbedded: Bool

    init(
        model: SideRefreshViewModel,
        onSelection: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil,
        isEmbedded: Bool = false
    ) {
        self.model = model
        self.onSelection = onSelection
        self.onClose = onClose
        self.isEmbedded = isEmbedded
        _pendingContainerPath = State(
            initialValue: model.target.containerPath.isEmpty
                ? nil
                : model.target.containerPath
        )
    }

    private func filteredCandidates(
        using relationshipIndex: XcodeContainerRelationshipIndex
    ) -> [XcodeContainerCandidate] {
        let candidates = relationshipIndex.preferredCandidates(
            from: model.discoveredXcodeContainers
        )
        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !query.isEmpty else {
            return candidates
        }
        let matchingCandidateIDs = Set(
            model.discoveredXcodeContainers
                .filter { candidate in
                    candidateMatchesSearch(candidate, query: query)
                }
                .flatMap {
                    relationshipIndex.preferredCandidateIDs(for: $0.id)
                }
        )
        return candidates.filter {
            matchingCandidateIDs.contains($0.id)
        }
    }

    private func candidateMatchesSearch(
        _ candidate: XcodeContainerCandidate,
        query: String
    ) -> Bool {
        candidate.displayName.localizedCaseInsensitiveContains(query)
            || candidate.applicationDisplayNames.contains { name in
                name.localizedCaseInsensitiveContains(query)
            }
            || candidate.applicationTargetNames.contains { name in
                name.localizedCaseInsensitiveContains(query)
            }
            || candidate.applicationBundleIdentifiers.contains {
                identifier in
                identifier.localizedCaseInsensitiveContains(query)
            }
            || candidate.relativePath
                .localizedCaseInsensitiveContains(query)
            || candidate.url.path
                .localizedCaseInsensitiveContains(query)
            || candidate.kind.label
                .localizedCaseInsensitiveContains(query)
            || candidate.kind.sideRefreshLocalizedLabel
                .localizedCaseInsensitiveContains(query)
    }

    private var relationshipIndex: XcodeContainerRelationshipIndex {
        XcodeContainerRelationshipIndex(
            candidates: model.discoveredXcodeContainers
        )
    }

    private func preferredPendingContainerPath(
        using relationshipIndex: XcodeContainerRelationshipIndex
    ) -> String? {
        pendingContainerPath.flatMap {
            relationshipIndex.unambiguousPreferredCandidateID(
                for: $0
            )
        }
    }

    private func selectedCandidate(
        using relationshipIndex: XcodeContainerRelationshipIndex
    ) -> XcodeContainerCandidate? {
        guard let preferredPendingContainerPath =
            preferredPendingContainerPath(using: relationshipIndex)
        else {
            return nil
        }
        return model.discoveredXcodeContainers.first {
            $0.id == preferredPendingContainerPath
        }
    }

    private func usePendingContainer() {
        guard let preferredPendingContainerPath =
            preferredPendingContainerPath(using: relationshipIndex)
        else {
            return
        }
        if model.useXcodeContainer(preferredPendingContainerPath) {
            if let onSelection {
                onSelection()
            } else {
                closePicker()
            }
        }
    }

    private func closePicker() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    var body: some View {
        let relationshipIndex = self.relationshipIndex
        let preferredPendingContainerPath =
            self.preferredPendingContainerPath(
                using: relationshipIndex
            )
        let filteredCandidates = self.filteredCandidates(
            using: relationshipIndex
        )
        let selectedCandidate = self.selectedCandidate(
            using: relationshipIndex
        )
        let candidateSelection = Binding<String?>(
            get: { preferredPendingContainerPath },
            set: { pendingContainerPath = $0 }
        )
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Mac에서 설치할 앱 선택")
                        .font(.title2.weight(.semibold))
                    Text(
                        "Mac에서 빌드해 iPhone에 설치할 앱을 선택하세요. 같은 앱의 워크스페이스가 있으면 자동으로 사용합니다."
                    )
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    model.rescanHomeDirectory()
                } label: {
                    Label(
                        "홈 폴더 다시 검색",
                        systemImage: "arrow.clockwise"
                    )
                }
                .buttonStyle(.borderless)
            }
            .layoutPriority(10)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier(
                "simple.project-picker.header"
            )

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 14) {
                    ProjectSearchAccessCard(model: model)

                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField(
                            "앱 이름, Bundle ID, Xcode 대상 또는 경로 검색",
                            text: $searchText
                        )
                        .textFieldStyle(.plain)
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("검색어 지우기")
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        Color(nsColor: .textBackgroundColor),
                        in: RoundedRectangle(
                            cornerRadius: 8,
                            style: .continuous
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 8,
                            style: .continuous
                        )
                        .strokeBorder(.primary.opacity(0.12))
                    }

                    Group {
                        if filteredCandidates.isEmpty {
                            VStack(spacing: 8) {
                                Image(
                                    systemName: model.isScanningProjects
                                        ? "folder.badge.questionmark"
                                        : "magnifyingglass"
                                )
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                                Text(
                                    model.isScanningProjects
                                        ? "iOS 앱 프로젝트 찾는 중"
                                        : "조건에 맞는 앱 프로젝트가 없습니다"
                                )
                                .font(.headline)
                                Text(
                                    model.isScanningProjects
                                        ? "확인이 끝난 앱부터 바로 목록에 표시합니다."
                                        : "검색어를 지우거나 다른 폴더에서 찾아보세요."
                                )
                                .foregroundStyle(.secondary)
                            }
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity
                            )
                        } else {
                            List(
                                filteredCandidates,
                                selection: candidateSelection
                            ) { candidate in
                                ProjectCandidateRow(
                                    candidate: candidate,
                                    isSelected:
                                        preferredPendingContainerPath
                                            == candidate.id,
                                    isRecommended:
                                        candidate.kind == .workspace
                                            && relationshipIndex
                                                .recommendsWorkspace(
                                                    for: candidate
                                                ),
                                    colorScheme: colorScheme
                                )
                                .equatable()
                                .tag(candidate.id)
                            }
                            .listStyle(.inset)
                        }
                    }
                    .frame(height: 260)

                    HStack(spacing: 8) {
                        if model.isScanningProjects {
                            ProgressView()
                                .controlSize(.small)
                            Text(model.projectScanSummary)
                                .foregroundStyle(.secondary)
                            Button("중단") {
                                model.cancelProjectScan()
                            }
                        } else {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text(model.projectScanSummary)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .font(.caption)

                    Group {
                        if let selectedCandidate {
                            SelectedProjectDetail(
                                candidate: selectedCandidate,
                                hasRelatedContainer:
                                    relationshipIndex
                                        .recommendsWorkspace(
                                            for: selectedCandidate
                                        )
                            )
                        } else {
                            Text(
                                "목록에서 자동 갱신할 앱을 선택하면 빌드 및 서명 정보를 아래에서 확인할 수 있습니다."
                            )
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 270
                            )
                            .background(
                                Color.primary.opacity(0.025),
                                in: RoundedRectangle(
                                    cornerRadius: 10,
                                    style: .continuous
                                )
                            )
                        }
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 270,
                        alignment: .topLeading
                    )
                }
                .padding(.trailing, 4)
            }
            .frame(maxHeight: .infinity)

            HStack {
                Menu {
                    Button("다른 폴더 안에서 검색…") {
                        model.chooseProjectSearchFolder()
                    }
                    Button("Xcode 파일 직접 선택…") {
                        isChoosingProject = true
                        projectChoosingTask = Task {
                            defer {
                                isChoosingProject = false
                            }
                            if let path =
                                await model.addProjectContainer()
                            {
                                guard !Task.isCancelled else {
                                    return
                                }
                                pendingContainerPath = path
                            }
                        }
                    }
                } label: {
                    Label(
                        "다른 위치에서 찾기…",
                        systemImage: "folder"
                    )
                }
                .disabled(isChoosingProject)

                Spacer()

                if isChoosingProject {
                    ProgressView()
                        .controlSize(.small)
                }

                Button("취소", role: .cancel) {
                    projectChoosingTask?.cancel()
                    closePicker()
                }
                .keyboardShortcut(.cancelAction)
            }

            ProjectSelectionConfirmationBar(
                candidate: selectedCandidate,
                useSelection: usePendingContainer
            )
        }
        .simpleSettingsPageStyle(isEmbedded: isEmbedded)
        .task {
            model.prepareProjectSearch()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSApplication.didBecomeActiveNotification
            )
        ) { _ in
            model.refreshProjectSearchAccessAfterActivation()
        }
        .onDisappear {
            projectChoosingTask?.cancel()
            projectChoosingTask = nil
            model.cancelProjectSearchActivity()
        }
    }
}

private struct ProjectSelectionConfirmationBar: View {
    let candidate: XcodeContainerCandidate?
    let useSelection: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let candidate {
                ProjectAppIcon(
                    iconURL: candidate.applicationIconURL,
                    fallbackSystemImage:
                        candidate.kind == .workspace
                            ? "square.stack.3d.up"
                            : "hammer",
                    size: 36
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text("선택한 앱")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(candidate.sideRefreshApplicationNameSummary)
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                    Text(
                        SideRefreshLocalization.format(
                            "Bundle ID · %@",
                            candidate
                                .sideRefreshApplicationBundleIdentifiersText
                        )
                    )
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } else {
                Image(systemName: "cursorarrow.click")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("사용할 앱을 선택하세요")
                        .font(.callout.weight(.semibold))
                    Text("선택하면 이곳에서 바로 확정할 수 있습니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 12)

            Button(action: useSelection) {
                Label(
                    "선택한 앱 사용",
                    systemImage: "checkmark.circle.fill"
                )
                .frame(minWidth: 150)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .disabled(candidate == nil)
            .accessibilityLabel(
                candidate.map {
                    SideRefreshLocalization.format(
                        "%@ 앱 사용",
                        $0.sideRefreshApplicationNameSummary
                    )
                } ?? SideRefreshLocalization.string(
                    "사용할 앱을 먼저 선택하세요"
                )
            )
        }
        .padding(12)
        .background(
            candidate == nil
                ? Color.primary.opacity(0.025)
                : SideRefreshPalette.cobalt.opacity(0.08),
            in: RoundedRectangle(
                cornerRadius: 11,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 11,
                style: .continuous
            )
            .strokeBorder(
                candidate == nil
                    ? Color.primary.opacity(0.08)
                    : SideRefreshPalette.cobalt.opacity(0.28)
            )
        }
    }
}

private struct ProjectSearchAccessCard: View {
    @ObservedObject var model: SideRefreshViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false

    private var summary: ProjectSearchAccessSummary {
        ProjectSearchAccessSummary(
            locations: model.projectSearchLocations
        )
    }

    private var hasBlockedLocation: Bool {
        model.projectSearchLocations.contains {
            $0.status == .blocked
        }
    }

    private var hasLocationAwaitingSelection: Bool {
        model.projectSearchLocations.contains {
            $0.status == .selectionRequired
        }
    }

    private var summaryText: String {
        switch summary.state {
        case .ready:
            return SideRefreshLocalization.format(
                "%ld개 위치에서 검색",
                summary.searchableCount
            )
        case .checking:
            return SideRefreshLocalization.string(
                "검색 위치 확인 중"
            )
        case .actionRequired:
            return SideRefreshLocalization.format(
                "%ld개 위치 확인 필요",
                summary.actionRequiredCount
            )
        case .blocked:
            return SideRefreshLocalization.format(
                "%ld개 위치 접근 차단",
                summary.blockedCount
            )
        case .unavailable:
            return SideRefreshLocalization.string(
                "검색 가능한 위치 없음"
            )
        }
    }

    private var summaryImage: String {
        switch summary.state {
        case .ready:
            return "checkmark.circle.fill"
        case .checking:
            return "clock"
        case .actionRequired:
            return "questionmark.circle.fill"
        case .blocked:
            return "lock.circle.fill"
        case .unavailable:
            return "minus.circle.fill"
        }
    }

    private var summaryColor: Color {
        switch summary.state {
        case .ready:
            return SideRefreshPalette.success(for: colorScheme)
        case .checking, .actionRequired:
            return SideRefreshPalette.cobalt
        case .blocked, .unavailable:
            return SideRefreshPalette.warning(for: colorScheme)
        }
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    VStack(spacing: 0) {
                        ForEach(model.projectSearchLocations) { location in
                            ProjectSearchAccessRow(
                                location: location,
                                requestAccess: {
                                    model.requestProjectSearchAccess(
                                        for: location
                                    )
                                }
                            )
                            if location.id
                                != model.projectSearchLocations.last?.id
                            {
                                Divider()
                                    .padding(.leading, 30)
                            }
                        }
                    }

                    Label(
                        "소스 코드는 읽지 않습니다. Xcode 프로젝트의 앱 이름, iOS Target, Scheme, Bundle ID, Team 설정과 앱 아이콘만 확인하며 파일을 수정하거나 외부로 보내지 않습니다.",
                        systemImage: "hand.raised"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                    if hasLocationAwaitingSelection {
                        Label(
                            "폴더 선택 창에서는 왼쪽의 위치를 연 다음 오른쪽 아래 ‘이 위치 확인’을 누르세요.",
                            systemImage: "info.circle"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    if hasBlockedLocation {
                        HStack(spacing: 7) {
                            Image(
                                systemName: "exclamationmark.triangle.fill"
                            )
                                .foregroundStyle(
                                    SideRefreshPalette.warning(
                                        for: colorScheme
                                    )
                                )
                            Text(
                                "차단한 위치는 macOS의 파일 및 폴더 설정에서 다시 허용할 수 있습니다."
                            )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("시스템 설정 열기") {
                                model.openFilesAndFoldersPrivacySettings()
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 160)
            .padding(.top, 8)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "folder")
                    .foregroundStyle(SideRefreshPalette.cobalt)
                Text("검색 위치")
                    .font(.callout.weight(.semibold))
                Spacer(minLength: 12)
                Label(summaryText, systemImage: summaryImage)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(summaryColor)
                    .lineLimit(1)
            }
        }
        .accessibilityLabel(
            SideRefreshLocalization.string("검색 위치")
                + " · "
                + summaryText
        )
        .padding(12)
        .background(
            Color.primary.opacity(0.035),
            in: RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
            .strokeBorder(Color.primary.opacity(0.08))
        }
    }
}

private struct ProjectSearchAccessRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let location: ProjectSearchLocationAccess
    let requestAccess: () -> Void

    private var title: String {
        location.kind.presentation.title
            ?? location.url.lastPathComponent
    }

    private var pathText: String {
        let homePath = FileManager.default.homeDirectoryForCurrentUser
            .standardizedFileURL.path
        let path = location.url.standardizedFileURL.path
        let abbreviatedPath =
            path == homePath
            ? "~"
            : path.hasPrefix(homePath + "/")
            ? "~" + String(path.dropFirst(homePath.count))
            : path
        if location.kind == .home {
            return SideRefreshLocalization.format(
                "%@ · Library 및 숨김·빌드 폴더 제외",
                abbreviatedPath
            )
        }
        return abbreviatedPath
    }

    private var statusText: String {
        location.status.presentation.text
    }

    private var statusImage: String {
        location.status.presentation.systemImage
    }

    private var statusColor: Color {
        if location.status == .allowed {
            return .secondary
        }
        switch location.status.presentation.tone {
        case .success:
            return SideRefreshPalette.success(for: colorScheme)
        case .warning:
            return SideRefreshPalette.warning(for: colorScheme)
        case .brand:
            return SideRefreshPalette.cobalt
        case .secondary:
            return .secondary
        }
    }

    private var actionTitle: String? {
        location.status.presentation.actionTitle
    }

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: location.kind.presentation.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.weight(.medium))
                Text(pathText)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 8)
            if location.status == .checking {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel(statusText)
            } else {
                Label(statusText, systemImage: statusImage)
                    .font(.caption)
                    .foregroundStyle(statusColor)
                    .labelStyle(.titleAndIcon)
            }
            if let actionTitle {
                Button(actionTitle, action: requestAccess)
                    .buttonStyle(.borderless)
                    .accessibilityLabel("\(title) \(actionTitle)")
            }
        }
        .padding(.vertical, 6)
    }
}

private struct ProjectSearchLocationKindPresentation {
    let title: String?
    let systemImage: String
}

private extension ProjectSearchLocationKind {
    var presentation: ProjectSearchLocationKindPresentation {
        switch self {
        case .home:
            return ProjectSearchLocationKindPresentation(
                title: SideRefreshLocalization.string(
                    "홈 폴더의 일반 위치"
                ),
                systemImage: "house"
            )
        case .desktop:
            return ProjectSearchLocationKindPresentation(
                title: SideRefreshLocalization.string("데스크탑"),
                systemImage: "desktopcomputer"
            )
        case .documents:
            return ProjectSearchLocationKindPresentation(
                title: SideRefreshLocalization.string("문서"),
                systemImage: "doc"
            )
        case .downloads:
            return ProjectSearchLocationKindPresentation(
                title: SideRefreshLocalization.string("다운로드"),
                systemImage: "arrow.down.circle"
            )
        case .custom:
            return ProjectSearchLocationKindPresentation(
                title: nil,
                systemImage: "folder"
            )
        }
    }
}

private struct ProjectSearchStatusPresentation {
    enum Tone {
        case success
        case warning
        case brand
        case secondary
    }

    let text: String
    let systemImage: String
    let tone: Tone
    let actionTitle: String?
}

private extension ProjectSearchAccessStatus {
    var presentation: ProjectSearchStatusPresentation {
        switch self {
        case .selectionRequired:
            return ProjectSearchStatusPresentation(
                text: SideRefreshLocalization.string("폴더 선택 필요"),
                systemImage: "circle.dotted",
                tone: .brand,
                actionTitle: SideRefreshLocalization.string("폴더 선택…")
            )
        case .verificationRequired:
            return ProjectSearchStatusPresentation(
                text: SideRefreshLocalization.string("접근 확인 필요"),
                systemImage: "questionmark.circle",
                tone: .brand,
                actionTitle: SideRefreshLocalization.string("다시 확인")
            )
        case .checking:
            return ProjectSearchStatusPresentation(
                text: SideRefreshLocalization.string("실제 접근 확인 중"),
                systemImage: "clock",
                tone: .brand,
                actionTitle: nil
            )
        case .allowed:
            return ProjectSearchStatusPresentation(
                text: SideRefreshLocalization.string("검색 가능"),
                systemImage: "checkmark.circle.fill",
                tone: .success,
                actionTitle: SideRefreshLocalization.string("다시 확인")
            )
        case .partiallyBlocked:
            return ProjectSearchStatusPresentation(
                text: SideRefreshLocalization.string(
                    "일부 하위 폴더 제한"
                ),
                systemImage: "exclamationmark.circle.fill",
                tone: .warning,
                actionTitle: SideRefreshLocalization.string("다시 확인")
            )
        case .blocked:
            return ProjectSearchStatusPresentation(
                text: SideRefreshLocalization.string(
                    "macOS에서 접근 차단"
                ),
                systemImage: "lock.circle.fill",
                tone: .warning,
                actionTitle: SideRefreshLocalization.string("다시 확인")
            )
        case .missing:
            return ProjectSearchStatusPresentation(
                text: SideRefreshLocalization.string("폴더 없음"),
                systemImage: "questionmark.folder",
                tone: .secondary,
                actionTitle: nil
            )
        }
    }
}

private struct ProjectCandidateRow: View, Equatable {
    let candidate: XcodeContainerCandidate
    let isSelected: Bool
    let isRecommended: Bool
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 11) {
            ProjectAppIcon(
                iconURL: candidate.applicationIconURL,
                fallbackSystemImage:
                    candidate.kind == .workspace
                        ? "square.stack.3d.up"
                        : "hammer",
                size: 40
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(candidate.sideRefreshApplicationNameSummary)
                    .font(.callout.weight(.medium))
                Text(
                    SideRefreshLocalization.format(
                        "Bundle ID · %@",
                        candidate
                            .sideRefreshApplicationBundleIdentifiersText
                    )
                )
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(
                    SideRefreshLocalization.format(
                        "Xcode 대상 %@ · %@",
                        candidate.sideRefreshApplicationTargetNamesText,
                        candidate.relativePath
                    )
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                HStack(spacing: 6) {
                    Text(candidate.kind.sideRefreshLocalizedLabel)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Color.primary.opacity(0.055),
                            in: Capsule()
                        )

                    if isRecommended {
                        Text("권장")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(
                                SideRefreshPalette.success(
                                    for: colorScheme
                                )
                            )
                    }
                }

                if let modificationText {
                    Text(modificationText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Image(systemName: "checkmark")
                .foregroundStyle(SideRefreshPalette.cobalt)
                .opacity(isSelected ? 1 : 0)
                .frame(width: 14)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            SideRefreshLocalization.format(
                "앱 %@, 앱 식별자 %@, 타깃 %@, %@, %@%@",
                candidate.sideRefreshApplicationNamesText,
                candidate.sideRefreshApplicationBundleIdentifiersText,
                candidate.sideRefreshApplicationTargetNamesText,
                candidate.kind.sideRefreshLocalizedLabel,
                isRecommended
                    ? SideRefreshLocalization.string("권장, ")
                    : "",
                candidate.url.path
            )
            + modificationAccessibilitySuffix
        )
        .accessibilityValue(
            SideRefreshLocalization.string(
                isSelected ? "선택됨" : "선택 안 됨"
            )
        )
    }

    private var modificationText: String? {
        candidate.projectFileModificationDate.map {
            SideRefreshLocalization.format(
                "프로젝트 파일 수정 · %@",
                SideRefreshLocalization.date(
                    $0,
                    dateStyle: .medium,
                    timeStyle: .none
                )
            )
        }
    }

    private var modificationAccessibilitySuffix: String {
        modificationText.map { ", \($0)" } ?? ""
    }
}

struct ProjectAppIcon: View {
    let iconURL: URL?
    let fallbackSystemImage: String
    let size: CGFloat
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let displayedImage {
                Image(nsImage: displayedImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
            } else {
                ZStack {
                    SideRefreshPalette.brandGradient
                    Image(systemName: fallbackSystemImage)
                        .font(
                            .system(
                                size: size * 0.38,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(
            RoundedRectangle(
                cornerRadius: size * 0.22,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: size * 0.22,
                style: .continuous
            )
            .strokeBorder(.primary.opacity(0.10))
        }
        .task(id: iconURL) {
            image = nil
            guard let iconURL else {
                return
            }
            let loadedImage =
                await ProjectAppIconCache.shared.image(
                    for: iconURL
                )
            guard !Task.isCancelled else {
                return
            }
            image = loadedImage
        }
        .accessibilityHidden(true)
    }

    private var displayedImage: NSImage? {
        #if DEBUG
        SimpleWorkspaceFixtureCapture.preparedIcon(for: iconURL) ?? image
        #else
        image
        #endif
    }
}

private struct SendableProjectIcon: @unchecked Sendable {
    let cgImage: CGImage
}

@MainActor
private final class ProjectAppIconCache {
    static let shared = ProjectAppIconCache()

    private let cache = NSCache<NSURL, NSImage>()
    private var loadingTasks:
        [URL: Task<SendableProjectIcon?, Never>] = [:]

    private init() {
        cache.countLimit = 128
        cache.totalCostLimit = 32 * 1_024 * 1_024
    }

    func image(for url: URL) async -> NSImage? {
        let standardizedURL = url.standardizedFileURL
        let cacheKey = standardizedURL as NSURL
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }

        let loadingTask: Task<SendableProjectIcon?, Never>
        if let activeTask = loadingTasks[standardizedURL] {
            loadingTask = activeTask
        } else {
            let newTask = Task.detached(priority: .utility) {
                Self.loadThumbnail(at: standardizedURL)
            }
            loadingTasks[standardizedURL] = newTask
            loadingTask = newTask
        }

        guard let loadedIcon = await loadingTask.value else {
            loadingTasks[standardizedURL] = nil
            return nil
        }
        loadingTasks[standardizedURL] = nil

        let image = NSImage(
            cgImage: loadedIcon.cgImage,
            size: NSSize(
                width: loadedIcon.cgImage.width,
                height: loadedIcon.cgImage.height
            )
        )
        let cost =
            loadedIcon.cgImage.bytesPerRow
                * loadedIcon.cgImage.height
        cache.setObject(
            image,
            forKey: cacheKey,
            cost: cost
        )
        return image
    }

    nonisolated private static func loadThumbnail(
        at url: URL
    ) -> SendableProjectIcon? {
        let sourceOptions = [
            kCGImageSourceShouldCache: false,
        ] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(
            url as CFURL,
            sourceOptions
        ) else {
            return nil
        }
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 96,
            kCGImageSourceShouldCacheImmediately: true,
        ] as CFDictionary
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            thumbnailOptions
        ) else {
            return nil
        }
        return SendableProjectIcon(cgImage: thumbnail)
    }
}

private struct SelectedProjectDetail: View {
    @Environment(\.colorScheme) private var colorScheme
    let candidate: XcodeContainerCandidate
    let hasRelatedContainer: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Text("앱 이름")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(candidate.sideRefreshApplicationNamesText)
                    .font(.callout.weight(.semibold))
                Text(candidate.kind.sideRefreshLocalizedLabel)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                if isRecommended {
                    Text("권장")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(
                            SideRefreshPalette.success(
                                for: colorScheme
                            )
                        )
                }
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(
                        candidate.url.path,
                        forType: .string
                    )
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("전체 경로 복사")
                .help("전체 경로 복사")
            }

            Text(
                SideRefreshLocalization.format(
                    "Xcode에서 빌드할 대상 · %@",
                    candidate.sideRefreshApplicationTargetNamesText
                )
            )
                .font(.caption)
                .foregroundStyle(.secondary)

            if let application = candidate.unambiguousApplication {
                Grid(
                    alignment: .leading,
                    horizontalSpacing: 10,
                    verticalSpacing: 4
                ) {
                    projectDetailRow(
                        "앱 구성(Scheme)",
                        value: schemeSummary(for: application)
                    )
                    projectDetailRow(
                        "빌드 결과 파일",
                        value: "\(application.productName).app"
                    )
                    projectDetailRow(
                        "앱 식별자",
                        value: application.bundleIdentifier
                            ?? SideRefreshLocalization.string(
                                "자동으로 확인하지 못함"
                            )
                    )
                    projectDetailRow(
                        "버전",
                        value: AppIdentifierPresentation
                            .appVersionDetail(
                                marketingVersion:
                                    application.marketingVersion,
                                buildVersion: application.buildVersion
                            )
                            ?? SideRefreshLocalization.string(
                                "자동으로 확인하지 못함"
                            )
                    )
                    projectDetailRow(
                        "Apple 팀 ID",
                        value: application.developmentTeam
                            ?? SideRefreshLocalization.string(
                                "Xcode에서 직접 확인 필요"
                            )
                    )
                }
                .padding(.vertical, 3)
            } else if candidate.applications.count > 1 {
                Label(
                    "설치 가능한 앱이 여러 개라 앱 구성(Scheme)과 Apple 팀을 자동으로 고르지 않았습니다. 앱을 선택한 뒤 설정 화면에서 직접 확인해 주세요.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.caption)
                .foregroundStyle(
                    SideRefreshPalette.warning(for: colorScheme)
                )
            }

            Text(
                SideRefreshLocalization.format(
                    "선택할 Xcode 파일 · %@",
                    candidate.url.lastPathComponent
                )
            )
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(candidate.url.path)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)

            Text(selectionGuidance)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            Color.primary.opacity(0.035),
            in: RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
        )
    }

    private var isRecommended: Bool {
        candidate.kind == .workspace && hasRelatedContainer
    }

    private func schemeSummary(
        for application: XcodeApplicationTargetInfo
    ) -> String {
        if let scheme = application.unambiguousSchemeName {
            return scheme
        }
        if application.schemeNames.isEmpty {
            return SideRefreshLocalization.string(
                "자동으로 확인하지 못함"
            )
        }
        return SideRefreshLocalization.format(
            "%ld개 발견 · 직접 선택 필요",
            application.schemeNames.count
        )
    }

    @ViewBuilder
    private func projectDetailRow(
        _ title: String,
        value: String
    ) -> some View {
        GridRow {
            Text(SideRefreshLocalization.string(title))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
        .font(.caption)
    }

    private var selectionGuidance: String {
        guard !candidate.applicationTargetNames.isEmpty else {
            return SideRefreshLocalization.string(
                "설치 가능한 앱을 자동으로 확인하지 못했습니다. 선택하기 전에 Xcode에서 앱 대상과 Scheme을 확인해 주세요."
            )
        }
        switch candidate.kind {
        case .workspace:
            return hasRelatedContainer
                ? SideRefreshLocalization.string(
                    "이 워크스페이스는 앱 프로젝트와 필요한 라이브러리를 함께 빌드하므로 권장합니다."
                )
                : SideRefreshLocalization.string(
                    "앱 프로젝트와 필요한 라이브러리를 한 번에 여는 워크스페이스입니다."
                )
        case .project:
            return hasRelatedContainer
                ? SideRefreshLocalization.string(
                    "이 프로젝트를 포함하는 워크스페이스가 목록에 있습니다. 특별한 이유가 없다면 워크스페이스를 선택하세요."
                )
                : SideRefreshLocalization.string(
                    "연결된 워크스페이스가 없어 이 프로젝트 파일을 사용하면 됩니다."
                )
        }
    }
}

private struct SettingsCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let subtitle: String
    let systemImage: String
    @ViewBuilder let content: Content

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SideRefreshPalette.cobalt)
                    .frame(width: 24, height: 24)
                    .background(
                        LinearGradient(
                            colors: [
                                SideRefreshPalette.cobalt.opacity(0.16),
                                SideRefreshPalette.cyan.opacity(0.08),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(
                            cornerRadius: 7,
                            style: .continuous
                        )
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            content
        }
        .padding(18)
        .background(.thinMaterial)
        .background {
            LinearGradient(
                colors: [
                    SideRefreshPalette.cobalt.opacity(
                        colorScheme == .dark ? 0.08 : 0.035
                    ),
                    SideRefreshPalette.cyan.opacity(
                        colorScheme == .dark ? 0.025 : 0.012
                    ),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    SideRefreshPalette.cobalt.opacity(
                        colorScheme == .dark ? 0.24 : 0.12
                    )
                )
        }
        .shadow(
            color: SideRefreshPalette.ink.opacity(
                colorScheme == .dark ? 0.16 : 0.07
            ),
            radius: 14,
            y: 5
        )
    }
}

struct SideRefreshMark: View {
    let size: CGFloat

    var body: some View {
        Image(
            nsImage: size <= 34
                ? SideRefreshApplicationArtwork.image
                : NSApplication.shared.applicationIconImage
                    ?? SideRefreshApplicationArtwork.image
        )
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(
                color: SideRefreshPalette.cobalt.opacity(0.24),
                radius: 10,
                y: 4
            )
            .accessibilityHidden(true)
    }
}
