import SideRefreshAppPresentation

enum SimpleWorkspaceAccessibilityFocus: Hashable {
    case condition
    case control(SimpleWorkspaceControl)
}

struct SimpleWorkspaceFocusRequest: Equatable {
    let control: SimpleWorkspaceControl?
    let generation: Int

    static let initial = SimpleWorkspaceFocusRequest(
        control: nil,
        generation: 0
    )
}
