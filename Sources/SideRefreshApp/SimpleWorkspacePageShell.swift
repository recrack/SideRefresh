import SideRefreshAppPresentation
import SwiftUI

struct SimpleWorkspacePageShell<Header: View, Content: View>: View {
    let page: SimpleWorkspacePage
    private let header: Header
    private let content: Content

    init(
        page: SimpleWorkspacePage,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.page = page
        self.header = header()
        self.content = content()
    }

    var body: some View {
        let metrics = SimpleWorkspacePageLayoutPolicy.metrics(for: page)
        VStack(spacing: 0) {
            header
                .frame(
                    maxWidth: .infinity,
                    minHeight: CGFloat(metrics.minimumContentHeight),
                    alignment: .topLeading
                )
                .padding(
                    .horizontal,
                    CGFloat(metrics.horizontalPadding)
                )
                .padding(.vertical, CGFloat(metrics.verticalPadding))
                .frame(maxWidth: CGFloat(metrics.maximumContentWidth))
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(
                    SimpleWorkspacePageLayoutPolicy
                        .headerIdentifier(for: page)
                )
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(SimpleWorkspacePalette.canvas)
    }
}
