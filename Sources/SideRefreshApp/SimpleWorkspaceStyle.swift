import SwiftUI

enum SimpleWorkspacePalette {
    static let ink = Color(red: 0.05, green: 0.09, blue: 0.18)
    static let blue = Color(red: 0.18, green: 0.40, blue: 0.93)
    static let mint = Color(red: 0.10, green: 0.54, blue: 0.39)
    static let amber = Color(red: 0.72, green: 0.38, blue: 0.08)
    static let canvas = LinearGradient(
        colors: [
            Color(nsColor: .windowBackgroundColor),
            blue.opacity(0.045),
        ],
        startPoint: .top,
        endPoint: .bottomTrailing
    )
}

private struct SimpleWorkspaceCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(
                Color.primary.opacity(
                    colorScheme == .dark ? 0.075 : 0.035
                ),
                in: RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.11))
            }
    }
}

extension View {
    func simpleWorkspaceCard() -> some View {
        modifier(SimpleWorkspaceCardModifier())
    }
}
