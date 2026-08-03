import SideRefreshAppPresentation

@MainActor
enum WorkspaceWindowRouter {
    static func show(
        _ workspace: AppWorkspace,
        model: SideRefreshViewModel
    ) {
        switch workspace {
        case .simple:
            SimpleWorkspaceWindowPresenter.shared.show(model: model)
        case .legacy:
            SettingsWindowPresenter.shared.show(model: model)
        }
    }
}
